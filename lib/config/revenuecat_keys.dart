import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import 'env.dart';

/// RevenueCat public SDK keys, subscription product IDs and TikTok Events SDK
/// identifiers. All values are loaded from `.env` (asset) or overridden with
/// `--dart-define`. See `.env.example` for the full list of supported keys.

String get revenueCatIosApiKey => Env.revenueCatIosKey;
String get revenueCatAndroidApiKey => Env.revenueCatAndroidKey;

/// Entitlement identifier configured in the RevenueCat dashboard.
/// Case-sensitive — must match the dashboard exactly.
String get revenueCatEntitlementId => Env.revenueCatEntitlementId;

String get iosAnnualSubscriptionId => Env.iosAnnualSubscriptionId;
String get iosMonthlySubscriptionId => Env.iosMonthlySubscriptionId;
String get androidAnnualSubscriptionId => Env.androidAnnualSubscriptionId;
String get androidMonthlySubscriptionId => Env.androidMonthlySubscriptionId;
String get iosAnnualSubscriptionId14 => Env.iosAnnualSubscriptionId14;
String get androidAnnualSubscriptionId14 => Env.androidAnnualSubscriptionId14;

/// Annual subscription — 3-day trial branch (A/B test).
String get iosAnnualSubscriptionId3DayTrialAb =>
    Env.iosAnnualSubscriptionId3DayTrialAb;
String get androidAnnualSubscriptionId3DayTrialAb =>
    Env.androidAnnualSubscriptionId3DayTrialAb;

String get iosAnnualSubscriptionIdPromo => Env.iosAnnualSubscriptionIdPromo;
String get androidAnnualSubscriptionIdPromo =>
    Env.androidAnnualSubscriptionIdPromo;

// ─── TikTok Events SDK (attribution / conversion) ────────────────────────────
// Two TikTok Ads accounts in our setup: one for the US store, one for the rest
// of the world (ROW). See `.env.example` for the keys.
String get tiktokAndroidAppId => Env.tiktokAndroidAppId;
String get tiktokAndroidId => Env.tiktokAndroidId;
String get tiktokIosAppIdUS => Env.tiktokIosAppIdUS;
String get tiktokIosIdUS => Env.tiktokIosIdUS;
String get tiktokIosAppIdROW => Env.tiktokIosAppIdROW;
String get tiktokIosIdROW => Env.tiktokIosIdROW;

String resolveRevenueCatApiKey() {
  if (kIsWeb) {
    throw UnsupportedError('RevenueCat is not supported on web.');
  }
  if (Platform.isIOS) return revenueCatIosApiKey;
  if (Platform.isAndroid) return revenueCatAndroidApiKey;
  throw UnsupportedError('Unsupported platform for RevenueCat.');
}

String getSubscriptionProductId() {
  if (kIsWeb) {
    throw UnsupportedError('RevenueCat is not supported on web.');
  }
  if (Platform.isIOS) return iosAnnualSubscriptionId;
  if (Platform.isAndroid) return androidAnnualSubscriptionId;
  throw UnsupportedError('Unsupported platform for RevenueCat.');
}

String getSubscriptionProductIdMonthly() {
  if (kIsWeb) {
    throw UnsupportedError('RevenueCat is not supported on web.');
  }
  if (Platform.isIOS) return iosMonthlySubscriptionId;
  if (Platform.isAndroid) return androidMonthlySubscriptionId;
  throw UnsupportedError('Unsupported platform for RevenueCat.');
}

String getSubscriptionProductId14() {
  if (kIsWeb) {
    throw UnsupportedError('RevenueCat is not supported on web.');
  }
  if (Platform.isIOS) return iosAnnualSubscriptionId14;
  if (Platform.isAndroid) return androidAnnualSubscriptionId14;
  throw UnsupportedError('Unsupported platform for RevenueCat.');
}

/// Annual product ID — 3-day trial (A/B). Configure in stores + RevenueCat.
String getSubscriptionProductId3TrialAb() {
  if (kIsWeb) {
    throw UnsupportedError('RevenueCat is not supported on web.');
  }
  if (Platform.isIOS) return iosAnnualSubscriptionId3DayTrialAb;
  if (Platform.isAndroid) return androidAnnualSubscriptionId3DayTrialAb;
  throw UnsupportedError('Unsupported platform for RevenueCat.');
}

/// [trialDays] : `3` -> short A/B trial product, `7` -> standard 7-day trial.
String getAnnualSubscriptionProductIdForTrialDays(int trialDays) {
  if (kIsWeb) {
    throw UnsupportedError('RevenueCat is not supported on web.');
  }
  final id = trialDays == 3
      ? getSubscriptionProductId3TrialAb()
      : getSubscriptionProductId();
  if (kDebugMode) {
    debugPrint('[TrialAB] Annual product ID (RevenueCat / stores): $trialDays d -> $id');
  }
  return id;
}

/// On Android (Google Play Billing v5+), RevenueCat returns a `StoreProduct`
/// whose `identifier` is formatted as `"<productId>:<basePlanId>"` (e.g.
/// `"premium_annual:annual-base"`). On iOS the identifier is just the product
/// ID. This helper strips the base plan suffix so we can match against the
/// product IDs defined in `.env` on both platforms.
String baseProductId(String identifier) => identifier.split(':').first;

String getSubscriptionProductIdPromo() {
  if (kIsWeb) {
    throw UnsupportedError('RevenueCat is not supported on web.');
  }
  if (Platform.isIOS) return iosAnnualSubscriptionIdPromo;
  if (Platform.isAndroid) return androidAnnualSubscriptionIdPromo;
  throw UnsupportedError('Unsupported platform for RevenueCat.');
}
