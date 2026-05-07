import 'package:businessmindset/features/share_preview/model/share_preview_models.dart';

class SharePreviewUiState {
  const SharePreviewUiState({
    required this.input,
    this.isSaving = false,
    this.isSharing = false,
  });

  final SharePreviewInput input;
  final bool isSaving;
  final bool isSharing;

  SharePreviewUiState copyWith({
    SharePreviewInput? input,
    bool? isSaving,
    bool? isSharing,
  }) {
    return SharePreviewUiState(
      input: input ?? this.input,
      isSaving: isSaving ?? this.isSaving,
      isSharing: isSharing ?? this.isSharing,
    );
  }
}

