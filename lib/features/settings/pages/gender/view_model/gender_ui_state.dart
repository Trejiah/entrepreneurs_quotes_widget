import 'package:businessmindset/features/settings/pages/gender/model/gender_models.dart';

class GenderUiState {
  const GenderUiState({
    this.selected,
    this.isLoaded = false,
  });

  final GenderChoice? selected;
  final bool isLoaded;

  GenderUiState copyWith({
    GenderChoice? selected,
    bool? isLoaded,
    bool clearSelected = false,
  }) {
    return GenderUiState(
      selected: clearSelected ? null : (selected ?? this.selected),
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

