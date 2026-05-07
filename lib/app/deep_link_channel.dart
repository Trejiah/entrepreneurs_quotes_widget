import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Single source of truth for the native ↔ Flutter deep-link bridge.
///
/// The channel name is shared with the iOS `AppDelegate.swift` and the
/// Android equivalent. Anything that talks to those native sides must
/// import this file rather than re-declaring the channel string.
const MethodChannel businessmindsetDeepLinkChannel =
    MethodChannel('businessmindset/deeplink');

/// Notifies the iOS side that the app was opened from the lock-screen
/// widget so it can persist the flag in the shared `UserDefaults` (App
/// Group). Best-effort; failures are swallowed.
Future<void> markOpenedFromLockScreen() async {
  try {
    await businessmindsetDeepLinkChannel.invokeMethod('setOpenedFromLockScreen');
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[DeepLink] markOpenedFromLockScreen failed: $e');
    }
  }
}

/// Reads the latest quote that the iOS widget displayed, including its
/// `signature` and `book` metadata. Returns `null` on any failure (channel
/// not wired, native side unavailable, no quote stored, …).
Future<Map<dynamic, dynamic>?> readWidgetStoredQuote() async {
  try {
    return await businessmindsetDeepLinkChannel
        .invokeMethod<Map<dynamic, dynamic>>('getWidgetStoredQuote');
  } catch (error, stack) {
    if (kDebugMode) {
      debugPrint('[DeepLink] readWidgetStoredQuote failed: $error\n$stack');
    }
    return null;
  }
}

/// Android only: one-shot quote saved when opening `businessmindset://home`,
/// before native code clears prefs for the next widget quote.
Future<Map<dynamic, dynamic>?> consumeAndroidWidgetOpenSnapshot() async {
  if (!Platform.isAndroid) return null;
  try {
    final raw = await businessmindsetDeepLinkChannel
        .invokeMethod<dynamic>('consumeWidgetOpenSnapshot');
    if (raw == null) {
      if (kDebugMode) {
        debugPrint('[WidgetTap] consumeAndroidWidgetOpenSnapshot: native returned null');
      }
      return null;
    }
    if (raw is Map) {
      final m = Map<dynamic, dynamic>.from(raw);
      if (kDebugMode) {
        final q = m['quote'] as String?;
        debugPrint(
          '[WidgetTap] consumeAndroidWidgetOpenSnapshot: keys=${m.keys.toList()} quoteLen=${q?.length ?? 0}',
        );
      }
      return m;
    }
    return null;
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[WidgetTap] consumeAndroidWidgetOpenSnapshot failed: $e\n$st');
    }
    return null;
  }
}
