import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incrémenté après chaque deep link `businessmindset://home` une fois le flag
/// `openedFromWidget` écrit. HomePage écoute pour relancer le chargement de la
/// citation widget si le premier passage était en course avec le deep link.
final widgetHomeDeepLinkTickProvider = StateProvider<int>((ref) => 0);

/// Remote Config `show_item` (bool) — paywall close button display, default `true`.
final crossShowItemProvider =
    StateNotifierProvider<CrossShowItemNotifier, bool>((ref) {
  return CrossShowItemNotifier();
});

class CrossShowItemNotifier extends StateNotifier<bool> {
  CrossShowItemNotifier() : super(true) {
    _fetchRemoteFlags();
  }

  Future<void> _fetchRemoteFlags() async {
    if (Firebase.apps.isEmpty) {
      return;
    }

    final remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setDefaults({'show_item': true});

    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval:
            kDebugMode ? Duration.zero : const Duration(hours: 1),
      ),
    );

    try {
      await remoteConfig.fetchAndActivate();
      state = remoteConfig.getBool('show_item');
      if (kDebugMode) {
        debugPrint('[RemoteConfig] show_item = $state');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Remote config unreachable, using default: $e');
      }
    }
  }
}
