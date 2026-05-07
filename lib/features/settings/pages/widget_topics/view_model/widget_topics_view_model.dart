import 'package:businessmindset/features/settings/pages/widget_topics/view_model/widget_topics_ui_state.dart';
import 'package:businessmindset/models/topics.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/providers/widget_preferences.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/services/widget_subscription_sync.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WidgetTopicsViewModel extends StateNotifier<WidgetTopicsUiState> {
  WidgetTopicsViewModel(this._ref) : super(const WidgetTopicsUiState());

  final Ref _ref;
  static const MethodChannel _widgetChannel =
      MethodChannel('businessmindset/deeplink');

  Future<void> loadInitialSelection() async {
    final prefs = _ref.read(sharedPrefsProvider);
    final stored = await loadWidgetTopics(prefs);
    final isPremium = _ref.read(premiumProvider);
    final hasStored = prefs.getStringList(widgetTopicsKey) != null;

    Set<String> initialSelection;
    if (!hasStored || stored.isEmpty) {
      initialSelection = {
        isPremium ? personalizedFeedTopicId : generalTopicDefinition.id,
      };
    } else {
      initialSelection = stored.toSet();
    }

    state = state.copyWith(
      selected: initialSelection,
      loading: false,
    );
  }

  bool isTopicLocked(String topicId, bool premium) {
    if (premium) return false;
    if (topicId == generalTopicDefinition.id) return false;
    if (topicId == 'favoritesquotes') return false;
    if (topicId == 'resilience') return false;
    if (topicId == 'vispurp') return false;
    return true;
  }

  /// Retourne true si on a pu toggle, false si bloqué premium.
  bool toggleTopic(TopicDefinition topic) {
    if (state.loading) return true;
    final isPremium = _ref.read(premiumProvider);
    final locked = isTopicLocked(topic.id, isPremium);
    final alreadySelected = state.selected.contains(topic.id);
    if (locked && !alreadySelected) return false;

    final next = Set<String>.from(state.selected);
    if (next.contains(topic.id)) {
      next.remove(topic.id);
    } else {
      next.add(topic.id);
    }
    state = state.copyWith(selected: next);
    return true;
  }

  Future<List<String>?> saveAndSync() async {
    if (state.loading) return null;
    final isPremium = _ref.read(premiumProvider);
    final next = Set<String>.from(state.selected);

    if (next.isEmpty) {
      next.add(isPremium ? personalizedFeedTopicId : generalTopicDefinition.id);
    }

    final filtered = next.where((id) => !isTopicLocked(id, isPremium)).toSet();
    if (filtered.isEmpty) {
      filtered.add(isPremium ? personalizedFeedTopicId : generalTopicDefinition.id);
    }

    final prefs = _ref.read(sharedPrefsProvider);
    await saveWidgetTopics(prefs, filtered.toList());
    await _syncWidgetComplete();
    return filtered.toList(growable: false);
  }

  Future<void> _syncWidgetComplete() async {
    final prefs = _ref.read(sharedPrefsProvider);
    final freshThemeIndex = prefs.getInt('widgetThemeIndex') ?? 0;
    final topics = await loadWidgetTopics(prefs);
    final favorites = await loadWidgetFavorites(prefs);
    final frequency = await loadWidgetFrequency(prefs);
    final buttons = await loadWidgetButtons(prefs);

    if (kDebugMode) {
      debugPrint('WidgetTopicsPage: Synchronizing widget configuration...');
    }

    await prefs.setBool('widgetConfigured', true);
    MixpanelService.instance.track('[Widget] Refresh widget', {
      'source': 'widget_topics_page',
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
      if (kDebugMode) debugPrint('Failed to update widget data: $error');
    }

    try {
      await _widgetChannel.invokeMethod('reloadWidgets');
    } catch (error) {
      if (kDebugMode) debugPrint('Failed to reload widgets: $error');
    }
  }
}

