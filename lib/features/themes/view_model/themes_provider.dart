import 'package:businessmindset/features/themes/view_model/themes_ui_state.dart';
import 'package:businessmindset/features/themes/view_model/themes_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themesViewModelProvider =
    StateNotifierProvider.autoDispose<ThemesNotifier, ThemesUiState>((ref) {
  return ThemesNotifier(ref);
});

