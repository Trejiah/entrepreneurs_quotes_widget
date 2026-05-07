import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:businessmindset/features/custom_editor/view_model/quote_editor_ui_state.dart';
import 'package:businessmindset/features/custom_editor/view_model/quote_editor_view_model.dart';

final quoteEditorViewModelProvider = StateNotifierProvider.autoDispose<
    QuoteEditorNotifier, QuoteEditorUiState>((ref) {
  return QuoteEditorNotifier();
});
