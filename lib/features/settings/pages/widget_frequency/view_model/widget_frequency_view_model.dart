import 'package:businessmindset/data/widget_frequency.dart';
import 'package:businessmindset/features/settings/pages/widget_frequency/view_model/widget_frequency_ui_state.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/providers/widget_preferences.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/services/widget_subscription_sync.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WidgetFrequencyViewModel extends StateNotifier<WidgetFrequencyUiState> {
  WidgetFrequencyViewModel(this._ref) : super(const WidgetFrequencyUiState());

  final Ref _ref;
  static const MethodChannel _widgetChannel =
      MethodChannel('businessmindset/deeplink');

  Future<void> loadInitialSelection() async {
    final prefs = _ref.read(sharedPrefsProvider);
    final stored = await loadWidgetFrequency(prefs);
    state = state.copyWith(
      selectedId: stored,
      loading: false,
    );
  }

  bool canSelectOption(WidgetFrequencyOption option) {
    final premium = _ref.read(premiumProvider);
    return !(option.requiresPremium && !premium);
  }

  void selectOption(WidgetFrequencyOption option) {
    if (state.loading) return;
    if (!canSelectOption(option)) return;
    state = state.copyWith(selectedId: option.id);
  }

  Future<String?> saveAndSync() async {
    if (state.loading) return null;
    final prefs = _ref.read(sharedPrefsProvider);
    await saveWidgetFrequency(prefs, state.selectedId);
    await _syncWidgetComplete();
    return state.selectedId;
  }

  Future<void> _syncWidgetComplete() async {
    final prefs = _ref.read(sharedPrefsProvider);
    final freshThemeIndex = prefs.getInt('widgetThemeIndex') ?? 0;
    final topics = await loadWidgetTopics(prefs);
    final favorites = await loadWidgetFavorites(prefs);
    final frequency = await loadWidgetFrequency(prefs);
    final buttons = await loadWidgetButtons(prefs);

    if (kDebugMode) {
      debugPrint('WidgetFrequencyPage: Synchronizing widget configuration...');
    }

    await prefs.setBool('widgetConfigured', true);
    MixpanelService.instance.track('[Widget] Refresh widget', {
      'source': 'widget_frequency_page',
    });

    try {
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
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to update widget data: $error');
      }
    }

    try {
      await _widgetChannel.invokeMethod('reloadWidgets');
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to reload widgets: $error');
      }
    }
  }
}

