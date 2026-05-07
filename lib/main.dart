import 'dart:async';

import 'package:businessmindset/app/bootstrap/app_bootstrapper.dart';
import 'package:businessmindset/config/env.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Point d’entrée minimal : binding, config, zone d’erreurs, premier widget.
/// Logique d’init détaillée : [AppBootstrapper].
void main() {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

      await Env.load();

      runApp(const AppBootstrapper());
    },
    (error, stack) {
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {}
    },
  );
}
