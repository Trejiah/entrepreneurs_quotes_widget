import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_draft_repository_contract.dart';

class OnboardingDraftRepository implements IOnboardingDraftRepository {
  static const _stepKey = 'bodyInt';
  static const _hasOnboardKey = 'hasOnboard';
  static const _justCompletedKey = 'justCompletedOnboarding';

  @override
  Future<int> readCurrentStep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_stepKey) ?? 0;
  }

  @override
  Future<void> saveCurrentStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stepKey, step);
  }

  @override
  Future<void> markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasOnboardKey, true);
    await prefs.setBool(_justCompletedKey, true);
  }

  @override
  Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Future<void> saveStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }

  @override
  Future<String?> readString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<List<String>> readStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? const <String>[];
  }

  @override
  Future<Map<String, Object?>> readCompletionSummary() async {
    final prefs = await SharedPreferences.getInstance();
    return <String, Object?>{
      'name': prefs.getString('name') ?? 'Nobody',
      'gender': prefs.getString('gender'),
      'age': prefs.getString('age'),
      'situation': prefs.getString('situation'),
      'mindset': prefs.getString('mindset'),
      'focus': prefs.getStringList('focus') ?? const <String>[],
      'challenge': prefs.getStringList('challenge') ?? const <String>[],
      'topics': prefs.getStringList('topics') ?? const <String>[],
      'selectedTopics': prefs.getStringList('selectedTopics') ?? const <String>[],
      'themeIndex': prefs.getInt('themeIndex') ?? prefs.getInt('currentThemeIndex') ?? 0,
      'isCustomTheme': prefs.getBool('isCustomTheme') ?? false,
    };
  }
}
