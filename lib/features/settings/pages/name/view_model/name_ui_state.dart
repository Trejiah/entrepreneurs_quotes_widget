class NameUiState {
  const NameUiState({
    this.currentName = '',
    this.initialName = '',
  });

  final String currentName;
  final String initialName;

  bool get isButtonEnabled => currentName.trimRight().isNotEmpty;
  int get characterCount => currentName.length;

  NameUiState copyWith({
    String? currentName,
    String? initialName,
  }) {
    return NameUiState(
      currentName: currentName ?? this.currentName,
      initialName: initialName ?? this.initialName,
    );
  }
}

