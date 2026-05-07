import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/onboarding_draft_repository_provider.dart';
import 'improvement_step_ui_state.dart';
import 'improvement_step_view_model.dart';

final improvementStepProvider = StateNotifierProvider.autoDispose
    .family<ImprovementStepViewModel, ImprovementStepUiState, List<String>>(
  (ref, choiceList) =>
      ImprovementStepViewModel(choiceList, ref.read(onboardingDraftRepositoryProvider)),
);
