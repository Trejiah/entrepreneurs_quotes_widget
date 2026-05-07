import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:businessmindset/config/revenuecat_keys.dart';
import 'package:businessmindset/features/home/view_model/home_actions_coordinator.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/services/revenuecat_service.dart';
import 'package:businessmindset/services/tiktok_service.dart';
import 'package:businessmindset/features/paywall/hard_paywall_presenter.dart';

/// Tranche B (phase 3) : paywall forcé, paywall promo, synchro prefs premium / RevenueCat.
final homePremiumCoordinatorProvider = Provider<HomePremiumCoordinator>((ref) {
  return HomePremiumCoordinator(ref);
});

class PremiumPrefsSyncResult {
  const PremiumPrefsSyncResult({
    required this.subscriptionWidgetSyncNeeded,
  });

  /// `true` si le provider premium ou la date d’expiration stockée a changé (widget natif).
  final bool subscriptionWidgetSyncNeeded;
}

class HomePremiumCoordinator {
  HomePremiumCoordinator(this._ref);

  final Ref _ref;

  Future<bool> presentHardPaywallIfEnforced(WidgetRef ref, Widget homePageWidget) {
    return HardPaywallPresenter.presentIfEnforced(ref, homePageWidget);
  }

  Future<void> clearPremiumLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('premiumState', false);
      await prefs.remove('premiumExpirationDate');
    } catch (_) {}
  }

  /// Met à jour [premiumProvider] + SharedPreferences à partir d’un [CustomerInfo] frais.
  Future<PremiumPrefsSyncResult> applyPremiumStateFromCustomerInfo(
    CustomerInfo info,
  ) async {
    final entitlement = info.entitlements.active[revenueCatEntitlementId];
    final hasEntitlement = entitlement != null;
    final latestExpirationDate = RevenueCatService.instance.getExpirationDate(info);
    final latestExpirationMs = latestExpirationDate?.millisecondsSinceEpoch;

    final prefs = await SharedPreferences.getInstance();
    final previousPremium = _ref.read(premiumProvider);
    final previousExpirationMs = prefs.getInt('premiumExpirationDate');
    var subscriptionWidgetSyncNeeded = false;

    if (previousPremium != hasEntitlement) {
      _ref.read(premiumProvider.notifier).state = hasEntitlement;
      subscriptionWidgetSyncNeeded = true;
    }

    if (hasEntitlement) {
      await prefs.setBool('premiumState', true);
      if (latestExpirationMs != null) {
        await prefs.setInt('premiumExpirationDate', latestExpirationMs);
      } else {
        await prefs.remove('premiumExpirationDate');
      }
    } else {
      await prefs.setBool('premiumState', false);
      await prefs.remove('premiumExpirationDate');
    }

    if (previousExpirationMs != latestExpirationMs) {
      subscriptionWidgetSyncNeeded = true;
    }

    return PremiumPrefsSyncResult(
      subscriptionWidgetSyncNeeded: subscriptionWidgetSyncNeeded,
    );
  }

  /// Prépare le paywall promo J+4 (prefs + Mixpanel + délai). La vue ouvre [PaywallPromo].
  Future<bool> preparePromoPaywallNavigationIfEligible() async {
    if (_ref.read(premiumProvider)) return false;

    final prefs = await SharedPreferences.getInstance();
    final refusedDateMs = prefs.getInt('subscriptionRefusedDate');
    if (refusedDateMs == null) return false;

    final promoPaywallShown = prefs.getBool('promoPaywallShown') ?? false;
    if (promoPaywallShown) return false;

    final refusedDate = DateTime.fromMillisecondsSinceEpoch(refusedDateMs);
    final daysSinceRefusal = DateTime.now().difference(refusedDate).inDays;
    if (daysSinceRefusal < 4) return false;

    await prefs.setBool('promoPaywallShown', true);
    MixpanelService.instance.track('[Paywall] Promo J4 déclenchée', {
      'days_since_refusal': daysSinceRefusal,
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return true;
  }

  Future<void> afterPremiumFlagChanged({
    required bool? previous,
    required bool next,
    required Future<void> Function() refreshWidget,
    required Future<void> Function() onBecamePremium,
  }) async {
    await refreshWidget();
    if (previous == false && next == true) {
      await onBecamePremium();
    }
  }

  Future<HomeQuoteStatePatch?> buildBecamePremiumQuotePatch({
    required bool isHistoryEmpty,
    required Future<Map<String, dynamic>> Function() generateQuote,
    required HomeQuoteStatePatch Function(Map<String, dynamic> newQuoteData) buildPatch,
  }) async {
    if (!isHistoryEmpty) return null;
    final newQuoteData = await generateQuote();
    return buildPatch(newQuoteData);
  }

  Future<void> onSubscriptionStreamEvent({
    required SubscriptionEvent event,
    required WidgetRef ref,
    required bool Function() isMounted,
    required Widget homePageWidget,
    required Future<void> Function() onPremiumExpiredRepair,
    required Future<void> Function() onBecamePremiumContent,
  }) async {
    if (!isMounted()) return;

    final info = event.customerInfo;
    final entitlement = info.entitlements.active[revenueCatEntitlementId];

    if (entitlement == null && event.type != SubscriptionEventType.expired) {
      return;
    }

    final periodType = entitlement?.periodType;
    final isTrial = RevenueCatService.instance.isTrialPeriod(periodType);

    if (entitlement != null &&
        (event.type == SubscriptionEventType.converted ||
            event.type == SubscriptionEventType.renewed)) {
      SharedPreferences.getInstance().then((prefs) async {
        await prefs.setBool('subscription_cancel_event_sent', false);
      });
    }

    if (event.type == SubscriptionEventType.optedOut &&
        entitlement != null &&
        !isTrial) {
      SharedPreferences.getInstance().then((prefs) async {
        final alreadySent = prefs.getBool('subscription_cancel_event_sent') ?? false;
        if (!alreadySent) {
          MixpanelService.instance.track('[Subscription] Cancelled', {});
          await prefs.setBool('subscription_cancel_event_sent', true);
        }
      });
    }

    if (event.type == SubscriptionEventType.converted && entitlement != null) {
      final productId = entitlement.productIdentifier.toLowerCase();
      final subscriptionPeriod =
          (productId.contains('month') || productId.contains('monthly')) ? 'month' : 'year';
      SharedPreferences.getInstance().then((prefs) {
        final age = prefs.getString('age') ?? 'unknown';
        final gender = prefs.getString('gender') ?? 'unknown';
        final workSituation = prefs.getString('situation') ?? 'unknown';
        MixpanelService.instance.track('[Subscription] Premium Enabled', {
          'subscription_origin': 'trial_converted',
          'subscription_period': subscriptionPeriod,
          'trial_type': 'converted',
          'gender': gender,
          'age': age,
          'work_situation': workSituation,
          'source': 'trial_conversion',
        });
      });
      TikTokService.instance.trackCompletePayment(
        contentId: entitlement.productIdentifier,
        contentName: subscriptionPeriod == 'year' ? 'premium_annual' : 'premium_monthly',
        quantity: 1,
      );
    }

    if (event.type == SubscriptionEventType.expired) {
      final currentPremium = _ref.read(premiumProvider);
      if (currentPremium) {
        _ref.read(premiumProvider.notifier).state = false;
        await clearPremiumLocalStorage();
        await onPremiumExpiredRepair();
        if (!isMounted()) return;
        await presentHardPaywallIfEnforced(ref, homePageWidget);
      }
    } else if (entitlement != null) {
      HardPaywallPresenter.resetSessionFlag();
      await onBecamePremiumContent();
    }
  }

  Future<void> onPeriodicSubscriptionPoll({
    required WidgetRef ref,
    required bool Function() isMounted,
    required Widget homePageWidget,
    required Future<void> Function() onLostPremiumRepair,
  }) async {
    try {
      if (!isMounted()) return;

      final info = await RevenueCatService.instance.getCustomerInfo(forceRefresh: true);
      final entitlement = info.entitlements.active[revenueCatEntitlementId];
      final hasEntitlement = entitlement != null;
      final prefs = await SharedPreferences.getInstance();
      final periodType = entitlement?.periodType;
      final isTrial = RevenueCatService.instance.isTrialPeriod(periodType);

      if (hasEntitlement) {
        final willRenew = entitlement.willRenew;
        if (willRenew || isTrial) {
          await prefs.setBool('subscription_cancel_event_sent', false);
        } else {
          final alreadySent = prefs.getBool('subscription_cancel_event_sent') ?? false;
          if (!alreadySent) {
            MixpanelService.instance.track('[Subscription] Cancelled', {});
            await prefs.setBool('subscription_cancel_event_sent', true);
          }
        }
      } else {
        final wasPremium = prefs.getBool('premiumState') ?? false;
        if (wasPremium) {
          _ref.read(premiumProvider.notifier).state = false;
          await clearPremiumLocalStorage();
          await onLostPremiumRepair();
          await presentHardPaywallIfEnforced(ref, homePageWidget);
        }
      }
    } catch (_) {}
  }
}
