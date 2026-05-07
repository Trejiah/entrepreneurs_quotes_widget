import 'package:businessmindset/features/themes/model/themes_models.dart';

class ThemesUiState {
  const ThemesUiState({
    this.selectedCustomIndex,
    this.selectedAppIndex,
    this.lastOutcome = const ThemesOutcomeNone(),
  });

  final int? selectedCustomIndex;
  final int? selectedAppIndex;
  final ThemesOutcome lastOutcome;

  ThemesUiState copyWith({
    int? selectedCustomIndex,
    int? selectedAppIndex,
    ThemesOutcome? lastOutcome,
    bool clearSelectedCustomIndex = false,
    bool clearSelectedAppIndex = false,
  }) {
    return ThemesUiState(
      selectedCustomIndex:
          clearSelectedCustomIndex ? null : (selectedCustomIndex ?? this.selectedCustomIndex),
      selectedAppIndex:
          clearSelectedAppIndex ? null : (selectedAppIndex ?? this.selectedAppIndex),
      lastOutcome: lastOutcome ?? this.lastOutcome,
    );
  }
}

