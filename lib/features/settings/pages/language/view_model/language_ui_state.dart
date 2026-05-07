import 'package:businessmindset/features/settings/pages/language/model/language_models.dart';

class LanguageUiState {
  const LanguageUiState({
    this.selected,
    this.isLoaded = false,
  });

  final LanguageUsed? selected;
  final bool isLoaded;

  LanguageUiState copyWith({
    LanguageUsed? selected,
    bool? isLoaded,
    bool clearSelected = false,
  }) {
    return LanguageUiState(
      selected: clearSelected ? null : (selected ?? this.selected),
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

