import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:businessmindset/features/settings/view_model/settings_ui_state.dart';
import 'package:businessmindset/features/settings/view_model/settings_view_model.dart';

final settingsViewModelProvider =
    StateNotifierProvider<SettingsNotifier, SettingsUiState>((ref) {
  return SettingsNotifier();
});
