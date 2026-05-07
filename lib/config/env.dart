import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised access to runtime configuration values.
///
/// Resolution order for every key:
///   1. `--dart-define=KEY=value` (compile-time, highest priority).
///   2. `.env` file shipped as an asset (loaded by [load]).
///   3. Hard-coded fallback passed to the getter (lowest priority).
///
/// `.env` is gitignored. See `.env.example` for the supported keys.
class Env {
  Env._();

  /// Loads `.env` if present. Safe to call multiple times. Errors are swallowed
  /// in release mode so a missing `.env` never crashes the app — only the
  /// fallback values will then be used.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Env] Could not load .env (using fallbacks): $e');
      }
    }
  }

  static String _read(String key, {String fallback = ''}) {
    final fromDefine = String.fromEnvironment(key);
    if (fromDefine.isNotEmpty) return fromDefine;
    if (dotenv.isInitialized && dotenv.env.containsKey(key)) {
      return dotenv.env[key] ?? fallback;
    }
    return fallback;
  }

  // ─── RevenueCat ──────────────────────────────────────────────────────────
  static String get revenueCatIosKey => _read('REVENUECAT_IOS_KEY');
  static String get revenueCatAndroidKey => _read('REVENUECAT_ANDROID_KEY');
  static String get revenueCatEntitlementId =>
      _read('REVENUECAT_ENTITLEMENT_ID', fallback: 'Premium');

  // ─── Subscription product IDs ────────────────────────────────────────────
  static String get iosAnnualSubscriptionId =>
      _read('IOS_ANNUAL_SUBSCRIPTION_ID', fallback: 'premium_annual');
  static String get iosMonthlySubscriptionId =>
      _read('IOS_MONTHLY_SUBSCRIPTION_ID', fallback: 'premium_monthly');
  static String get androidAnnualSubscriptionId =>
      _read('ANDROID_ANNUAL_SUBSCRIPTION_ID', fallback: 'premium_annual');
  static String get androidMonthlySubscriptionId =>
      _read('ANDROID_MONTHLY_SUBSCRIPTION_ID', fallback: 'premium_monthly');
  static String get iosAnnualSubscriptionId14 =>
      _read('IOS_ANNUAL_SUBSCRIPTION_ID_14', fallback: 'premium_annual_14');
  static String get androidAnnualSubscriptionId14 =>
      _read('ANDROID_ANNUAL_SUBSCRIPTION_ID_14', fallback: 'premium_annual_14');
  static String get iosAnnualSubscriptionId3DayTrialAb => _read(
        'IOS_ANNUAL_SUBSCRIPTION_ID_3_DAY_TRIAL_AB',
        fallback: 'premium_annual_3',
      );
  static String get androidAnnualSubscriptionId3DayTrialAb => _read(
        'ANDROID_ANNUAL_SUBSCRIPTION_ID_3_DAY_TRIAL_AB',
        fallback: 'premium_annual_3',
      );
  static String get iosAnnualSubscriptionIdPromo =>
      _read('IOS_ANNUAL_SUBSCRIPTION_ID_PROMO', fallback: 'premium_annual_promo');
  static String get androidAnnualSubscriptionIdPromo => _read(
        'ANDROID_ANNUAL_SUBSCRIPTION_ID_PROMO',
        fallback: 'premium_annual_promo',
      );

  // ─── Google Sign-In (Android) ────────────────────────────────────────────
  /// OAuth 2.0 Web client ID (type « Web » dans la console Firebase / GCP).
  /// Requis pour obtenir un `idToken` côté Android avec google_sign_in v7+.
  static String get googleAndroidServerClientId =>
      _read('GOOGLE_ANDROID_SERVER_CLIENT_ID');

  // ─── Mixpanel ────────────────────────────────────────────────────────────
  static String get mixpanelToken => _read('MIXPANEL_TOKEN');

  // ─── TikTok Events SDK ───────────────────────────────────────────────────
  static String get tiktokAndroidAppId => _read('TIKTOK_ANDROID_APP_ID');
  static String get tiktokAndroidId => _read('TIKTOK_ANDROID_ID');
  static String get tiktokIosAppIdUS => _read('TIKTOK_IOS_APP_ID_US');
  static String get tiktokIosIdUS => _read('TIKTOK_IOS_ID_US');
  static String get tiktokIosAppIdROW => _read('TIKTOK_IOS_APP_ID_ROW');
  static String get tiktokIosIdROW => _read('TIKTOK_IOS_ID_ROW');
}
