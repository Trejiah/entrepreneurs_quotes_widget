import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:businessmindset/services/mindset_points_service.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/utils/favorite_management.dart';

final homeActionsCoordinatorProvider = Provider<HomeActionsCoordinator>((ref) {
  return HomeActionsCoordinator();
});

class QuoteNavigationUpdate {
  const QuoteNavigationUpdate({
    required this.direction,
    required this.currentIndex,
    required this.currentQuote,
    required this.currentQuoteData,
    required this.liked,
  });

  final int direction;
  final int currentIndex;
  final String currentQuote;
  final Map<String, dynamic> currentQuoteData;
  final bool liked;
}

class HomeQuoteStatePatch {
  const HomeQuoteStatePatch({
    required this.history,
    required this.historyData,
    required this.currentIndex,
    required this.currentQuote,
    required this.currentQuoteData,
    required this.liked,
    required this.shouldTrackNewQuoteView,
  });

  final List<String> history;
  final List<Map<String, dynamic>> historyData;
  final int currentIndex;
  final String currentQuote;
  final Map<String, dynamic> currentQuoteData;
  final bool liked;
  final bool shouldTrackNewQuoteView;
}

class SettingsReturnUpdate {
  const SettingsReturnUpdate({
    required this.selectedTopics,
    required this.quotePatch,
  });

  final List<String> selectedTopics;
  final HomeQuoteStatePatch? quotePatch;
}

class HomeActionsCoordinator {
  HomeActionsCoordinator();

  QuoteNavigationUpdate? computeNextNavigation({
    required int currentIndex,
    required List<String> history,
    required List<Map<String, dynamic>> historyData,
    required List<DayQuote> favorites,
  }) {
    if (history.isEmpty) return null;
    final next = (currentIndex + 1).clamp(0, history.length - 1);
    return QuoteNavigationUpdate(
      direction: 1,
      currentIndex: next,
      currentQuote: history[next],
      currentQuoteData: historyData[next],
      liked: favorites.any((e) => e.quote == history[next]),
    );
  }

  QuoteNavigationUpdate? computePreviousNavigation({
    required int currentIndex,
    required List<String> history,
    required List<Map<String, dynamic>> historyData,
    required List<DayQuote> favorites,
  }) {
    if (history.isEmpty || currentIndex == 0) return null;
    final prev = (currentIndex - 1).clamp(0, history.length - 1);
    return QuoteNavigationUpdate(
      direction: -1,
      currentIndex: prev,
      currentQuote: history[prev],
      currentQuoteData: historyData[prev],
      liked: favorites.any((e) => e.quote == history[prev]),
    );
  }

  Future<void> onQuoteLiked({
    required String currentQuote,
    required Set<String> quotesThatGaveLikePoint,
  }) async {
    if (!quotesThatGaveLikePoint.contains(currentQuote)) {
      await MindsetPointsService.instance.incrementLike();
      quotesThatGaveLikePoint.add(currentQuote);
    }
    MixpanelService.instance.track('[Quote] Like', {});
  }

  void onQuoteUnliked() {
    MixpanelService.instance.track('[Quote] Unlike', {});
  }

  HomeQuoteStatePatch buildAppendQuotePatch({
    required List<String> history,
    required List<Map<String, dynamic>> historyData,
    required Map<String, dynamic> newQuoteData,
    required bool Function(String quote) isQuoteLiked,
    bool shouldTrackNewQuoteView = true,
  }) {
    final quoteText = (newQuoteData['text'] as String?) ?? '';
    final updatedHistory = List<String>.from(history)..add(quoteText);
    final updatedHistoryData = List<Map<String, dynamic>>.from(historyData)
      ..add(Map<String, dynamic>.from(newQuoteData));
    final nextIndex = updatedHistory.length - 1;
    return HomeQuoteStatePatch(
      history: updatedHistory,
      historyData: updatedHistoryData,
      currentIndex: nextIndex,
      currentQuote: updatedHistory[nextIndex],
      currentQuoteData: updatedHistoryData[nextIndex],
      liked: isQuoteLiked(updatedHistory[nextIndex]),
      shouldTrackNewQuoteView: shouldTrackNewQuoteView,
    );
  }

  Future<SettingsReturnUpdate> processSettingsReturn({
    required List<String> currentSelectedTopics,
    required String personalizedFeedTopicId,
    required List<String> history,
    required List<Map<String, dynamic>> historyData,
    required Future<Map<String, dynamic>> Function() generateQuote,
    required bool Function(String quote) isQuoteLiked,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final testRetaken = prefs.getBool('testRetaken') ?? false;
    if (!testRetaken) {
      return SettingsReturnUpdate(
        selectedTopics: currentSelectedTopics,
        quotePatch: null,
      );
    }

    await prefs.setBool('testRetaken', false);
    final savedTopics = prefs.getStringList('selectedTopics') ?? <String>[];
    if (!savedTopics.contains(personalizedFeedTopicId)) {
      return SettingsReturnUpdate(selectedTopics: savedTopics, quotePatch: null);
    }

    final newQuoteData = await generateQuote();
    final patch = buildAppendQuotePatch(
      history: history,
      historyData: historyData,
      newQuoteData: newQuoteData,
      isQuoteLiked: isQuoteLiked,
      shouldTrackNewQuoteView: true,
    );
    return SettingsReturnUpdate(selectedTopics: savedTopics, quotePatch: patch);
  }
}
