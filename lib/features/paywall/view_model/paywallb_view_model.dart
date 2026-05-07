import 'dart:async';

import 'package:businessmindset/config/revenuecat_keys.dart';
import 'package:businessmindset/core/trial_type_analytics.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/services/hard_paywall_service.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/services/revenuecat_service.dart';
import 'package:businessmindset/services/tiktok_service.dart';
import 'package:businessmindset/services/trial_duration_ab_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/paywall_models.dart';
import 'paywallb_ui_state.dart';

class PaywallbViewModel extends StateNotifier<PaywallbUiState> {
  PaywallbViewModel(this._ref, this.input) : super(const PaywallbUiState()) {
    _subscriptionEventSubscription =
        RevenueCatService.instance.onSubscriptionEvent.listen(_onSubscriptionEvent);
    _ref.onDispose(() {
      _subscriptionEventSubscription?.cancel();
    });
  }

  final Ref _ref;
  final PaywallbInput input;

  StreamSubscription<SubscriptionEvent>? _subscriptionEventSubscription;

  Future<void> init() async {
    state = state.copyWith(currentWhatsIncludedPage: 0);
    await Future.wait([
      initializeRevenueCat(),
      initializeRevenueCat14(),
      checkTrialEligibility(),
      determineTrialDays(),
    ]);
  }

  void onWhatsIncludedPageChanged(int page) {
    state = state.copyWith(currentWhatsIncludedPage: page);
  }

  void setYearlySelected(bool value) {
    state = state.copyWith(isYearlySelected: value);
  }

  Future<void> _onSubscriptionEvent(SubscriptionEvent event) async {
    final info = event.customerInfo;
    final expirationDate = RevenueCatService.instance.getExpirationDate(info);
    final trialEndDate = RevenueCatService.instance.getTrialEndDate(info);
    final renewalDate = RevenueCatService.instance.getRenewalDate(info);

    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("🔔 [Paywall] Événement d'abonnement détecté");

      switch (event.type) {
        case SubscriptionEventType.converted:
          debugPrint("   ✅ Type: TRIAL → ABONNEMENT (Conversion)");
          if (trialEndDate != null) {
            debugPrint(
                "   🎁 Trial ended at (UTC+4): ${RevenueCatService.instance.formatDateTimeLocal(trialEndDate)}");
          }
          break;
        case SubscriptionEventType.renewed:
          debugPrint("   🔄 Type: RENOUVELLEMENT");
          if (renewalDate != null) {
            debugPrint(
                "   🔄 Renewed on (UTC+4): ${RevenueCatService.instance.formatDateTimeLocal(renewalDate)}");
          }
          break;
        case SubscriptionEventType.optedOut:
          debugPrint("   ⚠️ Type: OPT-OUT (Annulation, mais actif jusqu'à expiration)");
          if (expirationDate != null) {
            debugPrint(
                "   📅 Reste actif jusqu'au (UTC+4): ${RevenueCatService.instance.formatDateTimeLocal(expirationDate)}");
          }
          break;
        case SubscriptionEventType.expired:
          debugPrint("   ❌ Type: EXPIRED");
          debugPrint(
              "   📅 Date d'expiration (UTC+4): ${RevenueCatService.instance.formatDateTimeLocal(expirationDate)}");
          break;
      }

      if (expirationDate != null) {
        debugPrint(
            "   📅 Date d'expiration actuelle (UTC+4): ${RevenueCatService.instance.formatDateTimeLocal(expirationDate)}");
      }
      if (renewalDate != null && event.type != SubscriptionEventType.expired) {
        debugPrint(
            "   🔄 Prochain renouvellement (UTC+4): ${RevenueCatService.instance.formatDateTimeLocal(renewalDate)}");
      }
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }

