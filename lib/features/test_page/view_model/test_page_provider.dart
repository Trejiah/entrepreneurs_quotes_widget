import 'package:businessmindset/features/test_page/view_model/test_page_ui_state.dart';
import 'package:businessmindset/features/test_page/view_model/test_page_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final testPageViewModelProvider =
    StateNotifierProvider.autoDispose<TestPageNotifier, TestPageUiState>(
  (ref) => TestPageNotifier(),
);

