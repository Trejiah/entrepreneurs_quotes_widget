import 'package:businessmindset/services/mindset_points_service.dart';
import 'package:flutter/widgets.dart';

/// Délégué cycle de vie (Mindset Points) pour éviter d'alourdir [MyApp].
abstract final class MyAppLifecycle {
  static void handle(AppLifecycleState state, {required bool hasOnboard}) {
    if (state == AppLifecycleState.paused) {
      MindsetPointsService.instance.markAppWentToBackground();
    } else if (state == AppLifecycleState.resumed) {
      if (hasOnboard) {
        MindsetPointsService.instance.incrementOpenOnResume();
      }
    } else if (state == AppLifecycleState.detached) {
      MindsetPointsService.instance.markAppKilled();
    }
  }
}
