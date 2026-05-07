/// Résultat normalisé pour restore / reprise d’abonnement pendant l’onboarding ou le paywall.
enum OnboardingRestoreCoordinatorOutcome {
  /// Achat restauré, enchaînement possible (ex. popup cloud).
  restoredContinue,

  /// Restore OK mais aucun achat actif — feedback UI attendu (SnackBar).
  purchaseNotFound,

  /// Annulation utilisateur / état indéterminé — pas de message.
  silentStop,

  /// Erreur technique — SnackBar erreur générique déjà géré côté UI si besoin.
  error,
}
