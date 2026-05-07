class WidgetButtonsUiState {
  const WidgetButtonsUiState({
    this.selectedIds = const <String>{},
    this.loading = true,
  });

  final Set<String> selectedIds;
  final bool loading;

  WidgetButtonsUiState copyWith({
    Set<String>? selectedIds,
    bool? loading,
  }) {
    return WidgetButtonsUiState(
      selectedIds: selectedIds ?? this.selectedIds,
      loading: loading ?? this.loading,
    );
  }
}

