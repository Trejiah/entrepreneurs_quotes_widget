/// Contrat unique pour la persistance locale du brouillon d’onboarding.
/// Permet de mocker / remplacer l’implémentation (prefs, future remote, etc.).
abstract class IOnboardingDraftRepository {
  Future<int> readCurrentStep();
  Future<void> saveCurrentStep(int step);
  Future<void> markOnboardingCompleted();
  Future<void> saveString(String key, String value);
  Future<void> saveStringList(String key, List<String> value);
  Future<String?> readString(String key);
  Future<List<String>> readStringList(String key);
  Future<Map<String, Object?>> readCompletionSummary();
}
