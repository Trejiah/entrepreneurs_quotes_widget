import 'package:businessmindset/features/share_preview/model/share_preview_models.dart';
import 'package:businessmindset/features/share_preview/view_model/share_preview_ui_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SharePreviewNotifier extends StateNotifier<SharePreviewUiState> {
  SharePreviewNotifier(SharePreviewInput input)
      : super(SharePreviewUiState(input: input));

  static const MethodChannel _channel = MethodChannel('businessmindset/deeplink');

  Future<void> saveImageToGallery() async {
    if (state.isSaving) return;
    state = state.copyWith(isSaving: true);
    try {
      await _channel.invokeMethod('saveImageToGallery', {
        'imageBytes': Uint8List.fromList(state.input.imageBytes),
      });
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<void> shareImageDirect() async {
    if (state.isSharing) return;
    state = state.copyWith(isSharing: true);
    try {
      await _channel.invokeMethod('shareImageDirect', {
        'imageBytes': Uint8List.fromList(state.input.imageBytes),
      });
    } finally {
      state = state.copyWith(isSharing: false);
    }
  }

  String buildShareText() {
    return SharePreviewTextBuilder.build(
      quote: state.input.quote,
      signature: state.input.signature,
      bookTitle: state.input.bookTitle,
    );
  }
}

