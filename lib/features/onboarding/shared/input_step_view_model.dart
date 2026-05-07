import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_draft_repository.dart';
import 'input_step_ui_state.dart';

class InputStepViewModel extends StateNotifier<InputStepUiState> {
  InputStepViewModel(this._draftRepository) : super(const InputStepUiState());

  final OnboardingDraftRepository _draftRepository;

  void updateText(String text) {
    state = state.copyWith(text: text);
  }

  Future<void> saveInput({
    required String? variable,
    required String value,
  }) async {
    if (variable == null) return;
    state = state.copyWith(isSaving: true);
    final normalized = variable == 'name' ? value.trimRight() : value;
    await _draftRepository.saveString(variable, normalized);
    if (kDebugMode) {
      debugPrint('[Onboarding] Saved input for $variable: $normalized');
    }
    state = state.copyWith(isSaving: false, text: normalized);
  }
}
