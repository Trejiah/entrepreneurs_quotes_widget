class LeaveMessageUiState {
  const LeaveMessageUiState({
    this.message = '',
  });

  final String message;

  int get characterCount => message.length;

  LeaveMessageUiState copyWith({
    String? message,
  }) {
    return LeaveMessageUiState(
      message: message ?? this.message,
    );
  }
}

