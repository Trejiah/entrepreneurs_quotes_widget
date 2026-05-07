import 'package:businessmindset/features/settings/pages/retake_test_flow/view_model/retake_test_ui_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RetakeTestPreviousAction {
  decremented,
  shouldPopFalse,
}

class RetakeTestViewModel extends StateNotifier<RetakeTestUiState> {
  RetakeTestViewModel() : super(const RetakeTestUiState());

  String? _initialSituation;
  List<String> _initialImprovement = [];
  List<String> _initialMainfocus = [];
  List<String> _initialBigchall = [];
  List<String> _initialTopics = [];
  String? _initialGoals;
  final Map<String, double> _initialPlanPercentages = {};

  Future<void> loadInitialValues() async {
    if (state.initialValuesLoaded) return;
    final prefs = await SharedPreferences.getInstance();

    _initialSituation = prefs.getString("situation");
    _initialImprovement = prefs.getStringList("improvement") ?? [];
    _initialMainfocus =
        prefs.getStringList("focus") ?? prefs.getStringList("mainfocus") ?? [];
    _initialBigchall =
        prefs.getStringList("challenge") ?? prefs.getStringList("bigchall") ?? [];
    _initialTopics = prefs.getStringList("topics") ?? [];
    _initialGoals = prefs.getString("goals");

    for (final key in ['growth', 'discipline', 'confidence', 'strategy']) {
      final percentage = prefs.getDouble("plan_${key}_percentage");
      if (percentage != null) {
        _initialPlanPercentages[key] = percentage;
      }
    }

    state = state.copyWith(
      situation: _initialSituation,
      improvement: List.from(_initialImprovement),
      mainfocus: List.from(_initialMainfocus),
      bigchall: List.from(_initialBigchall),
      topics: List.from(_initialTopics),
      goals: _initialGoals,
      planPercentages: Map.from(_initialPlanPercentages),
      initialValuesLoaded: true,
    );
  }

  void nextPage() {
    if (state.currentPage < RetakeTestUiState.maxPages - 1) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  RetakeTestPreviousAction previousPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
      return RetakeTestPreviousAction.decremented;
    }
    return RetakeTestPreviousAction.shouldPopFalse;
  }

  void setSituation(String? value) {
    state = state.copyWith(situation: value);
  }

  void setImprovement(List<String> values) {
    state = state.copyWith(improvement: values);
  }

  void setMainfocus(List<String> values) {
    state = state.copyWith(mainfocus: values);
  }

  void setBigchall(List<String> values) {
    state = state.copyWith(bigchall: values);
  }

  void setTopics(List<String> values) {
    state = state.copyWith(topics: values);
  }

  void setGoals(String? value) {
    state = state.copyWith(goals: value);
  }

  void setPlanPercentages(Map<String, double> percentages) {
    state = state.copyWith(planPercentages: percentages);
  }

  Future<void> saveAndReturn() async {
    final prefs = await SharedPreferences.getInstance();

    if (kDebugMode) {
      debugPrint("💾 [RetakeTestFlow] Saving all data:");
      debugPrint("  situation: ${state.situation}");
      debugPrint("  improvement: ${state.improvement}");
      debugPrint("  mainfocus: ${state.mainfocus}");
      debugPrint("  bigchall: ${state.bigchall}");
      debugPrint("  topics: ${state.topics}");
      debugPrint("  goals: ${state.goals}");
      debugPrint("  planPercentages: ${state.planPercentages}");
    }

    if (state.situation != null) {
      await prefs.setString("situation", state.situation!);
    } else {
      await prefs.remove("situation");
    }
    await prefs.setStringList("improvement", state.improvement);
    await prefs.setStringList("focus", state.mainfocus);
    await prefs.setStringList("challenge", state.bigchall);
    await prefs.setStringList("topics", state.topics);
    if (state.goals != null && state.goals!.isNotEmpty) {
      await prefs.setString("goals", state.goals!);
    } else {
      await prefs.remove("goals");
    }

    for (final key in ['growth', 'discipline', 'confidence', 'strategy']) {
      final percentage = state.planPercentages[key];
      if (percentage != null) {
        await prefs.setDouble("plan_${key}_percentage", percentage);
      }
    }

    await prefs.setBool("testRetaken", true);

    if (kDebugMode) {
      debugPrint("💾 [RetakeTestFlow] All data saved, returning to settings");
    }
  }

  Future<void> cancelAndRestorePrefs() async {
    final prefs = await SharedPreferences.getInstance();

    if (_initialSituation != null) {
      await prefs.setString("situation", _initialSituation!);
    } else {
      await prefs.remove("situation");
    }
    await prefs.setStringList("improvement", _initialImprovement);
    await prefs.setStringList("focus", _initialMainfocus);
    await prefs.setStringList("challenge", _initialBigchall);
    await prefs.setStringList("topics", _initialTopics);
    if (_initialGoals != null) {
      await prefs.setString("goals", _initialGoals!);
    } else {
      await prefs.remove("goals");
    }

    for (final key in ['growth', 'discipline', 'confidence', 'strategy']) {
      final percentage = _initialPlanPercentages[key];
      if (percentage != null) {
        await prefs.setDouble("plan_${key}_percentage", percentage);
      }
    }

    if (kDebugMode) {
      debugPrint("❌ [RetakeTestFlow] Cancelled - values restored");
    }
  }
}
