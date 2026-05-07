import 'package:businessmindset/features/test_page/view_model/test_page_ui_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TestPageNotifier extends StateNotifier<TestPageUiState> {
  TestPageNotifier() : super(const TestPageUiState());

  void onTextChanged(String value) {
    state = state.copyWith(inputText: value);
  }
}

