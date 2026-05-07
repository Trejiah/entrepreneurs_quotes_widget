import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_draft_repository_provider.dart';
import 'choice_step_ui_state.dart';
import 'choice_step_view_model.dart';

final choiceStepProvider =
    StateNotifierProvider.autoDispose<ChoiceStepViewModel, ChoiceStepUiState>(
  (ref) => ChoiceStepViewModel(ref.read(onboardingDraftRepositoryProvider)),
);
