class NotificationDebugUiState {
  const NotificationDebugUiState({
    this.debugInfo = 'Appuyez sur le bouton pour verifier...',
  });

  final String debugInfo;

  NotificationDebugUiState copyWith({
    String? debugInfo,
  }) {
    return NotificationDebugUiState(
      debugInfo: debugInfo ?? this.debugInfo,
    );
  }
}

