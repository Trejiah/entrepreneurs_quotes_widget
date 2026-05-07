import 'package:businessmindset/features/settings/pages/language/model/language_models.dart';
import 'package:businessmindset/features/settings/pages/language/view_model/language_ui_state.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/services/save_cloud.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageViewModel extends StateNotifier<LanguageUiState> {
  LanguageViewModel(this._ref) : super(const LanguageUiState());

  final Ref _ref;

  Future<void> loadPref() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('language');
    final selected = languageFromString(savedLang);

    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📋 [LanguagePage] Loading');
      debugPrint('   - language: ${savedLang ?? "null"}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    state = state.copyWith(selected: selected, isLoaded: true);
  }

  void selectLanguage(LanguageUsed language) {
    state = state.copyWith(selected: language);
  }

  Future<void> saveInput() async {
    final selected = state.selected;
    if (selected == null) return;

    final langCode = languageToString(selected);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
    _ref.read(languageProvider.notifier).state = langCode;
    saveOneToCloud('', 'language', langCode);

    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📋 [LanguagePage] Sauvegarde');
      debugPrint('   - language: $langCode');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }
}

