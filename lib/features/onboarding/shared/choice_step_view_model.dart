import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_draft_repository.dart';

import 'choice_step_ui_state.dart';

class ChoiceStepViewModel extends StateNotifier<ChoiceStepUiState> {
  ChoiceStepViewModel(this._draftRepository) : super(const ChoiceStepUiState());

  final OnboardingDraftRepository _draftRepository;

  Future<void> saveChoice({
    required String? variable,
    required String choice,
  }) async {
    if (variable == null) return;
    state = state.copyWith(isSaving: true);
    await _draftRepository.saveString(variable, choice);
    if (variable == 'gender') {
      MixpanelService.instance.track('[Profile] Gender Selected', {
        'gender': choice,
        'source': 'onboarding',
      });
    }
    if (kDebugMode) {
      debugPrint('[Onboarding] Saved choice for $variable: $choice');
    }
    state = state.copyWith(isSaving: false, selectedChoice: choice);
  }
}
