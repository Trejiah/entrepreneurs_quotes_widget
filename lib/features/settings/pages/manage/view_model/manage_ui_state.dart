class ManageUiState {
  const ManageUiState({
    this.currentPeriod = "yearly",
    this.currentType = "freetrial",
    this.currentTEnd = "Mar 7, 2025",
    this.currentSubStart = "Mar 7, 2025",
    this.currentStartedOn = "—",
    this.currentNextRenewal = "—",
    this.isTrialPeriod = true,
    this.isCancelled = false,
  });

  final String currentPeriod;
  final String currentType;
  final String currentTEnd;
  final String currentSubStart;
  final String currentStartedOn;
  final String currentNextRenewal;
  final bool isTrialPeriod;
  final bool isCancelled;

  ManageUiState copyWith({
    String? currentPeriod,
    String? currentType,
    String? currentTEnd,
    String? currentSubStart,
    String? currentStartedOn,
    String? currentNextRenewal,
    bool? isTrialPeriod,
    bool? isCancelled,
  }) {
    return ManageUiState(
      currentPeriod: currentPeriod ?? this.currentPeriod,
      currentType: currentType ?? this.currentType,
      currentTEnd: currentTEnd ?? this.currentTEnd,
      currentSubStart: currentSubStart ?? this.currentSubStart,
      currentStartedOn: currentStartedOn ?? this.currentStartedOn,
      currentNextRenewal: currentNextRenewal ?? this.currentNextRenewal,
      isTrialPeriod: isTrialPeriod ?? this.isTrialPeriod,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }
}

enum RestorePurchaseOutcome {
  success,
  notFound,
  error,
}

