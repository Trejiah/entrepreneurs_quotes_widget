/// Constantes et helpers de l’écran Thèmes.
class ThemesCatalog {
  /// Ordre fixe des thèmes de l’app (UI index -> original index).
  static const List<int> shuffledAppThemeIndices = [
    15, 66, 6, 42, 7, 22, 39, 18, 16, 53, 50, 40, 4, 20, 62, 25, 29, 33, 44, 48,
    8, 19, 23, 11, 61, 46, 55, 36, 24, 30, 52, 9, 49, 21, 56, 10, 0, 64, 60,
    65, 51, 26, 59, 41, 45, 12, 67, 54, 38, 32, 63, 58, 1, 2, 27, 37, 5, 34,
    57, 47, 43, 13, 17, 28, 31, 35, 3, 14
  ];

  /// Indices gratuits (dans `allAppThemes`).
  static const Set<int> freeThemeIndices = {0, 8, 9, 13, 20, 24, 26, 29, 40, 67};

  static bool isThemeFree(int themeIndex) => freeThemeIndices.contains(themeIndex);
}

enum ThemesPaywallSource {
  createTheme,
  customThemeTap,
  appThemeTap,
}

/// Résultat “UI” pour une action pilotée par le ViewModel.
sealed class ThemesOutcome {
  const ThemesOutcome();
}

class ThemesOutcomeNone extends ThemesOutcome {
  const ThemesOutcomeNone();
}

class ThemesOutcomeOpenPaywall extends ThemesOutcome {
  const ThemesOutcomeOpenPaywall(this.source);
  final ThemesPaywallSource source;
}

class ThemesOutcomeOpenQuoteEditor extends ThemesOutcome {
  const ThemesOutcomeOpenQuoteEditor();
}

class ThemesOutcomeOpenCropForWidget extends ThemesOutcome {
  const ThemesOutcomeOpenCropForWidget({
    required this.customIndex,
    required this.imagePath,
  });

  final int customIndex;
  final String imagePath;
}

class ThemesOutcomeShowSnack extends ThemesOutcome {
  const ThemesOutcomeShowSnack(this.translationKey);
  final String translationKey;
}

class ThemesOutcomePop extends ThemesOutcome {
  const ThemesOutcomePop({required this.modified});
  final bool modified;
}
