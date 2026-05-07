import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/revenuecat_keys.dart';

/// A/B: 3 days vs 7 days trial on the annual subscription, drawn **once** at
/// first open and stored in [SharedPreferences].
class TrialDurationAbService {
  TrialDurationAbService._();

  static const String _prefsKey = 'ab_trial_duration_days';

  static int? _memoryCache;

  /// Once per session: log when we avoid rereading prefs (subsequent calls).
  static bool _loggedMemoryHitThisSession = false;

  /// To call at bootstrap after [SharedPreferences.getInstance] to populate the memory cache.
  /// Return the 3 or 7 bucket (new draw or already-persisted value).
  static Future<int> ensureAssigned(SharedPreferences prefs) async {
    return getAssignedTrialDays(prefs);
  }

  /// 3 or 7 — never regenerated once persisted.
  static Future<int> getAssignedTrialDays(SharedPreferences prefs) async {
    if (_memoryCache != null) {
      if (kDebugMode && !_loggedMemoryHitThisSession) {
        _loggedMemoryHitThisSession = true;
        debugPrint(
          '[TrialAB] Session cache active → $_memoryCache days (prefs key: $_prefsKey, no new draw)',
        );
      }
      return _memoryCache!;
    }
    final existing = prefs.getInt(_prefsKey);
    if (existing == 3 || existing == 7) {
      final v = existing!;
      _memoryCache = v;
      if (kDebugMode) {
        debugPrint(
          '[TrialAB] A/B bucket already persisted → $v days (prior install, no random)',
        );
      }
      return v;
    }
    final coin = Random().nextBool();
    final days = coin ? 3 : 7;
    await prefs.setInt(_prefsKey, days);
    _memoryCache = days;
    if (kDebugMode) {
      debugPrint(
        '[TrialAB] 🎲 Random 50/50 (first assignment) → $days days '
        '(nextBool=${coin ? "true→3j" : "false→7j"}, enregistré $_prefsKey=$days)',
      );
    }
    return days;
  }

  /// Trial days to show: RevenueCat data if subscription active, otherwise A/B bucket.
  static Future<int> resolveTrialDaysFromCustomerInfo(
    CustomerInfo info,
    SharedPreferences prefs,
  ) async {
    final assigned = await getAssignedTrialDays(prefs);
    if (kIsWeb) {
      if (kDebugMode) {
        debugPrint('[TrialAB] Resolution (web) → $assigned days (no RevenueCat)');
      }
      return assigned;
    }

    final entitlement = info.entitlements.active[revenueCatEntitlementId];
    if (entitlement == null) {
      if (kDebugMode) {
        debugPrint(
          '[TrialAB] Resolution → $assigned days (no active entitlement, A/B bucket)',
        );
      }
      return assigned;
    }

    final productId = entitlement.productIdentifier.toLowerCase();
    final productId14 = getSubscriptionProductId14().toLowerCase();
    final productId3 = getSubscriptionProductId3TrialAb().toLowerCase();

    if (productId.contains('14') || productId == productId14) {
      if (kDebugMode) {
        debugPrint(
          '[TrialAB] Resolution → 14 d (14d / promo product) id=$productId',
        );
      }
      return 14;
    }
    if (productId == productId3) {
      if (kDebugMode) {
        debugPrint(
          '[TrialAB] Resolution → 3 d (short A/B trial product) id=$productId',
        );
      }
      return 3;
    }
    if (kDebugMode) {
      debugPrint(
        '[TrialAB] Resolution → 7 d (standard annual subscription or non-id3) '
        'id=$productId, periodType=${entitlement.periodType}',
      );
    }
    return 7;
  }
}
