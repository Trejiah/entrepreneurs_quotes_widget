import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:businessmindset/features/home/view_model/home_actions_coordinator.dart';
import 'package:businessmindset/features/home/view_model/home_notifications_coordinator.dart';
import 'package:businessmindset/features/home/view_model/home_premium_coordinator.dart';
import 'package:businessmindset/features/home/view_model/home_quote_engine_coordinator.dart';
import 'package:businessmindset/features/home/view_model/home_quotes_coordinator.dart';
import 'package:businessmindset/features/home/view_model/home_resume_coordinator.dart';
import 'package:businessmindset/features/home/view_model/home_selection_coordinator.dart';
import 'package:businessmindset/features/home/view_model/home_topics_coordinator.dart';
import 'package:businessmindset/features/home/view_model/home_quote_ui_state.dart';
import 'package:businessmindset/features/home/view_model/home_view_model.dart';
import 'package:businessmindset/models/topics.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/services/mindset_points_service.dart';
import 'package:businessmindset/services/notification_service.dart';
import 'package:businessmindset/services/review_popup_service.dart';
import 'package:businessmindset/features/home/view_model/home_widget_coordinator.dart';
import 'package:businessmindset/providers/user_provider.dart';

String _replaceNameInQuote(String text, String userName) {
  return text.replaceAll('%NAME%', userName);
}

class HomeQuoteNotifier extends StateNotifier<HomeQuoteUiState> {
  HomeQuoteNotifier(this._ref) : super(const HomeQuoteUiState());

  final Ref _ref;

  final Set<String> _quotesThatGaveLikePoint = {};

  bool _checkingSelectedQuote = false;
  bool _handlingOpenedFromWidget = false;
  bool _suppressNextResumeTopicRegeneration = false;

  String? _debugSelectedTopic;

  bool get isCheckingSelectedQuote => _checkingSelectedQuote;

  bool get suppressNextResumeTopicRegeneration => _suppressNextResumeTopicRegeneration;

  void setSuppressNextResumeTopicRegeneration(bool value) {
    _suppressNextResumeTopicRegeneration = value;
  }

  /// Flux complet « ouverture depuis le widget » (prefs, citation native, file ordonnée, etc.).
  /// La vue ne fait qu’injecter le [MethodChannel] et des hooks Flutter ([isMounted], layout).
  Future<bool> checkIfOpenedFromWidget(
    MethodChannel widgetChannel, {
    bool Function()? isMounted,
    void Function()? onWidgetQuoteApplied,
  }) async {
    if (_handlingOpenedFromWidget) {
      if (kDebugMode) {
        debugPrint(
          '[HomeQuote] checkIfOpenedFromWidget skipped (already in progress)',
        );
      }
      return false;
    }
    _handlingOpenedFromWidget = true;
    try {
      final opened =
          await _ref.read(homeWidgetCoordinatorProvider).handleOpenedFromWidget(
                checkWidgetQuoteOnResume: () => _loadWidgetQuoteFromChannel(
                      widgetChannel,
                      isMounted: isMounted,
                      onQuoteApplied: onWidgetQuoteApplied,
                    ),
                loadAppOrderedQuotes: _loadAppOrderedQuotesWithLogging,
                forceWidgetNewQuoteOnResume: () =>
                    _forceWidgetNewQuoteOnResumeWithLogging(widgetChannel),
                resetOpenedFromLockScreen: () async {
                  await widgetChannel.invokeMethod('resetOpenedFromLockScreen');
                },
                markSuppressNextResumeTopicRegeneration: () {
                  _suppressNextResumeTopicRegeneration = true;
                },
              );
      if (!opened && kDebugMode) {
        debugPrint(
          '[WidgetTap] checkIfOpenedFromWidget: openedFromWidget=false → skip (race: wait for tick listener)',
        );
      }
      return opened;
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("⚠️ [HomeQuote] Error while checking the openedFromWidget flag");
        debugPrint("   Message: $error");
        debugPrint("   Stack: $stack");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
      return false;
    } finally {
      _handlingOpenedFromWidget = false;
    }
  }

