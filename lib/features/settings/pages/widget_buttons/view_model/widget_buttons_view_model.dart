import 'package:businessmindset/data/widget_buttons.dart';
import 'package:businessmindset/features/settings/pages/widget_buttons/view_model/widget_buttons_ui_state.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/providers/widget_preferences.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/services/widget_subscription_sync.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WidgetButtonsViewModel extends StateNotifier<WidgetButtonsUiState> {
  WidgetButtonsViewModel(this._ref) : super(const WidgetButtonsUiState());

  final Ref _ref;
  static const MethodChannel _widgetChannel =
      MethodChannel('businessmindset/deeplink');

  Future<void> loadInitialSelection() async {
    final prefs = _ref.read(sharedPrefsProvider);
    final stored = await loadWidgetButtons(prefs);
    state = state.copyWith(
      selectedIds:
          stored.isEmpty ? {...defaultWidgetButtonSelection} : Set<String>.from(stored),
      loading: false,
    );
  }

  void toggleOption(WidgetButtonOption option) {
    if (state.loading) return;
    final next = Set<String>.from(state.selectedIds);
    if (option.id == widgetButtonNoneId) {
      state = state.copyWith(selectedIds: {widgetButtonNoneId});
      return;
    }
    if (next.contains(option.id)) {
      next.remove(option.id);
    } else {
      next.add(option.id);
    }
    next.remove(widgetButtonNoneId);
    final hasActionButton =
        next.contains(widgetButtonShareId) || next.contains(widgetButtonLikeId);
    if (!hasActionButton) {
      state = state.copyWith(selectedIds: {widgetButtonNoneId});
      return;
    }
    state = state.copyWith(selectedIds: next);
  }

  Future<Set<String>?> saveAndSync() async {
    if (state.loading) return null;
    final prefs = _ref.read(sharedPrefsProvider);
    await saveWidgetButtons(prefs, state.selectedIds);
    await _syncWidgetWithCurrentPrefs();
    return {...state.selectedIds};
  }

  Future<void> _syncWidgetWithCurrentPrefs() async {
    final prefs = _ref.read(sharedPrefsProvider);
    final freshThemeIndex = prefs.getInt('widgetThemeIndex') ?? 0;
    final topics = await loadWidgetTopics(prefs);
    final favorites = await loadWidgetFavorites(prefs);
    final frequency = await loadWidgetFrequency(prefs);
    final buttons = await loadWidgetButtons(prefs);

    if (kDebugMode) {
      debugPrint('WidgetButtonsPage: Synchronizing widget configuration...');
    }

    await prefs.setBool('widgetConfigured', true);
    MixpanelService.instance.track('[Widget] Refresh widget', {
      'source': 'widget_buttons_page',
    });

    final planGrowthPercentage = prefs.getDouble('plan_growth_percentage') ?? 0.0;
    final planDisciplinePercentage =
        prefs.getDouble('plan_discipline_percentage') ?? 0.0;
    final planConfidencePercentage =
        prefs.getDouble('plan_confidence_percentage') ?? 0.0;
    final planStrategyPercentage =
        prefs.getDouble('plan_strategy_percentage') ?? 0.0;
    final gender = prefs.getString('gender');
    final affirmationPercentage = prefs.getInt('tone_value_AFFIRMATION') ?? 0;
    final noMercyPercentage = prefs.getInt('tone_value_NO MERCY') ?? 0;
    final lang = _ref.read(languageProvider);
    final premiumExpirationEpochMs = await fetchWidgetPremiumExpirationEpochMs();

    try {
      await _widgetChannel.invokeMethod('updateWidgetData', {
        'configured': true,
        'themeIndex': freshThemeIndex,
        'topics': topics,
        'favorites': favorites.map((e) => e.toJson()).toList(growable: false),
        'frequency': frequency,
        'buttons': buttons.toList(growable: false),
        'isPremium': _ref.read(premiumProvider),
        'premiumExpirationEpochMs': premiumExpirationEpochMs,
        'language': lang,
        'planGrowthPercentage': planGrowthPercentage,
        'planDisciplinePercentage': planDisciplinePercentage,
        'planConfidencePercentage': planConfidencePercentage,
        'planStrategyPercentage': planStrategyPercentage,
        'gender': gender,
        'affirmationPercentage': affirmationPercentage,
        'noMercyPercentage': noMercyPercentage,
      });
      if (kDebugMode) {
        debugPrint('WidgetButtonsPage: Sent configuration to iOS widget');
      }
    } catch (error) {
      if (kDebugMode) debugPrint('Failed to update widget data: $error');
    }

    try {
      await _widgetChannel.invokeMethod('reloadWidgets');
      if (kDebugMode) debugPrint('WidgetButtonsPage: Reloaded iOS widget');
    } catch (error) {
      if (kDebugMode) debugPrint('Failed to reload widgets: $error');
    }
  }
}

