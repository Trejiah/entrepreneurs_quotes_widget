import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:businessmindset/app/deep_link_channel.dart';
import 'package:businessmindset/models/topics.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/providers/widget_preferences.dart';
import 'package:businessmindset/services/widget_subscription_sync.dart';

final homeWidgetCoordinatorProvider = Provider<HomeWidgetCoordinator>((ref) {
  return HomeWidgetCoordinator(ref);
});

class WidgetQuoteResolution {
  const WidgetQuoteResolution({
    required this.quote,
    required this.metadata,
    required this.updatedHistory,
    required this.updatedHistoryData,
    required this.currentIndex,
    required this.isNewQuote,
  });

  final String quote;
  final Map<String, dynamic> metadata;
  final List<String> updatedHistory;
  final List<Map<String, dynamic>> updatedHistoryData;
  final int currentIndex;
  final bool isNewQuote;
}

class HomeWidgetCoordinator {
  HomeWidgetCoordinator(this._ref);

  final Ref _ref;

  Future<bool> validateAndFixWidgetTopics() async {
    final premium = _ref.read(premiumProvider);
    final prefs = await SharedPreferences.getInstance();
    const freeTopics = {'favoritesquotes', 'general', 'resilience', 'vispurp'};

    final savedWidgetTopics = await loadWidgetTopics(prefs);
    if (savedWidgetTopics.isEmpty) {
      final defaultTopics = premium ? [personalizedFeedTopicId] : [generalTopicDefinition.id];
      await saveWidgetTopics(prefs, defaultTopics);
      return true;
    }

    if (!premium) {
      final hasLockedTopics = savedWidgetTopics.any((topicId) => !freeTopics.contains(topicId));
      if (hasLockedTopics) {
        await saveWidgetTopics(prefs, [generalTopicDefinition.id]);
        return true;
      }
    }
    return false;
  }

  Future<void> refreshWidgetData(MethodChannel widgetChannel) async {
    final prefs = await SharedPreferences.getInstance();
    final freshThemeIndex = prefs.getInt('widgetThemeIndex') ?? 0;
    final topics = await loadWidgetTopics(prefs);
    final favorites = await loadWidgetFavorites(prefs);
    final frequency = await loadWidgetFrequency(prefs);
    final buttons = await loadWidgetButtons(prefs);

    final payload = <String, dynamic>{
      'themeIndex': freshThemeIndex,
      'topics': topics,
      'favorites': favorites.map((e) => e.toJson()).toList(growable: false),
      'frequency': frequency,
      'buttons': buttons.toList(growable: false),
      'isPremium': _ref.read(premiumProvider),
      'premiumExpirationEpochMs': await fetchWidgetPremiumExpirationEpochMs(),
      'language': _ref.read(languageProvider),
      'planGrowthPercentage': prefs.getDouble('plan_growth_percentage') ?? 0.0,
      'planDisciplinePercentage': prefs.getDouble('plan_discipline_percentage') ?? 0.0,
      'planConfidencePercentage': prefs.getDouble('plan_confidence_percentage') ?? 0.0,
      'planStrategyPercentage': prefs.getDouble('plan_strategy_percentage') ?? 0.0,
      'gender': prefs.getString('gender'),
      'affirmationPercentage': prefs.getInt('tone_value_AFFIRMATION') ?? 0,
      'noMercyPercentage': prefs.getInt('tone_value_NO MERCY') ?? 0,
    };
    if (prefs.getBool('widgetConfigured') ?? false) {
      payload['configured'] = true;
    }

    await widgetChannel.invokeMethod('updateWidgetData', payload);
    await widgetChannel.invokeMethod('reloadWidgets');
  }

  Future<bool> consumePendingWidgetShareFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingShare = prefs.getBool('pendingWidgetShare') ?? false;
    if (!pendingShare) return false;
    await prefs.setBool('pendingWidgetShare', false);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return true;
  }

  Future<bool> handleOpenedFromWidget({
    required Future<void> Function() checkWidgetQuoteOnResume,
    required Future<void> Function() loadAppOrderedQuotes,
    required Future<void> Function() forceWidgetNewQuoteOnResume,
    required Future<void> Function() resetOpenedFromLockScreen,
    required void Function() markSuppressNextResumeTopicRegeneration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final openedFromWidget = prefs.getBool('openedFromWidget') ?? false;
    if (!openedFromWidget) return false;

    await prefs.setBool('openedFromWidget', false);
    await checkWidgetQuoteOnResume();
    await loadAppOrderedQuotes();
    if (!Platform.isAndroid) {
      await forceWidgetNewQuoteOnResume();
    }
    await resetOpenedFromLockScreen();
    markSuppressNextResumeTopicRegeneration();
    return true;
  }

  Future<Map<dynamic, dynamic>?> readWidgetStoredQuote(MethodChannel widgetChannel) async {
    Map<dynamic, dynamic>? storedQuote;
    if (Platform.isAndroid) {
      storedQuote = await consumeAndroidWidgetOpenSnapshot();
    }
    storedQuote ??=
        await widgetChannel.invokeMethod<Map<dynamic, dynamic>>('getWidgetStoredQuote');
    return storedQuote;
  }

  Future<void> requestForceWidgetNewQuote(MethodChannel widgetChannel) async {
    await widgetChannel.invokeMethod('forceWidgetNewQuote');
  }

  WidgetQuoteResolution? resolveWidgetQuoteForHomeState({
    required Map<dynamic, dynamic>? storedQuote,
    required String userName,
    required String Function(String text, String userName) replaceNamePlaceholder,
    required List<String> history,
    required List<Map<String, dynamic>> historyData,
  }) {
    if (storedQuote == null) return null;

    final quoteRaw = storedQuote['quote'] as String?;
    if (quoteRaw == null || quoteRaw.isEmpty) return null;

    final quote = userName.isEmpty ? quoteRaw : replaceNamePlaceholder(quoteRaw, userName);
    final metadata = <String, dynamic>{
      'category': storedQuote['category'] as String?,
      'text': quote,
      'signature': storedQuote['signature'] as String?,
      'bookTitle': storedQuote['book'] as String?,
      'url': storedQuote['url'] as String?,
    };

    final updatedHistory = List<String>.from(history);
    final updatedHistoryData = List<Map<String, dynamic>>.from(historyData);
    final existingIndex = updatedHistory.indexOf(quote);
    final isNewQuote = existingIndex == -1;

    late final int currentIndex;
    if (isNewQuote) {
      updatedHistory.add(quote);
      updatedHistoryData.add(metadata);
      currentIndex = updatedHistory.length - 1;
    } else {
      currentIndex = existingIndex;
      updatedHistoryData[existingIndex] = metadata;
    }

    return WidgetQuoteResolution(
      quote: quote,
      metadata: metadata,
      updatedHistory: updatedHistory,
      updatedHistoryData: updatedHistoryData,
      currentIndex: currentIndex,
      isNewQuote: isNewQuote,
    );
  }
}
