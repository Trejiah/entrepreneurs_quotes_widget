import 'package:businessmindset/features/settings/pages/my_feed/view_model/my_feed_ui_state.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/services/save_cloud.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyFeedViewModel extends StateNotifier<MyFeedUiState> {
  MyFeedViewModel(this._ref) : super(MyFeedUiState.initial());

  final Ref _ref;

  static const categoryKeys = ['growth', 'discipline', 'confidence', 'strategy'];
  static const categoryNameKeys = {
    'growth': 'plan_category_growth',
    'discipline': 'plan_category_discipline',
    'confidence': 'plan_category_confidence',
    'strategy': 'plan_category_strategy',
  };

  Future<void> loadSavedPercentages() async {
    final prefs = await SharedPreferences.getInstance();
    final initial = <String, double>{};
    for (final key in categoryKeys) {
      final percentage = prefs.getDouble("plan_${key}_percentage");
      if (percentage != null && percentage >= 10.0 && percentage <= 100.0) {
        initial[key] = percentage;
      } else {
        initial[key] = 25.0;
      }
    }

    final maxAxisValue = initial.isNotEmpty
        ? initial.values.reduce((a, b) => a > b ? a : b)
        : 100.0;
    final axisValues = Map<String, double>.from(initial);
    final calculated = _calculatePercentages(axisValues);

    state = state.copyWith(
      initialPercentages: initial,
      axisValues: axisValues,
      calculatedPercentages: calculated,
      maxAxisValue: maxAxisValue,
      hasChanges: false,
      draggingPoint: null,
    );

    if (kDebugMode) {
      final premium = _ref.read(premiumProvider);
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📋 [MyFeed] Loading");
      debugPrint("   - premium: $premium");
      for (final key in categoryKeys) {
        final initialValue = initial[key] ?? 0.0;
        debugPrint("   - $key: ${initialValue.toStringAsFixed(2)}%");
      }
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }

  void onPointDragged(String categoryKey, double newValue) {
    final clampedValue = newValue.clamp(0.0, state.maxAxisValue);
    final oldValue = state.axisValues[categoryKey] ?? 0.0;
    if ((clampedValue - oldValue).abs() < 0.01) return;

    final updatedAxis = Map<String, double>.from(state.axisValues)
      ..[categoryKey] = clampedValue;
    final updatedCalculated = _calculatePercentages(updatedAxis);
    final hasChanges = updatedAxis.entries.any((entry) {
      final initial = state.initialPercentages[entry.key] ?? 0.0;
      return (entry.value - initial).abs() > 0.1;
    });

    state = state.copyWith(
      axisValues: updatedAxis,
      calculatedPercentages: updatedCalculated,
      hasChanges: hasChanges,
    );
  }

  void setDraggingPoint(String? key) {
    state = state.copyWith(draggingPoint: key);
  }

  void resetToInitial() {
    final axis = Map<String, double>.from(state.initialPercentages);
    state = state.copyWith(
      axisValues: axis,
      calculatedPercentages: _calculatePercentages(axis),
      hasChanges: false,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in state.calculatedPercentages.entries) {
      await prefs.setDouble("plan_${entry.key}_percentage", entry.value);
      saveOneToCloud("personalized_plan", "plan_${entry.key}_percentage", entry.value);
    }

    state = state.copyWith(
      initialPercentages: Map<String, double>.from(state.calculatedPercentages),
      hasChanges: false,
    );

    if (kDebugMode) {
      final premium = _ref.read(premiumProvider);
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📋 [MyFeed] Sauvegarde");
      debugPrint("   - premium: $premium");
      for (final entry in state.calculatedPercentages.entries) {
        debugPrint("   - ${entry.key}: ${entry.value.toStringAsFixed(2)}%");
      }
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }

  Map<String, double> _calculatePercentages(Map<String, double> axisValues) {
    final total = axisValues.values.fold(0.0, (sum, val) => sum + val);
    if (total == 0) {
      return {
        for (final key in categoryKeys) key: 25.0,
      };
    }
    return {
      for (final key in categoryKeys) key: ((axisValues[key] ?? 0.0) / total) * 100.0,
    };
  }
}

