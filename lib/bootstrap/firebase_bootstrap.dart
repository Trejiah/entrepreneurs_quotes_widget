import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Initialise Firebase with a small retry loop and wire Crashlytics as the
/// global error sink for both Flutter (`FlutterError.onError`) and Dart
/// (`PlatformDispatcher.instance.onError`).
///
/// Native Pigeon channels are not always ready on the very first frame, so
/// we retry a few times with linear back-off before giving up. The app keeps
/// running even if every attempt fails — Firebase-dependent features will
/// just silently degrade.
Future<void> initializeFirebaseWithRetry({int maxAttempts = 5}) async {
  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Disabled in debug to avoid polluting the Crashlytics dashboard
      // with developer-side errors.
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);

      if (kDebugMode) {
        debugPrint('✅ [Firebase] Initialised (attempt $attempt/$maxAttempts)');
      }
      return;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [Firebase] Attempt $attempt/$maxAttempts failed: $e');
      }
      if (attempt == maxAttempts) {
        if (kDebugMode) {
          debugPrint(
            '❌ [Firebase] Giving up after $maxAttempts attempts — '
            'app continues without Firebase.',
          );
        }
        return;
      }
      await Future.delayed(Duration(milliseconds: 100 * attempt));
    }
  }
}
