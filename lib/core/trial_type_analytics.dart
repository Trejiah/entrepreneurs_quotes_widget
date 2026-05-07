import '../config/revenuecat_keys.dart';

/// `trial_type` value for Mixpanel / analytics (consistent with App Store / Play products).
String trialTypeAnalyticsValue({
  required String productIdLower,
  required bool isInTrial,
}) {
  final id14 = getSubscriptionProductId14().toLowerCase();
  final id3 = getSubscriptionProductId3TrialAb().toLowerCase();
  final id7 = getSubscriptionProductId().toLowerCase();

  if (productIdLower.contains('14') || productIdLower == id14) {
    return 'trial_14_days';
  }
  if (productIdLower == id3) {
    return 'trial_3_days';
  }
  if (isInTrial) {
    if (productIdLower == id7) return 'trial_7_days';
    return 'trial_other';
  }
  return 'no_trial';
}
