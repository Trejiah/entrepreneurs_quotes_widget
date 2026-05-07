class WidgetFrequencyUiState {
  const WidgetFrequencyUiState({
    this.selectedId = '',
    this.loading = true,
  });

  final String selectedId;
  final bool loading;

  WidgetFrequencyUiState copyWith({
    String? selectedId,
    bool? loading,
  }) {
    return WidgetFrequencyUiState(
      selectedId: selectedId ?? this.selectedId,
      loading: loading ?? this.loading,
    );
  }
}

