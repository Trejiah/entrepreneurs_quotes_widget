import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Point d’extension pour charger les données cloud pendant l’onboarding.
/// L’implémentation concrète reste dans les services (Firebase, etc.) ;
/// ce contrat documente l’intention MVVM / testabilité.
abstract class OnboardingCloudSync {
  /// Charge le profil utilisateur distant et applique les providers locaux.
  Future<void> loadUserCloudIntoApp(WidgetRef ref);
}
