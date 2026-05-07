import 'package:businessmindset/config/revenuecat_keys.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/features/settings/pages/manage/view_model/manage_ui_state.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/services/revenuecat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageViewModel extends StateNotifier<ManageUiState> {
  ManageViewModel(this._ref) : super(const ManageUiState());

  final Ref _ref;
  DateTime? _lastRefreshTime;

  Future<void> init() async {
    await loadPref();
    await verifyCancellationStatusOnOpen();
  }

  Future<void> verifyCancellationStatusOnOpen() async {
    if (kIsWeb) return;
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await RevenueCatService.instance.ensureConfigured(appUserId: userId);
      final info = await RevenueCatService.instance.restorePurchases();
      final entitlement = info.entitlements.active[revenueCatEntitlementId];
      if (entitlement != null) {
        final isTrial = RevenueCatService.instance.isTrialPeriod(entitlement.periodType);
        if (entitlement.isActive && !entitlement.willRenew && !isTrial) {
          await loadPref(force: true);
        }
      }
    } catch (_) {}
  }

  Future<void> maybeRefreshAfterResume() async {
    final now = DateTime.now();
    final shouldRefresh = _lastRefreshTime == null ||
        now.difference(_lastRefreshTime!).inSeconds >= 2;
    if (!shouldRefresh) return;
    _lastRefreshTime = now;
    await Future.delayed(const Duration(milliseconds: 800));
    await loadPref(force: true);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "—";
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  String _getPeriodFromProductId(String productId, String lang) {
    final idLower = productId.toLowerCase();
    if (idLower.contains('annual') || idLower.contains('yearly') || idLower.contains('year')) {
      return translate("yearly", lang);
    } else if (idLower.contains('monthly') || idLower.contains('month')) {
      return translate("monthly", lang);
    } else if (idLower.contains('weekly') || idLower.contains('week')) {
      return translate("weekly", lang);
    }
    return translate("yearly", lang);
  }

  int _getPeriodDurationDays(String productId) {
    final idLower = productId.toLowerCase();
    if (idLower.contains('annual') || idLower.contains('yearly') || idLower.contains('year')) {
      return 365;
    } else if (idLower.contains('monthly') || idLower.contains('month')) {
      return 30;
    } else if (idLower.contains('weekly') || idLower.contains('week')) {
      return 7;
    }
    return 365;
  }

  Future<void> loadPref({bool force = false}) async {
    if (kIsWeb) return;
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await RevenueCatService.instance.ensureConfigured(appUserId: userId);
      final CustomerInfo info = force
          ? await RevenueCatService.instance.restorePurchases()
          : await RevenueCatService.instance.getCustomerInfo(forceRefresh: true);
      final entitlement = info.entitlements.active[revenueCatEntitlementId];
      final lang = _ref.read(languageProvider);
      if (entitlement == null) return;

      final productId = entitlement.productIdentifier;
      final isTrial = RevenueCatService.instance.isTrialPeriod(entitlement.periodType);
      final period = _getPeriodFromProductId(productId, lang);
      final type = isTrial ? translate("free_trial", lang) : translate("Premium", lang);
      final isCancelled = !entitlement.willRenew;

      DateTime? trialEndDate;
      DateTime? startDate;
      DateTime? expirationDate;
      final expDateStr = entitlement.expirationDate;
      if (expDateStr != null) {
        expirationDate = DateTime.parse(expDateStr);
      }
      if (expirationDate != null) {
        if (isTrial) {
          trialEndDate = expirationDate;
          try {
            startDate = DateTime.parse(entitlement.originalPurchaseDate);
          } catch (_) {}
        } else {
          trialEndDate = null;
          startDate = expirationDate.subtract(Duration(days: _getPeriodDurationDays(productId)));
        }
      }

      state = state.copyWith(
        currentPeriod: period,
        currentType: type,
        isTrialPeriod: isTrial,
        isCancelled: isCancelled,
        currentTEnd: _formatDate(trialEndDate),
        currentSubStart: _formatDate(startDate),
        currentStartedOn: _formatDate(startDate),
        currentNextRenewal: _formatDate(expirationDate),
      );
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[MANAGE PAGE] Error loading subscription info: $error');
        debugPrint('$stack');
      }
    }
  }

  Future<void> refreshPremiumState() async {
    final prefs = await SharedPreferences.getInstance();
    await RevenueCatService.instance.ensureConfigured(
      appUserId: FirebaseAuth.instance.currentUser?.uid,
    );
    final info = await RevenueCatService.instance.getCustomerInfo(forceRefresh: true);
    final hasEntitlement = RevenueCatService.instance.hasActiveEntitlement(info);
    _ref.read(premiumProvider.notifier).state = hasEntitlement;
    await prefs.setBool('premiumState', hasEntitlement);
    await loadPref();
  }

  Future<void> pollForCancellationStatus() async {
    if (kIsWeb) return;
    for (int attempt = 0; attempt < 10; attempt++) {
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        await RevenueCatService.instance.ensureConfigured(appUserId: userId);
        final info = await RevenueCatService.instance.restorePurchases();
        final entitlement = info.entitlements.active[revenueCatEntitlementId];
        if (entitlement != null) {
          final willRenew = entitlement.willRenew;
          final isTrial = RevenueCatService.instance.isTrialPeriod(entitlement.periodType);
          if (!willRenew && !isTrial) {
            await loadPref(force: true);
            break;
          }
        }
        if (attempt < 9) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (_) {
        if (attempt < 9) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }
  }

  Future<RestorePurchaseOutcome> handleRestorePurchase() async {
    try {
      await RevenueCatService.instance.ensureConfigured(
        appUserId: FirebaseAuth.instance.currentUser?.uid,
      );
      final info = await RevenueCatService.instance.restorePurchases();
      final hasEntitlement = RevenueCatService.instance.hasActiveEntitlement(info);
      if (hasEntitlement) {
        await refreshPremiumState();
        return RestorePurchaseOutcome.success;
      }
      return RestorePurchaseOutcome.notFound;
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Restore purchase failed: $error');
        debugPrint('$stack');
      }
      return RestorePurchaseOutcome.error;
    }
  }
}

