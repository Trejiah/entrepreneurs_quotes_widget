import 'package:businessmindset/features/settings/pages/retake_test_flow/view_model/retake_test_ui_state.dart';
import 'package:businessmindset/features/settings/pages/retake_test_flow/view_model/retake_test_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final retakeTestViewModelProvider =
    StateNotifierProvider.autoDispose<RetakeTestViewModel, RetakeTestUiState>(
  (ref) => RetakeTestViewModel(),
);
