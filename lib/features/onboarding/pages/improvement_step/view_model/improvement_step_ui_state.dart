class ImprovementStepUiState {
  const ImprovementStepUiState({
    required this.isChecked,
    this.isLoading = true,
  });

  final List<bool> isChecked;
  final bool isLoading;

  bool get hasSelection => isChecked.any((checked) => checked);

  ImprovementStepUiState copyWith({
    List<bool>? isChecked,
    bool? isLoading,
  }) {
    return ImprovementStepUiState(
      isChecked: isChecked ?? this.isChecked,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
