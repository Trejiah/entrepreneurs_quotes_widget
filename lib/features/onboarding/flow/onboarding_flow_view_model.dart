import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/onboarding_page_time_service.dart';
import '../data/onboarding_draft_repository.dart';
import 'onboarding_flow_state.dart';
import 'onboarding_step_registry.dart';

class OnboardingFlowViewModel extends StateNotifier<OnboardingFlowState> {
  OnboardingFlowViewModel(this._draftRepository)
      : super(
          const OnboardingFlowState(
            currentStep: 0,
            maxStep: OnboardingStepRegistry.maxStep,
          ),
        );

  final OnboardingDraftRepository _draftRepository;

  Future<void> init() async {
    final saved = await _draftRepository.readCurrentStep();
    final clamped = saved.clamp(0, state.maxStep);
    OnboardingPageTimeService.markPageOpened(clamped);
    state = state.copyWith(currentStep: clamped, isReady: true);
  }

  Future<void> next([int delta = 1]) async {
    final nextStep = (state.currentStep + delta).clamp(0, state.maxStep);
    state = state.copyWith(currentStep: nextStep);
    OnboardingPageTimeService.markPageOpened(nextStep);
    await _saveCurrentStep();
  }

  Future<void> previous() async {
    final previousStep = (state.currentStep - 1).clamp(0, state.maxStep);
    state = state.copyWith(currentStep: previousStep);
    OnboardingPageTimeService.markPageOpened(previousStep);
    await _saveCurrentStep();
  }

  Future<void> setStep(int step) async {
    final clamped = step.clamp(0, state.maxStep);
    state = state.copyWith(currentStep: clamped);
    OnboardingPageTimeService.markPageOpened(clamped);
    await _saveCurrentStep();
  }

  Future<void> jumpTo(int step) => setStep(step);

  Future<void> skip([int delta = 1]) => next(delta);

  /// Reprend le flow depuis les préférences (même logique que [init]).
  Future<void> resume() => init();

  Future<void> complete() async {
    await _draftRepository.markOnboardingCompleted();
    await setStep(state.maxStep);
  }

  Future<void> _saveCurrentStep() async {
    await _draftRepository.saveCurrentStep(state.currentStep);
  }
}
