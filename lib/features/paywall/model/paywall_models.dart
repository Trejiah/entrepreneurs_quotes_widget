/// Résultat de `purchasePrimaryPlans` sur le paywall principal.
enum PaywallbPurchaseOutcome {
  success,
  noProductAvailable,
  cancelled,
  completedWithoutActiveEntitlement,
  failed,
}

class PaywallbInput {
  const PaywallbInput({
    required this.pageStyle,
    required this.title,
    required this.subTitle,
    required this.choiceList,
    required this.backIcon,
    required this.skipLink,
    this.hardPaywallMode = false,
    this.variable,
    this.buttonText,
  });

  final String pageStyle;
  final String title;
  final String subTitle;
  final List<String> choiceList;
  final bool backIcon;
  final bool skipLink;
  final bool hardPaywallMode;

  // Paramètres optionnels (utile pour une migration future complète côté VM).
  final String? variable;
  final String? buttonText;
}

