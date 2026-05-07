import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_draft_repository_provider.dart';
import 'input_step_ui_state.dart';
import 'input_step_view_model.dart';

final inputStepProvider =
    StateNotifierProvider.autoDispose<InputStepViewModel, InputStepUiState>(
  (ref) => InputStepViewModel(ref.read(onboardingDraftRepositoryProvider)),
);
