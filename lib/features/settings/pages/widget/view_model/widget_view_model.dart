import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/data/widget_buttons.dart';
import 'package:businessmindset/data/widget_frequency.dart';
import 'package:businessmindset/features/settings/pages/widget/view_model/widget_ui_state.dart';
import 'package:businessmindset/models/topics.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/providers/widget_preferences.dart' as wp;
import 'package:businessmindset/services/widget_subscription_sync.dart';
import 'package:businessmindset/theme/themedatas.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WidgetViewModel extends StateNotifier<WidgetUiState> {
  WidgetViewModel(this._ref) : super(const WidgetUiState());

  final Ref _ref;

  static const MethodChannel _widgetChannel = MethodChannel('businessmindset/deeplink');

  Future<void> init() async {
    final displayNames = _computeWidgetThemeDisplayNames();
    state = state.copyWith(widgetThemeDisplayNames: displayNames);
    await _ensureWidgetConfiguredOnFirstOpen();
    await loadWidgetTheme();
    await loadWidgetTopics();
    await loadWidgetFrequency();
    await loadWidgetButtons();
  }

  Future<void> _ensureWidgetConfiguredOnFirstOpen() async {
    final prefs = _ref.read(sharedPrefsProvider);
    final widgetConfigured = prefs.getBool('widgetConfigured') ?? false;
    if (widgetConfigured) return;
    await _markWidgetAsConfigured();
  }

  Future<void> _markWidgetAsConfigured() async {
    final prefs = _ref.read(sharedPrefsProvider);
    await prefs.setBool('widgetConfigured', true);
    try {
      final themeIndex = prefs.getInt("widgetThemeIndex") ?? 0;
      final topics = await wp.loadWidgetTopics(prefs);
      final favorites = await wp.loadWidgetFavorites(prefs);
      final frequency = await wp.loadWidgetFrequency(prefs);
      final buttons = await wp.loadWidgetButtons(prefs);
      final lang = _ref.read(languageProvider);
      final planGrowthPercentage = prefs.getDouble("plan_growth_percentage") ?? 0.0;
      final planDisciplinePercentage = prefs.getDouble("plan_discipline_percentage") ?? 0.0;
      final planConfidencePercentage = prefs.getDouble("plan_confidence_percentage") ?? 0.0;
      final planStrategyPercentage = prefs.getDouble("plan_strategy_percentage") ?? 0.0;
      final gender = prefs.getString("gender");
      final affirmationPercentage = prefs.getInt("tone_value_AFFIRMATION") ?? 0;
      final noMercyPercentage = prefs.getInt("tone_value_NO MERCY") ?? 0;
      final premiumExpirationEpochMs = await fetchWidgetPremiumExpirationEpochMs();

      await _widgetChannel.invokeMethod('updateWidgetData', {
        'configured': true,
        'themeIndex': themeIndex,
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
      await _widgetChannel.invokeMethod('reloadWidgets');
      if (kDebugMode) debugPrint('WidgetPage: Widget marked as configured and reloaded');
    } catch (error) {
      if (kDebugMode) debugPrint('WidgetPage: Failed to sync with iOS widget: $error');
    }
  }

  Future<void> loadWidgetTheme() async {
    final prefs = _ref.read(sharedPrefsProvider);
    final hasWidgetThemeIndex = prefs.containsKey("widgetThemeIndex");
    final hasWidgetIsCustomTheme = prefs.containsKey("widgetIsCustomTheme");
    final widgetConfigured = prefs.getBool('widgetConfigured') ?? false;

    int themeIndex;
    bool isCustom;
    if (!hasWidgetThemeIndex || !hasWidgetIsCustomTheme || !widgetConfigured) {
      themeIndex = _ref.read(themeIndexProvider);
      isCustom = _ref.read(isCustomThemeProvider);
      await prefs.setInt("widgetThemeIndex", themeIndex);
      await prefs.setBool("widgetIsCustomTheme", isCustom);
    } else {
      themeIndex = prefs.getInt("widgetThemeIndex") ?? 0;
      isCustom = prefs.getBool("widgetIsCustomTheme") ?? false;
    }

    var selectedTheme = "App theme";
    if (isCustom) {
      final customList = _ref.read(themeCustomListProvider);
      if (themeIndex >= 0 && themeIndex < customList.length) {
        selectedTheme = customList[themeIndex]["name"] ?? "Custom theme";
      } else {
        selectedTheme = "Custom theme";
      }
    } else {
      final names = state.widgetThemeDisplayNames;
      if (themeIndex >= 0 && themeIndex < names.length) {
        selectedTheme = names[themeIndex];
      }
    }
    state = state.copyWith(
      widgetThemeIndex: themeIndex,
      widgetIsCustomTheme: isCustom,
      selectedTheme: selectedTheme,
    );
  }

  Future<void> loadWidgetTopics() async {
    final prefs = _ref.read(sharedPrefsProvider);
    final topics = await wp.loadWidgetTopics(prefs);
    final hasStored = prefs.getStringList(wp.widgetTopicsKey) != null;
    final premium = _ref.read(premiumProvider);
    var selected = topics.toSet();
    if (!hasStored || selected.isEmpty) {
      selected = {premium ? personalizedFeedTopicId : generalTopicDefinition.id};
    }
    state = state.copyWith(selectedTopicIds: selected);
  }

  Future<void> loadWidgetFrequency() async {
    final prefs = _ref.read(sharedPrefsProvider);
    final freq = await wp.loadWidgetFrequency(prefs);
    state = state.copyWith(selectedFrequencyId: freq);
  }

  Future<void> loadWidgetButtons() async {
    final prefs = _ref.read(sharedPrefsProvider);
    final buttons = await wp.loadWidgetButtons(prefs);
    state = state.copyWith(
      selectedButtonIds: buttons.isEmpty ? {...defaultWidgetButtonSelection} : buttons,
    );
  }

  void applyTopicsResult(List<String>? result) {
    if (result == null) return;
    var selected = result.toSet();
    if (selected.isEmpty) {
      final premium = _ref.read(premiumProvider);
      selected = {premium ? personalizedFeedTopicId : generalTopicDefinition.id};
    }
    state = state.copyWith(selectedTopicIds: selected);
  }

  void applyFrequencyResult(String? result) {
    if (result == null) return;
    state = state.copyWith(selectedFrequencyId: result);
  }

  void applyButtonsResult(Set<String>? result) {
    if (result == null || result.isEmpty) return;
    state = state.copyWith(selectedButtonIds: result);
  }

  String topicsLabel(String lang) {
    final orderedLabels = widgetTopicDefinitions
        .where((def) => state.selectedTopicIds.contains(def.id))
        .map((def) => translate(def.localizationKey, lang))
        .toList();
    if (orderedLabels.isEmpty) {
      final premium = _ref.read(premiumProvider);
      return premium
          ? translate("personalized_feed", lang)
          : translate(generalTopicDefinition.localizationKey, lang);
    }
    return orderedLabels.join(', ');
  }

  String frequencyLabel(String lang) {
    final option = widgetFrequencyOptions.firstWhere(
      (opt) => opt.id == state.selectedFrequencyId,
      orElse: () => everySixHoursFrequency,
    );
    return translate(option.shortLocalizationKey, lang);
  }

  String buttonsLabel(String lang) {
    final hasNone = state.selectedButtonIds.contains(widgetButtonNoneId);
    if (hasNone || state.selectedButtonIds.isEmpty) {
      return translate(widgetButtonNoneOption.localizationKey, lang);
    }
    final labels = <String>[];
    if (state.selectedButtonIds.contains(widgetButtonLikeId)) {
      labels.add(translate(widgetButtonLikeOption.localizationKey, lang));
    }
    if (state.selectedButtonIds.contains(widgetButtonShareId)) {
      labels.add(translate(widgetButtonShareOption.localizationKey, lang));
    }
    if (labels.isEmpty) {
      return translate(widgetButtonNoneOption.localizationKey, lang);
    }
    return labels.join(', ');
  }

  List<String> _computeWidgetThemeDisplayNames() {
    final baseNames = <String>[];
    final counts = <String, int>{};
    for (final theme in allAppThemes) {
      final isImage = theme["isImage"] == true;
      final nbrColor = (theme["nbrcolor"] as int?) ?? 1;
      var rawName = (theme["name"] as String? ?? "").trim();
      String base;
      if (isImage) {
        base = _extractImageBaseName(rawName);
        if (base.isEmpty) {
          final imageName = (theme["imageName"] as String? ?? "").trim();
          base = _extractImageBaseName(imageName);
        }
      } else {
        base = _formatColorThemeName(rawName, nbrColor: nbrColor);
      }
      if (base.isEmpty) base = "Theme";
      base = _normalizeDisplayName(base);
      baseNames.add(base);
      counts[base] = (counts[base] ?? 0) + 1;
    }

    final finalNames = <String>[];
    final seen = <String, int>{};
    for (final base in baseNames) {
      final total = counts[base] ?? 0;
      if (total <= 1) {
        finalNames.add(base);
      } else {
        final occ = (seen[base] ?? 0) + 1;
        seen[base] = occ;
        finalNames.add(occ == 1 ? base : "$base $occ");
      }
    }
    return finalNames;
  }

  String _extractImageBaseName(String raw) {
    if (raw.isEmpty) return "";
    var name = raw;
    final dotIndex = name.indexOf('.');
    if (dotIndex != -1) name = name.substring(0, dotIndex);
    final match = RegExp(r'^\d+_(.+)$').firstMatch(name);
    if (match != null) {
      name = match.group(1) ?? name;
    }
    return name.replaceAll('_', ' ').trim();
  }

  String _formatColorThemeName(String rawName, {required int nbrColor}) {
    if (rawName.isEmpty) return "";
    final words = _splitNameWords(rawName);
    if (words.isEmpty) return "";
    if (nbrColor <= 1) {
      if (words.length == 1) return words[0];
      return "${words[0]} ${words[1]}";
    }
    if (words.length >= 2) {
      final first = words[0];
      final second = words[1];
      if (nbrColor == 2 || words.length == 2) return "$first & $second";
      if (words.length >= 3) {
        final third = words[2];
        return "$first, $second, $third";
      }
      return "$first & $second";
    }
    return words[0];
  }

  List<String> _splitNameWords(String raw) {
    var name = raw.replaceAll('_', ' ').trim();
    if (name.isEmpty) return const [];
    name = name.replaceAllMapped(RegExp(r'(?<!^)([A-Z])'), (m) => ' ${m.group(1)}');
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return parts.map(_capitalize).toList();
  }

  String _normalizeDisplayName(String base) {
    final trimmed = base.trim();
    if (trimmed.isEmpty) return "";
    const maxLen = 20;
    if (trimmed.length <= maxLen) return trimmed;
    return trimmed.substring(0, maxLen).trimRight();
  }

  String _capitalize(String input) {
    if (input.isEmpty) return input;
    if (input.length == 1) return input.toUpperCase();
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }
}

