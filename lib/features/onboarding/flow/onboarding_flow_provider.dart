import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_draft_repository_provider.dart';
import 'onboarding_flow_state.dart';
import 'onboarding_flow_view_model.dart';

final onboardingFlowProvider =
    StateNotifierProvider<OnboardingFlowViewModel, OnboardingFlowState>(
  (ref) => OnboardingFlowViewModel(ref.read(onboardingDraftRepositoryProvider)),
);
