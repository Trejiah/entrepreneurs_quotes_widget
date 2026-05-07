import 'package:purchases_flutter/purchases_flutter.dart';

class PaywallbUiState {
  const PaywallbUiState({
    this.currentWhatsIncludedPage = 0,
    this.isLoadingPackage = false,
    this.isLoadingPackage14 = false,
    this.isEligibleForTrial = true,
    this.isCheckingTrialEligibility = true,
    this.reminderEnabled = false,
    this.isInTrial = true,
    this.trialDays = 7,
    this.annualProduct,
    this.monthlyProduct,
    this.annualProduct14,
    this.isSubscriptionActive = false,
    this.isYearlySelected = true,
  });

  final int currentWhatsIncludedPage;
  final bool isLoadingPackage;
  final bool isLoadingPackage14;
  final bool isEligibleForTrial;
  final bool isCheckingTrialEligibility;
  final bool reminderEnabled;
  final bool isInTrial;
  final int trialDays;

  final StoreProduct? annualProduct;
  final StoreProduct? monthlyProduct;
  final StoreProduct? annualProduct14;

  final bool isSubscriptionActive;
  final bool isYearlySelected;

  PaywallbUiState copyWith({
    int? currentWhatsIncludedPage,
    bool? isLoadingPackage,
    bool? isLoadingPackage14,
    bool? isEligibleForTrial,
    bool? isCheckingTrialEligibility,
    bool? reminderEnabled,
    bool? isInTrial,
    int? trialDays,
    StoreProduct? annualProduct,
    StoreProduct? monthlyProduct,
    StoreProduct? annualProduct14,
    bool? isSubscriptionActive,
    bool? isYearlySelected,
  }) {
    return PaywallbUiState(
      currentWhatsIncludedPage:
          currentWhatsIncludedPage ?? this.currentWhatsIncludedPage,
      isLoadingPackage: isLoadingPackage ?? this.isLoadingPackage,
      isLoadingPackage14: isLoadingPackage14 ?? this.isLoadingPackage14,
      isEligibleForTrial: isEligibleForTrial ?? this.isEligibleForTrial,
      isCheckingTrialEligibility:
          isCheckingTrialEligibility ?? this.isCheckingTrialEligibility,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      isInTrial: isInTrial ?? this.isInTrial,
      trialDays: trialDays ?? this.trialDays,
      annualProduct: annualProduct ?? this.annualProduct,
      monthlyProduct: monthlyProduct ?? this.monthlyProduct,
      annualProduct14: annualProduct14 ?? this.annualProduct14,
      isSubscriptionActive: isSubscriptionActive ?? this.isSubscriptionActive,
      isYearlySelected: isYearlySelected ?? this.isYearlySelected,
    );
  }
}

