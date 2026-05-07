import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

/// Hard paywall: `!premium` and snapshot = value of Remote Config `show_item` **at the moment**
/// where the subscription was validated on onboarding 33b (trial **or** direct purchase without trial; not the current RC).
/// - `show_item` **false** at that moment → snapshot `false` → hard paywall + blocks if no longer subscribed.
/// - `show_item` **true** → snapshot `true` → freemium / soft possible after expiration.
/// - Missing key → never went through a validated purchase on 33b → no hard paywall (e.g. close button / legacy users).
class HardPaywallService {
  HardPaywallService._();

  static bool _presentScheduledThisSession = false;

  static bool get isPresentScheduledThisSession => _presentScheduledThisSession;

  static void resetPresentScheduleFlag() {
    _presentScheduledThisSession = false;
  }

  static void markPresentScheduled() {
    _presentScheduledThisSession = true;
  }

  /// Snapshot of `show_item` ([crossShowItemProvider]) at the moment the subscription is validated (onboarding 33b).
  static const String rcSnapshotAtTrialKey = 'hard_paywall_show_close_rc_at_trial';

  /// App Group key (Swift): blocks quote generation in widgets.
  static const String appGroupBlockQuotesKey = 'hardPaywallBlockQuotes';

  static bool shouldEnforce(SharedPreferences prefs, bool premium) {
    if (premium) return false;
    final snap = prefs.getBool(rcSnapshotAtTrialKey);
    if (snap == null) return false;
    return !snap;
  }

  /// To call on every accepted purchase with active entitlement on 33b (trial or immediate payment).
  static Future<void> saveRcSnapshotAtTrial(
    SharedPreferences prefs,
    bool showCloseFromRemoteConfig,
  ) {
    return prefs.setBool(rcSnapshotAtTrialKey, showCloseFromRemoteConfig);
  }

  static Future<void> applyBlockingLayer() async {
    await NotificationService.instance.cancelAll();
    const ch = MethodChannel('businessmindset/deeplink');
    try {
      await ch.invokeMethod('cancelAllIosPendingNotifications');
    } catch (_) {}
    try {
      await ch.invokeMethod('setHardPaywallQuotesBlocked', {'blocked': true});
    } catch (_) {}
  }

  static Future<void> clearBlockingLayer() async {
    const ch = MethodChannel('businessmindset/deeplink');
    try {
      await ch.invokeMethod('setHardPaywallQuotesBlocked', {'blocked': false});
    } catch (_) {}
  }
}
