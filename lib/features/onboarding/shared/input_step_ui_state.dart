class InputStepUiState {
  const InputStepUiState({
    this.text = '',
    this.isSaving = false,
  });

  final String text;
  final bool isSaving;

  bool get hasInput => text.trim().isNotEmpty;

  InputStepUiState copyWith({
    String? text,
    bool? isSaving,
  }) {
    return InputStepUiState(
      text: text ?? this.text,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
