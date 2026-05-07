class OnboardingFlowState {
  const OnboardingFlowState({
    required this.currentStep,
    required this.maxStep,
    this.isReady = false,
  });

  final int currentStep;
  final int maxStep;
  final bool isReady;

  double get progress =>
      maxStep == 0 ? 0 : (currentStep / maxStep).clamp(0.0, 1.0);

  OnboardingFlowState copyWith({
    int? currentStep,
    int? maxStep,
    bool? isReady,
  }) {
    return OnboardingFlowState(
      currentStep: currentStep ?? this.currentStep,
      maxStep: maxStep ?? this.maxStep,
      isReady: isReady ?? this.isReady,
    );
  }
}