  Future<void> _loadWidgetQuoteFromChannel(
    MethodChannel widgetChannel, {
    bool Function()? isMounted,
    void Function()? onQuoteApplied,
  }) async {
    try {
      final widgetCoordinator = _ref.read(homeWidgetCoordinatorProvider);
      final storedQuote =
          await widgetCoordinator.readWidgetStoredQuote(widgetChannel);
      if (kDebugMode) {
        final q = storedQuote?['quote'] as String?;
        debugPrint(
          '[WidgetTap] _loadWidgetQuote: after native read quoteLen=${q?.length ?? 0} '
          '(fallback if snapshot was null)',
        );
      }

      final userName = _ref.read(userNameStateProvider);
      final qs = state;
      final resolution = widgetCoordinator.resolveWidgetQuoteForHomeState(
        storedQuote: storedQuote,
        userName: userName,
        replaceNamePlaceholder: _replaceNameInQuote,
        history: qs.quoteHistory,
        historyData: qs.quoteHistoryData,
      );
      if (resolution == null) {
        if (kDebugMode) {
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          debugPrint("⚠️ [HomeQuote] No usable widget quote available");
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        }
        return;
      }

      if (isMounted != null && !isMounted()) return;

      await applyWidgetQuoteResolution(resolution: resolution);
      onQuoteApplied?.call();

      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("📋 [HomeQuote] Quote loaded from widget");
        debugPrint("   - Citation: ${resolution.quote}");
        debugPrint("   - Signature: ${resolution.metadata['signature'] ?? "N/A"}");
        debugPrint("   - Livre: ${resolution.metadata['bookTitle'] ?? "N/A"}");
        debugPrint("   - URL: ${resolution.metadata['url'] ?? "N/A"}");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("❌ [HomeQuote] Error while fetching the widget quote");
        debugPrint("   Message: $error");
        debugPrint("   Stack: $stack");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
    }
  }

