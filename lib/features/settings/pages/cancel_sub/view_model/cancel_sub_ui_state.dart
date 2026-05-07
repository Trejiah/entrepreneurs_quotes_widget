class CancelSubUiState {
  const CancelSubUiState({
    this.isChecked = const [],
  });

  final List<bool> isChecked;

  CancelSubUiState copyWith({
    List<bool>? isChecked,
  }) {
    return CancelSubUiState(
      isChecked: isChecked ?? this.isChecked,
    );
  }
}

