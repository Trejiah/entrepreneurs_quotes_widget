import 'package:businessmindset/features/share_preview/model/share_preview_models.dart';
import 'package:businessmindset/features/share_preview/view_model/share_preview_ui_state.dart';
import 'package:businessmindset/features/share_preview/view_model/share_preview_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sharePreviewViewModelProvider = StateNotifierProvider.autoDispose
    .family<SharePreviewNotifier, SharePreviewUiState, SharePreviewInput>(
  (ref, input) => SharePreviewNotifier(input),
);

