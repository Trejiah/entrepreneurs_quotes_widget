class CropImageUiState {
  const CropImageUiState({
    this.imageData,
    this.isLoading = true,
    this.errorMessage,
  });

  final List<int>? imageData;
  final bool isLoading;
  final String? errorMessage;

  CropImageUiState copyWith({
    List<int>? imageData,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CropImageUiState(
      imageData: imageData ?? this.imageData,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

