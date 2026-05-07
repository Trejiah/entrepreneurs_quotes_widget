class NotificationUiState {
  const NotificationUiState({
    this.manyCount = 3,
  });

  final int manyCount;

  NotificationUiState copyWith({
    int? manyCount,
  }) {
    return NotificationUiState(
      manyCount: manyCount ?? this.manyCount,
    );
  }
}

