import 'package:businessmindset/features/settings/pages/language/view_model/language_ui_state.dart';
import 'package:businessmindset/features/settings/pages/language/view_model/language_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final languagePageViewModelProvider =
    StateNotifierProvider.autoDispose<LanguageViewModel, LanguageUiState>(
  (ref) => LanguageViewModel(ref),
);

