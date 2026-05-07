import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:businessmindset/features/onboarding/pages/onboarding_restore_flow.dart';
import 'package:businessmindset/features/onboarding/restore/onboarding_restore_outcomes.dart';

/// Façade VM-friendly au-dessus de [OnboardingRestoreFlow] (outcomes uniformes).
class OnboardingRestoreCoordinator {
  const OnboardingRestoreCoordinator._();

  static OnboardingRestoreCoordinatorOutcome mapPurchaseStatus(
    RestorePurchaseStatus status,
  ) {
    switch (status) {
      case RestorePurchaseStatus.restored:
        return OnboardingRestoreCoordinatorOutcome.restoredContinue;
      case RestorePurchaseStatus.notFound:
        return OnboardingRestoreCoordinatorOutcome.purchaseNotFound;
      case RestorePurchaseStatus.other:
        return OnboardingRestoreCoordinatorOutcome.silentStop;
    }
  }

  /// Restore seul — réutilise la logique UI existante (SnackBars) puis retourne l’outcome.
  static Future<OnboardingRestoreCoordinatorOutcome> restoreOnly({
    required BuildContext context,
    required WidgetRef ref,
    required String lang,
  }) async {
    final status = await OnboardingRestoreFlow.restoreOnly(
      context: context,
      ref: ref,
      lang: lang,
    );
    return mapPurchaseStatus(status);
  }
}