    if (event.type == SubscriptionEventType.expired) {
      final currentPremium = _ref.read(premiumProvider);
      if (currentPremium) {
        if (kDebugMode) {
          debugPrint("⚠️ [Paywall] Subscription expired - Switching from premium to !premium");
        }

        _ref.read(premiumProvider.notifier).state = false;

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool("premiumState", false);
          await prefs.remove("premiumExpirationDate");

          if (kDebugMode) {
            debugPrint("✅ [Paywall] Provider and storage updated: premium = false");
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint("❌ [Paywall] Error while updating storage: $e");
          }
        }
      }
    }
  }

  Future<void> initializeRevenueCat() async {
    if (kIsWeb) return;

    state = state.copyWith(isLoadingPackage: true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await RevenueCatService.instance.ensureConfigured(appUserId: userId);

      final prefs = await SharedPreferences.getInstance();
      final trialDays = await TrialDurationAbService.getAssignedTrialDays(prefs);
      final annualId = getAnnualSubscriptionProductIdForTrialDays(trialDays);
      final monthlyId = getSubscriptionProductIdMonthly();

      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint('Fetching products: $annualId, $monthlyId');
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }

      final products = await RevenueCatService.instance.getProducts([annualId, monthlyId]);

      StoreProduct? annual;
      StoreProduct? monthly;
      for (final p in products) {
        final base = baseProductId(p.identifier);
        if (base == annualId) annual = p;
        if (base == monthlyId) monthly = p;
      }

      state = state.copyWith(
        annualProduct: annual,
        monthlyProduct: monthly,
        isLoadingPackage: false,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to initialize RevenueCat: $error');
      }
      state = state.copyWith(isLoadingPackage: false);
    }
  }

  Future<void> initializeRevenueCat14() async {
    if (kIsWeb) return;

    state = state.copyWith(isLoadingPackage14: true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await RevenueCatService.instance.ensureConfigured(appUserId: userId);

      final productId = getSubscriptionProductId14();

      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint('Fetching product with ID: $productId');
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }

      final products = await RevenueCatService.instance.getProducts([productId]);

      if (products.isEmpty) {
        state = state.copyWith(isLoadingPackage14: false);
        if (kDebugMode) {
          debugPrint('No product 14 available');
        }
        return;
      }

      final product = products.first;
      state = state.copyWith(
        annualProduct14: product,
        isLoadingPackage14: false,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to initialize RevenueCat 14: $error');
      }
      state = state.copyWith(isLoadingPackage14: false);
    }
  }

  Future<void> checkTrialEligibility() async {
    if (kIsWeb) {
      state = state.copyWith(
        isEligibleForTrial: true,
        isCheckingTrialEligibility: false,
      );
      return;
    }

    state = state.copyWith(isCheckingTrialEligibility: true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await RevenueCatService.instance.ensureConfigured(appUserId: userId);

      final info = await RevenueCatService.instance.getCustomerInfo(forceRefresh: true);

      final hasActiveEntitlement = RevenueCatService.instance.hasActiveEntitlement(info);
      final allEntitlements = info.entitlements.all;
      final activeEntitlement = info.entitlements.active[revenueCatEntitlementId];

      bool hasSubscriptionHistory = false;
      if (allEntitlements.isNotEmpty) {
        for (final entitlement in allEntitlements.values) {
          if (!entitlement.isActive) {
            hasSubscriptionHistory = true;
            break;
          }
        }
      }

      final nonSubscriptionTransactions = info.nonSubscriptionTransactions;
      final hasNonSubscriptionPurchases = nonSubscriptionTransactions.isNotEmpty;

      final isEligible = !hasActiveEntitlement && !hasSubscriptionHistory;

      state = state.copyWith(
        isEligibleForTrial: isEligible,
        isCheckingTrialEligibility: false,
      );

      if (kDebugMode) {
        final isConnected = userId != null;
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('[Paywall] Trial eligibility summary:');
        debugPrint('  - Logic used: !hasActive && !hasHistory');
        debugPrint('  - Firebase account connected: $isConnected');
        debugPrint('  - Has active entitlement: $hasActiveEntitlement');
        debugPrint('  - Has subscription history: $hasSubscriptionHistory');
        debugPrint('  - Has non-subscription purchases: $hasNonSubscriptionPurchases');
        debugPrint('  - Total entitlements: ${allEntitlements.length}');
        debugPrint('  - Non-subscription transactions: ${nonSubscriptionTransactions.length}');
        if (activeEntitlement != null) {
          debugPrint('  - Active entitlement periodType: ${activeEntitlement.periodType}');
          debugPrint('  - Active entitlement willRenew: ${activeEntitlement.willRenew}');
        }
        debugPrint('  - ✨ Eligible for trial: ${state.isEligibleForTrial}');
        debugPrint(
            '  - Button text: ${state.isEligibleForTrial ? "Try for free" : "Let's go"}');
        if (!isConnected) {
          debugPrint(
              '  - ℹ️ Note: Without Firebase, RevenueCat uses store account (Apple ID/Google Play)');
        }
        if (hasSubscriptionHistory && !hasActiveEntitlement) {
          debugPrint('  - ⚠️ Has expired subscription history → NOT eligible');
        }
        debugPrint('  - ⚠️ Cannot detect if Apple eligibility was reset (App Store Connect)');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('❌ [Paywall] Failed to check trial eligibility: $error');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      state = state.copyWith(
        isEligibleForTrial: true,
        isCheckingTrialEligibility: false,
      );
    }
  }

  Future<void> determineTrialDays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (kIsWeb) {
        final d = await TrialDurationAbService.getAssignedTrialDays(prefs);
        state = state.copyWith(trialDays: d);
        return;
      }
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await RevenueCatService.instance.ensureConfigured(appUserId: userId);
      final info = await RevenueCatService.instance.getCustomerInfo(forceRefresh: true);
      final days = await TrialDurationAbService.resolveTrialDaysFromCustomerInfo(info, prefs);
      state = state.copyWith(trialDays: days);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to determine trial days: $error');
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        final d = await TrialDurationAbService.getAssignedTrialDays(prefs);
        state = state.copyWith(trialDays: d);
      } catch (_) {
        state = state.copyWith(trialDays: 7);
      }
    }
  }

  Future<PaywallbPurchaseOutcome> purchasePrimaryPlans() async {
    final product =
        state.isYearlySelected ? state.annualProduct : state.monthlyProduct;
    if (product == null) {
      if (kDebugMode) {
        debugPrint('No product available for purchase');
      }
      return PaywallbPurchaseOutcome.noProductAvailable;
    }

    state = state.copyWith(isLoadingPackage: true);

    try {
      final info = await RevenueCatService.instance.purchaseProduct(product);

      if (RevenueCatService.instance.hasActiveEntitlement(info)) {
        if (kDebugMode) {
          debugPrint('Purchase successful!');
        }
        state = state.copyWith(isLoadingPackage: false);
        await markPremiumUnlocked(info);
        return PaywallbPurchaseOutcome.success;
      }

      if (kDebugMode) {
        debugPrint('Purchase completed but no active entitlement found');
      }
      state = state.copyWith(isLoadingPackage: false);
      return PaywallbPurchaseOutcome.completedWithoutActiveEntitlement;
    } on PlatformException catch (error) {
      state = state.copyWith(isLoadingPackage: false);

      final errorCode = PurchasesErrorHelper.getErrorCode(error);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        if (kDebugMode) {
          debugPrint('Purchase cancelled by user');
        }
        return PaywallbPurchaseOutcome.cancelled;
      }
      if (kDebugMode) {
        debugPrint('Purchase failed: $error');
      }
      return PaywallbPurchaseOutcome.failed;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Purchase failed: $error');
      }
      state = state.copyWith(isLoadingPackage: false);
      return PaywallbPurchaseOutcome.failed;
    }
  }

  Future<void> markPremiumUnlocked(CustomerInfo? info) async {
    _ref.read(premiumProvider.notifier).state = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("premiumState", true);

    bool isInTrial = state.isInTrial;

    if (info != null) {
      final expirationDate = RevenueCatService.instance.getExpirationDate(info);
      final trialEndDate = RevenueCatService.instance.getTrialEndDate(info);
      final renewalDate = RevenueCatService.instance.getRenewalDate(info);

      final entitlement = info.entitlements.active[revenueCatEntitlementId];
      if (entitlement != null) {
        final isTrial = RevenueCatService.instance.isTrialPeriod(entitlement.periodType);
        isInTrial = isTrial;
        if (isTrial) {
          TikTokService.instance.trackStartTrial(
            contentId: entitlement.productIdentifier,
            value: 0,
          );
        } else {
          final productId = entitlement.productIdentifier.toLowerCase();
          final subscriptionPeriod =
              (productId.contains('month') || productId.contains('monthly')) ? 'month' : 'year';
          TikTokService.instance.trackCompletePayment(
            contentId: entitlement.productIdentifier,
            contentName: subscriptionPeriod == 'year' ? 'premium_annual' : 'premium_monthly',
            quantity: 1,
          );
        }
      }

      if (expirationDate != null) {
        await prefs.setInt("premiumExpirationDate", expirationDate.millisecondsSinceEpoch);
      }

      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("✅ [Paywall] Premium activé - Détails de l'abonnement");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

        if (trialEndDate != null) {
          debugPrint(
              "🎁 End of TRIAL period (UTC+4): ${RevenueCatService.instance.formatDateTimeLocal(trialEndDate)}");
        }

        if (renewalDate != null) {
          debugPrint(
              "🔄 Prochain RENEWAL (UTC+4): ${RevenueCatService.instance.formatDateTimeLocal(renewalDate)}");
        } else {
          final ent = info.entitlements.active[revenueCatEntitlementId];
          if (ent != null && !ent.willRenew) {
            debugPrint("⚠️ No renewal scheduled (opt-out)");
          }
        }

        if (expirationDate != null) {
          debugPrint(
              "📅 Date d'expiration (UTC+4): ${RevenueCatService.instance.formatDateTimeLocal(expirationDate)}");
        }

        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
    }

    state = state.copyWith(isInTrial: isInTrial);

    final age = prefs.getString("age") ?? "unknown";
    final gender = prefs.getString("gender") ?? "unknown";
    final workSituation = prefs.getString("situation") ?? "unknown";
    final entitlement = info?.entitlements.active[revenueCatEntitlementId];
    final productId = entitlement?.productIdentifier.toLowerCase() ?? '';
    final isInTrialRc = entitlement != null &&
        RevenueCatService.instance.isTrialPeriod(entitlement.periodType);
    final trialType = trialTypeAnalyticsValue(
      productIdLower: productId,
      isInTrial: isInTrialRc,
    );
    final subscriptionPeriod =
        (productId.contains('month') || productId.contains('monthly')) ? 'month' : 'year';
    final subscriptionOrigin = isInTrialRc ? 'free_trial' : 'no_trial';
    MixpanelService.instance.track('[Subscription] Premium Enabled', {
      'trial_type': trialType,
      'subscription_origin': subscriptionOrigin,
      'subscription_period': subscriptionPeriod,
      'gender': gender,
      'age': age,
      'work_situation': workSituation,
      'source': 'paywall_internal',
    });

    if (input.hardPaywallMode) {
      await HardPaywallService.clearBlockingLayer();
    }
  }
}
