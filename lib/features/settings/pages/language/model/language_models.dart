enum LanguageUsed { en, fr }

const Map<LanguageUsed, String> kLanguageLabels = {
  LanguageUsed.en: 'en',
  LanguageUsed.fr: 'fr',
};

LanguageUsed? languageFromString(String? value) {
  if (value == null) return LanguageUsed.en;
  try {
    return kLanguageLabels.entries.firstWhere((e) => e.value == value).key;
  } catch (_) {
    return null;
  }
}

String languageToString(LanguageUsed language) => kLanguageLabels[language]!;

