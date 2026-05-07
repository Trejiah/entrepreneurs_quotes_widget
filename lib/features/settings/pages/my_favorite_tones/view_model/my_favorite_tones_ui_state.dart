class MyFavoriteTonesUiState {
  const MyFavoriteTonesUiState({
    this.currentIndex = 0,
    this.selectedToneValues = const [null, null],
  });

  final int currentIndex;
  final List<int?> selectedToneValues;

  MyFavoriteTonesUiState copyWith({
    int? currentIndex,
    List<int?>? selectedToneValues,
  }) {
    return MyFavoriteTonesUiState(
      currentIndex: currentIndex ?? this.currentIndex,
      selectedToneValues: selectedToneValues ?? this.selectedToneValues,
    );
  }
}

