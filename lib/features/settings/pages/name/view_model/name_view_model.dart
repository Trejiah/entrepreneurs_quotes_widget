import 'package:businessmindset/features/settings/pages/name/view_model/name_ui_state.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/services/save_cloud.dart';
import 'package:businessmindset/services/widget_subscription_sync.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NameViewModel extends StateNotifier<NameUiState> {
  NameViewModel(this._ref) : super(const NameUiState());

  final Ref _ref;
  static const MethodChannel _widgetChannel =
      MethodChannel('businessmindset/deeplink');

  void init(String initialName) {
    state = state.copyWith(
      initialName: initialName,
      currentName: initialName,
    );

    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📋 [NamePage] Loading");
      debugPrint("   - userName: $initialName");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }

  void onNameChanged(String value) {
    state = state.copyWith(currentName: value);
  }

  Future<bool> saveInput() async {
    final trimmedName = state.currentName.trimRight();
    if (trimmedName.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', trimmedName);
    await prefs.setString('name', trimmedName);
    saveOneToCloud('', 'userName', trimmedName);
    _ref.read(userNameStateProvider.notifier).state = trimmedName;

    try {
      final premiumExpirationEpochMs = await fetchWidgetPremiumExpirationEpochMs();
      await _widgetChannel.invokeMethod('updateWidgetData', {
        'userName': trimmedName,
        'premiumExpirationEpochMs': premiumExpirationEpochMs,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint("⚠️ [NamePage] Error while saving userName to the widget: $e");
      }
    }

    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📋 [NamePage] Sauvegarde");
      debugPrint("   - userName: $trimmedName");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }

    return true;
  }
}

