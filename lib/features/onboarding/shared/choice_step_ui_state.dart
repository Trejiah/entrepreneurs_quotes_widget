class ChoiceStepUiState {
  const ChoiceStepUiState({
    this.isSaving = false,
    this.selectedChoice,
  });

  final bool isSaving;
  final String? selectedChoice;

  ChoiceStepUiState copyWith({
    bool? isSaving,
    String? selectedChoice,
  }) {
    return ChoiceStepUiState(
      isSaving: isSaving ?? this.isSaving,
      selectedChoice: selectedChoice ?? this.selectedChoice,
    );
  }
}
