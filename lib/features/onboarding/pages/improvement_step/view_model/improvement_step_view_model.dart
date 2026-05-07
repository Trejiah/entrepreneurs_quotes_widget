import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/onboarding_draft_repository.dart';
import 'improvement_step_ui_state.dart';

class ImprovementStepViewModel extends StateNotifier<ImprovementStepUiState> {
  ImprovementStepViewModel(this.choiceList, this._draftRepository)
      : super(
          ImprovementStepUiState(
            isChecked: List<bool>.filled(choiceList.length, false),
          ),
        );

  final List<String> choiceList;
  final OnboardingDraftRepository _draftRepository;

  Future<void> loadSavedSelections() async {
    final saved = await _draftRepository.readStringList('improvement');
    final checked = choiceList.map(saved.contains).toList(growable: false);
    state = state.copyWith(isChecked: checked, isLoading: false);
  }

  void toggleAt(int index, bool value) {
    final updated = List<bool>.from(state.isChecked);
    if (index < 0 || index >= updated.length) return;
    updated[index] = value;
    state = state.copyWith(isChecked: updated);
  }

  Future<void> saveSelections() async {
    final selected = <String>[];
    for (var i = 0; i < choiceList.length; i++) {
      if (state.isChecked[i]) selected.add(choiceList[i]);
    }
    await _draftRepository.saveStringList('improvement', selected);
    if (kDebugMode) {
      debugPrint('[Onboarding4] saved improvement: $selected');
    }
  }
}
