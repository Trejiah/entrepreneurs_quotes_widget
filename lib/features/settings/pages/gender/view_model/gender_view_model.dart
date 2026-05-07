import 'package:businessmindset/features/settings/pages/gender/model/gender_models.dart';
import 'package:businessmindset/features/settings/pages/gender/view_model/gender_ui_state.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/services/save_cloud.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GenderViewModel extends StateNotifier<GenderUiState> {
  GenderViewModel(Ref ref) : super(const GenderUiState());

  Future<void> loadPref() async {
    final prefs = await SharedPreferences.getInstance();
    final selected = genderFromString(prefs.getString('gender'));

    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📋 [GenderPage] Loading');
      debugPrint(
        '   - gender: ${selected != null ? genderToString(selected) : "null"}',
      );
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    state = state.copyWith(
      selected: selected,
      isLoaded: true,
    );
  }

  void selectGender(GenderChoice choice) {
    state = state.copyWith(selected: choice);
  }

  Future<void> saveInput() async {
    final selected = state.selected;
    if (selected == null) return;

    final prefs = await SharedPreferences.getInstance();
    final genderValue = genderToString(selected);
    await prefs.setString('gender', genderValue);
    saveOneToCloud('survey', 'gender', genderValue);

    MixpanelService.instance.track('[Profile] Gender Selected', {
      'gender': genderValue,
      'source': 'settings',
    });

    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📋 [GenderPage] Sauvegarde');
      debugPrint('   - gender: $genderValue');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }
}

