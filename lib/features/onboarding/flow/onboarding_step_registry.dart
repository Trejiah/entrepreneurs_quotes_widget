/// Registre statique du parcours onboarding (indices + métadonnées).
///
/// Les indices correspondent à l’ordre des écrans dans
/// [OnboardingFlowPage] (`lib/features/onboarding/view/onboarding_flow_page.dart`).
class OnboardingStepRegistry {
  OnboardingStepRegistry._();

  /// Dernier index d’étape (inclus). Progression = `currentStep / maxStep`.
  static const int maxStep = 27;

  /// Nombre d’écrans dans le flow (`maxStep + 1`).
  static const int stepCount = maxStep + 1;

  /// Libellés debug pour tests / logging (optionnel).
  static const Map<int, String> debugStepIds = <int, String>{
    0: 'intro_typewriter',
    1: 'welcome_13',
    2: 'improvement_multi',
    3: 'onboarding_56',
    4: 'quotes_swipe_710',
    5: 'welcome_13bis',
    6: 'age',
    7: 'gender',
    8: 'situation',
    9: 'theme',
    10: 'quote_transition',
    11: 'onboarding_19',
    12: 'focus',
    13: 'challenge',
    14: 'onboarding_20',
    15: 'habits',
    16: 'topics',
    17: 'onboarding_25',
    18: 'onboarding_26',
    19: 'onboarding_27',
    20: 'onboarding_28',
    21: 'onboarding_29',
    22: 'onboarding_30',
    23: 'diagnostic_31',
    24: 'radar_32',
    25: 'paywall_33b',
    26: 'paywall_37',
    27: 'paywall_38',
  };
}
