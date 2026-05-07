class TestPageUiState {
  const TestPageUiState({
    this.inputText = '',
  });

  final String inputText;

  int get characterCount => inputText.length;

  TestPageUiState copyWith({
    String? inputText,
  }) {
    return TestPageUiState(
      inputText: inputText ?? this.inputText,
    );
  }
}