  Future<void> _loadAppOrderedQuotesWithLogging() async {
    try {
      await loadAppOrderedQuotesIntoHistory();
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[HomeQuote] loadAppOrderedQuotes failed: $error');
        debugPrint('Stack: $stack');
      }
    }
  }

  Future<void> _forceWidgetNewQuoteOnResumeWithLogging(
    MethodChannel widgetChannel,
  ) async {
    try {
      await _ref
          .read(homeWidgetCoordinatorProvider)
          .requestForceWidgetNewQuote(widgetChannel);
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("❌ [HomeQuote] Error while requesting a new quote for the widget");
        debugPrint("   Message: $error");
        debugPrint("   Stack: $stack");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
    }
  }

  Future<void> onHomeForegroundResume(
    MethodChannel widgetChannel, {
    required bool Function() isMounted,
    required void Function() onQuoteLayoutRefreshNeeded,
    required Future<void> Function() refreshWidgetData,
    required Future<void> Function() presentHardPaywallIfNeeded,
    bool forceWidgetRefresh = false,
  }) async {
    await checkIfOpenedFromWidget(
      widgetChannel,
      isMounted: isMounted,
      onWidgetQuoteApplied: onQuoteLayoutRefreshNeeded,
    );
    if (!isMounted()) return;
    await consumeSelectedQuoteFromChoosePage(
      isMounted: isMounted,
      onQuoteApplied: onQuoteLayoutRefreshNeeded,
    );
    if (!isMounted()) return;
    await checkSubscriptionStateOnResume(
      isMounted: isMounted,
      onQuoteLayoutRefreshNeeded: onQuoteLayoutRefreshNeeded,
      refreshWidgetData: refreshWidgetData,
      presentHardPaywallIfNeeded: presentHardPaywallIfNeeded,
      forceWidgetRefresh: forceWidgetRefresh,
    );
  }

  Future<void> handleWidgetDeepLinkTick(
    MethodChannel widgetChannel, {
    required bool Function() isMounted,
    required void Function() onQuoteLayoutRefreshNeeded,
    required Future<void> Function() refreshWidgetData,
    required Future<void> Function() presentHardPaywallIfNeeded,
  }) async {
    final openedFromWidget = await checkIfOpenedFromWidget(
      widgetChannel,
      isMounted: isMounted,
      onWidgetQuoteApplied: onQuoteLayoutRefreshNeeded,
    );
    if (!isMounted() || !openedFromWidget) return;
    await checkSubscriptionStateOnResume(
      isMounted: isMounted,
      onQuoteLayoutRefreshNeeded: onQuoteLayoutRefreshNeeded,
      refreshWidgetData: refreshWidgetData,
      presentHardPaywallIfNeeded: presentHardPaywallIfNeeded,
      forceWidgetRefresh: true,
    );
  }

  Future<void> checkSubscriptionStateOnResume({
    required bool Function() isMounted,
    required void Function() onQuoteLayoutRefreshNeeded,
    required Future<void> Function() refreshWidgetData,
    required Future<void> Function() presentHardPaywallIfNeeded,
    bool forceWidgetRefresh = false,
  }) async {
    try {
      if (!isMounted()) return;
      final resumeResult = await _ref.read(homeResumeCoordinatorProvider).syncOnResume(
            forceWidgetRefresh: forceWidgetRefresh,
            validateAndFixSelectedTopics: validateAndFixSelectedTopics,
            validateAndFixWidgetTopics: () =>
                _ref.read(homeWidgetCoordinatorProvider).validateAndFixWidgetTopics(),
          );
      if (!isMounted()) return;

      if (resumeResult.widgetRefreshNeeded) {
        await refreshWidgetData();
      }

      final regenerationDecision = _ref
          .read(homeResumeCoordinatorProvider)
          .decideTopicRegenerationAfterResume(
            isHomeReady: isMounted() && _ref.read(homeViewModelProvider).isReady,
            suppressNextResumeTopicRegeneration: _suppressNextResumeTopicRegeneration,
            topicsChanged: resumeResult.topicsChanged,
          );
      _suppressNextResumeTopicRegeneration = regenerationDecision.nextSuppressFlag;

      if (regenerationDecision.shouldRegenerateQuote) {
        final lang = _ref.read(languageProvider);
        final newQuoteData = await getRandomQuoteFromTopics(lang);
        if (!isMounted()) return;
        await applyResumeTopicRegeneration(newQuoteData);
        onQuoteLayoutRefreshNeeded();
        if (!isMounted()) return;
      }

      if (isMounted() && _ref.read(homeViewModelProvider).isReady) {
        await presentHardPaywallIfNeeded();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HomeQuote] checkSubscriptionStateOnResume failed: $e');
      }
    }
  }

  void setLiked(bool value) {
    state = state.copyWith(liked: value);
  }

  void refreshLikedFromFavorites() {
    final liked = _ref.read(homeQuotesCoordinatorProvider).isQuoteLiked(
          favorites: state.favoritesGlobal,
          currentQuote: state.currentQuote,
        );
    state = state.copyWith(liked: liked);
  }

  void setSelectedTopics(List<String> topics) {
    state = state.copyWith(selectedTopics: List<String>.from(topics));
  }

  Future<void> validateAndFixSelectedTopics() async {
    final topics = await _ref.read(homeTopicsCoordinatorProvider).validateAndFixSelectedTopics();
    state = state.copyWith(selectedTopics: topics);
  }

  Future<void> loadStoredQuotes({bool updatePersistedHistory = true}) async {
    final loaded = await _ref.read(homeQuotesCoordinatorProvider).loadStoredQuotes();
    final liked = _ref.read(homeQuotesCoordinatorProvider).isQuoteLiked(
          favorites: loaded.favorites,
          currentQuote: state.currentQuote,
        );
    state = state.copyWith(
      favoritesGlobal: loaded.favorites,
      persistedHistoryGlobal: loaded.history,
      liked: liked,
    );
    if (updatePersistedHistory) {
      await appendCurrentToPersistedHistory();
    }
  }

  Future<void> appendCurrentToPersistedHistory() async {
    final lang = _ref.read(languageProvider);
    final metadata = _ref.read(homeQuotesCoordinatorProvider).resolveCurrentQuoteMetadata(
          currentQuote: state.currentQuote,
          currentQuoteData: state.currentQuoteData,
          lang: lang,
        );
    final updated = await _ref.read(homeQuotesCoordinatorProvider).appendToHistoryAndSave(
          history: state.persistedHistoryGlobal,
          currentQuote: state.currentQuote,
          metadata: metadata,
          lang: lang,
        );
    state = state.copyWith(persistedHistoryGlobal: updated);
  }

  Future<void> appendCurrentToFavoritesAndSave() async {
    final lang = _ref.read(languageProvider);
    final metadata = _ref.read(homeQuotesCoordinatorProvider).resolveCurrentQuoteMetadata(
          currentQuote: state.currentQuote,
          currentQuoteData: state.currentQuoteData,
          lang: lang,
        );
    final updated = await _ref.read(homeQuotesCoordinatorProvider).appendToFavoritesAndSave(
          favorites: state.favoritesGlobal,
          currentQuote: state.currentQuote,
          metadata: metadata,
          lang: lang,
        );
    state = state.copyWith(favoritesGlobal: updated);
  }

  Future<bool> removeCurrentFromFavoritesAndSave({bool removeAllMatches = false}) async {
    final result = await _ref.read(homeQuotesCoordinatorProvider).removeFromFavoritesAndSave(
          favorites: state.favoritesGlobal,
          currentQuote: state.currentQuote,
          removeAllMatches: removeAllMatches,
        );
    state = state.copyWith(favoritesGlobal: result.favorites);
    return result.removed;
  }

  Future<Map<String, dynamic>> getRandomQuoteFromTopics(String lang) {
    return _ref.read(homeQuoteEngineCoordinatorProvider).getRandomQuoteFromTopics(
          lang: lang,
          selectedTopics: state.selectedTopics,
          quotesGlobal: state.favoritesGlobal,
        );
  }

  Future<void> appendUniqueQuote(String lang) async {
    final history = List<String>.from(state.quoteHistory);
    final historyData =
        state.quoteHistoryData.map((e) => Map<String, dynamic>.from(e)).toList();
    await _ref.read(homeQuoteEngineCoordinatorProvider).appendUniqueQuoteToHistory(
          lang: lang,
          selectedTopics: state.selectedTopics,
          quotesGlobal: state.favoritesGlobal,
          history: history,
          historyData: historyData,
        );
    state = state.copyWith(quoteHistory: history, quoteHistoryData: historyData);
  }

  void applyHomeQuoteStatePatch(HomeQuoteStatePatch patch) {
    state = state.copyWith(
      quoteHistory: List<String>.from(patch.history),
      quoteHistoryData:
          patch.historyData.map((e) => Map<String, dynamic>.from(e)).toList(),
      historyIndex: patch.currentIndex,
      currentQuote: patch.currentQuote,
      currentQuoteData: Map<String, dynamic>.from(patch.currentQuoteData),
      liked: patch.liked,
    );
  }

  void applyNavigationUpdate(QuoteNavigationUpdate update) {
    state = state.copyWith(
      swipeDirection: update.direction,
      historyIndex: update.currentIndex,
      currentQuote: update.currentQuote,
      currentQuoteData: Map<String, dynamic>.from(update.currentQuoteData),
      liked: update.liked,
    );
  }

  /// Premier chargement : citation tirée au sort si pas de limite atteinte.
  void seedFirstQuoteOfSession(Map<String, dynamic> firstData) {
    final text = firstData['text'] as String? ?? '';
    state = state.copyWith(
      quoteHistory: [text],
      quoteHistoryData: [Map<String, dynamic>.from(firstData)],
      historyIndex: 0,
      currentQuote: text,
      currentQuoteData: Map<String, dynamic>.from(firstData),
    );
  }

  void clearSessionQuotesForDailyLimit() {
    state = state.copyWith(
      quoteHistory: [],
      quoteHistoryData: [],
      historyIndex: 0,
      currentQuote: '',
      clearCurrentQuoteData: true,
      liked: false,
    );
  }

  Future<void> applyResumeTopicRegeneration(Map<String, dynamic> newQuoteData) async {
    final patch = _ref.read(homeActionsCoordinatorProvider).buildAppendQuotePatch(
          history: List<String>.from(state.quoteHistory),
          historyData:
              state.quoteHistoryData.map((e) => Map<String, dynamic>.from(e)).toList(),
          newQuoteData: newQuoteData,
          isQuoteLiked: (quote) => state.favoritesGlobal.any((e) => e.quote == quote),
        );
    applyHomeQuoteStatePatch(patch);
    await appendCurrentToPersistedHistory();
    if (patch.shouldTrackNewQuoteView) {
      await trackNewQuoteViewed();
    }
  }

  Future<void> applySubscriptionExpiredRegeneration(Map<String, dynamic> newQuoteData) async {
    final patch = _ref.read(homeActionsCoordinatorProvider).buildAppendQuotePatch(
          history: List<String>.from(state.quoteHistory),
          historyData:
              state.quoteHistoryData.map((e) => Map<String, dynamic>.from(e)).toList(),
          newQuoteData: newQuoteData,
          isQuoteLiked: (quote) => state.favoritesGlobal.any((e) => e.quote == quote),
        );
    applyHomeQuoteStatePatch(patch);
    await appendCurrentToPersistedHistory();
  }

  Future<void> loadAppOrderedQuotesIntoHistory() async {
    final history = List<String>.from(state.quoteHistory);
    final historyData =
        state.quoteHistoryData.map((e) => Map<String, dynamic>.from(e)).toList();
    await _ref.read(homeSelectionCoordinatorProvider).applyAppOrderedQuotes(
          history: history,
          historyData: historyData,
          lang: _ref.read(languageProvider),
        );
    state = state.copyWith(quoteHistory: history, quoteHistoryData: historyData);
  }

  Future<void> applyWidgetQuoteResolution({
    required WidgetQuoteResolution resolution,
  }) async {
    state = state.copyWith(
      currentQuote: resolution.quote,
      currentQuoteData: Map<String, dynamic>.from(resolution.metadata),
      quoteHistory: List<String>.from(resolution.updatedHistory),
      quoteHistoryData:
          resolution.updatedHistoryData.map((e) => Map<String, dynamic>.from(e)).toList(),
      historyIndex: resolution.currentIndex,
      liked: state.favoritesGlobal.any((e) => e.quote == resolution.quote),
    );
    _ref.read(homeViewModelProvider.notifier).setReady(true);
    await appendCurrentToPersistedHistory();
    if (resolution.isNewQuote) {
      await trackNewQuoteViewed();
    }
  }

  Future<void> applyNotificationQuotePayload(NotificationQuotePayload payload) async {
    final metadata = <String, dynamic>{
      'category': payload.category,
      'text': payload.quote,
      'signature': payload.signature,
      'bookTitle': payload.bookTitle,
      'url': payload.url,
    };

    final existingIndex = state.quoteHistory.indexOf(payload.quote);
    final isNewQuote = existingIndex == -1;

    final history = List<String>.from(state.quoteHistory);
    final historyData =
        state.quoteHistoryData.map((e) => Map<String, dynamic>.from(e)).toList();

    if (isNewQuote) {
      history.add(payload.quote);
      historyData.add(metadata);
      state = state.copyWith(
        currentQuote: payload.quote,
        currentQuoteData: metadata,
        quoteHistory: history,
        quoteHistoryData: historyData,
        historyIndex: history.length - 1,
        liked: state.favoritesGlobal.any((e) => e.quote == payload.quote),
      );
    } else {
      historyData[existingIndex] = metadata;
      state = state.copyWith(
        currentQuote: payload.quote,
        currentQuoteData: metadata,
        quoteHistory: history,
        quoteHistoryData: historyData,
        historyIndex: existingIndex,
        liked: state.favoritesGlobal.any((e) => e.quote == payload.quote),
      );
    }

    _ref.read(homeViewModelProvider.notifier).setReady(true);
    await appendCurrentToPersistedHistory();
    await loadAppOrderedQuotesIntoHistory();
    if (isNewQuote) {
      await trackNewQuoteViewed();
    }
  }

  Future<void> processChoosePageSelectionResult(SelectedQuoteResult result) async {
    final history = List<String>.from(state.quoteHistory);
    final historyData =
        state.quoteHistoryData.map((e) => Map<String, dynamic>.from(e)).toList();

    if (result.isNewQuote) {
      history.add(result.quoteText);
      historyData.add(Map<String, dynamic>.from(result.metadata));
      state = state.copyWith(
        currentQuote: result.quoteText,
        currentQuoteData: Map<String, dynamic>.from(result.metadata),
        quoteHistory: history,
        quoteHistoryData: historyData,
        historyIndex: history.length - 1,
        liked: state.favoritesGlobal.any((e) => e.quote == result.quoteText),
      );
    } else {
      historyData[result.existingIndex] = Map<String, dynamic>.from(result.metadata);
      state = state.copyWith(
        currentQuote: result.quoteText,
        currentQuoteData: Map<String, dynamic>.from(result.metadata),
        quoteHistory: history,
        quoteHistoryData: historyData,
        historyIndex: result.existingIndex,
        liked: state.favoritesGlobal.any((e) => e.quote == result.quoteText),
      );
    }

    _ref.read(homeViewModelProvider.notifier).setReady(true);
    await appendCurrentToPersistedHistory();
    if (result.isNewQuote) {
      await trackNewQuoteViewed();
    }
  }

  Future<void> processSettingsReturnFlow() async {
    final lang = _ref.read(languageProvider);
    final result = await _ref.read(homeActionsCoordinatorProvider).processSettingsReturn(
          currentSelectedTopics: state.selectedTopics,
          personalizedFeedTopicId: personalizedFeedTopicId,
          history: List<String>.from(state.quoteHistory),
          historyData:
              state.quoteHistoryData.map((e) => Map<String, dynamic>.from(e)).toList(),
          generateQuote: () => getRandomQuoteFromTopics(lang),
          isQuoteLiked: (quote) => state.favoritesGlobal.any((e) => e.quote == quote),
        );

    final patch = result.quotePatch;
    state = state.copyWith(selectedTopics: result.selectedTopics);

    if (patch != null) {
      applyHomeQuoteStatePatch(patch);
      await appendCurrentToPersistedHistory();
      if (patch.shouldTrackNewQuoteView) {
        await trackNewQuoteViewed();
      }
    }
  }

  Future<void> onBecamePremium() async {
    _ref.read(homeViewModelProvider.notifier).clearDailyLimitFlags();
    final lang = _ref.read(languageProvider);
    final patch = await _ref.read(homePremiumCoordinatorProvider).buildBecamePremiumQuotePatch(
          isHistoryEmpty: state.quoteHistory.isEmpty,
          generateQuote: () => getRandomQuoteFromTopics(lang),
          buildPatch: (newQuoteData) =>
              _ref.read(homeActionsCoordinatorProvider).buildAppendQuotePatch(
                    history: const <String>[],
                    historyData: const <Map<String, dynamic>>[],
                    newQuoteData: newQuoteData,
                    isQuoteLiked: (quote) => state.favoritesGlobal.any((e) => e.quote == quote),
                  ),
        );
    if (patch == null) return;
    applyHomeQuoteStatePatch(patch);
    if (patch.shouldTrackNewQuoteView) {
      await trackNewQuoteViewed();
    }
  }

  Future<void> goNext() async {
    final lang = _ref.read(languageProvider);

    if (state.quoteHistory.isEmpty) {
      if (!_ref.read(premiumProvider)) {
        _ref.read(homeViewModelProvider.notifier).setShowDailyLimit(true);
      }
      return;
    }

    final debugTopic = _debugSelectedTopic;
    if (debugTopic != null && debugTopic != 'normal') {
      final update = _ref.read(homeActionsCoordinatorProvider).computeNextNavigation(
            currentIndex: state.historyIndex,
            history: state.quoteHistory,
            historyData: state.quoteHistoryData,
            favorites: state.favoritesGlobal,
          );
      if (update == null) return;
      final atEnd = state.historyIndex == state.quoteHistory.length - 1;
      if (atEnd) {
        state = state.copyWith(swipeDirection: update.direction);
        return;
      }
      applyNavigationUpdate(update);
      return;
    }

    final atEnd = state.historyIndex == state.quoteHistory.length - 1;
    final previousHistoryLength = state.quoteHistory.length;

    if (atEnd) {
      if (!_ref.read(premiumProvider)) {
        final limitReached =
            await _ref.read(homeViewModelProvider.notifier).checkDailyQuoteLimit();
        if (limitReached) {
          _ref.read(homeViewModelProvider.notifier).setShowDailyLimit(true);
          return;
        }
        await _ref.read(homeViewModelProvider.notifier).incrementDailyQuoteCount();
      }

      final indexBeforeAppend = state.historyIndex;
      await appendUniqueQuote(lang);

      if (state.quoteHistory.length > previousHistoryLength) {
        final update = _ref.read(homeActionsCoordinatorProvider).computeNextNavigation(
              currentIndex: indexBeforeAppend,
              history: state.quoteHistory,
              historyData: state.quoteHistoryData,
              favorites: state.favoritesGlobal,
            );
        if (update == null) return;
        applyNavigationUpdate(update);
        unawaited(appendCurrentToPersistedHistory());
        unawaited(_trackNewQuoteViewedAndMaybeReviewPopup());
      }
    } else {
      final update = _ref.read(homeActionsCoordinatorProvider).computeNextNavigation(
            currentIndex: state.historyIndex,
            history: state.quoteHistory,
            historyData: state.quoteHistoryData,
            favorites: state.favoritesGlobal,
          );
      if (update == null) return;
      applyNavigationUpdate(update);
      unawaited(appendCurrentToPersistedHistory());
    }
  }

  void goPrev() {
    final update = _ref.read(homeActionsCoordinatorProvider).computePreviousNavigation(
          currentIndex: state.historyIndex,
          history: state.quoteHistory,
          historyData: state.quoteHistoryData,
          favorites: state.favoritesGlobal,
        );
    if (update == null) return;

    final debugTopic = _debugSelectedTopic;
    applyNavigationUpdate(update);
    final shouldPersistHistory = debugTopic == null || debugTopic == 'normal';
    if (shouldPersistHistory) {
      unawaited(appendCurrentToPersistedHistory());
    }
  }

  Future<void> onQuoteLikedFromUser() async {
    await appendCurrentToFavoritesAndSave();
    await _ref.read(homeActionsCoordinatorProvider).onQuoteLiked(
          currentQuote: state.currentQuote,
          quotesThatGaveLikePoint: _quotesThatGaveLikePoint,
        );
  }

  Future<void> onQuoteUnlikedFromUser() async {
    await removeCurrentFromFavoritesAndSave();
    _ref.read(homeActionsCoordinatorProvider).onQuoteUnliked();
  }

  Future<void> trackNewQuoteViewed() async {
    await MindsetPointsService.instance.incrementQuote();
  }

  Future<void> _trackNewQuoteViewedAndMaybeReviewPopup() async {
    await trackNewQuoteViewed();
    await ReviewPopupService.instance.trackAction();
    await _ref
        .read(homeNotificationsCoordinatorProvider)
        .maybePresentReviewPopupAfterUserAction();
  }

  Future<void> consumeSelectedQuoteFromChoosePage({
    bool Function()? isMounted,
    void Function()? onQuoteApplied,
  }) async {
    if (_checkingSelectedQuote) return;
    _checkingSelectedQuote = true;
    try {
      final result =
          await _ref.read(homeSelectionCoordinatorProvider).consumeSelectedQuoteFromChoosePage(
                history: List<String>.from(state.quoteHistory),
              );

      if (result == null) return;

      if (isMounted != null && !isMounted()) return;
      await processChoosePageSelectionResult(result);
      onQuoteApplied?.call();
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[HomeQuote] consumeSelectedQuoteFromChoosePage failed: $error');
        debugPrint('$stack');
      }
    } finally {
      _checkingSelectedQuote = false;
    }
  }
}
