class WidgetTopicsUiState {
  const WidgetTopicsUiState({
    this.selected = const <String>{},
    this.loading = true,
  });

  final Set<String> selected;
  final bool loading;

  WidgetTopicsUiState copyWith({
    Set<String>? selected,
    bool? loading,
  }) {
    return WidgetTopicsUiState(
      selected: selected ?? this.selected,
      loading: loading ?? this.loading,
    );
  }
}

