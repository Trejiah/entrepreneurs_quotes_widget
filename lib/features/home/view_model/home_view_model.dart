import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/services/notification_service.dart';

/// État UI de l’écran d’accueil géré par [HomeViewModel] (phase MVVM).
class HomeViewState {
  const HomeViewState({
    this.isReady = false,
    this.showTutorial = true,
    this.tutorialPhase = 0,
    this.showReviewPopup = false,
    this.showDailyLimit = false,
    this.openedWithDailyLimit = false,
    this.pendingNotificationPayload,
  });

  /// Home a fini le chargement initial ([HomePage]._loadPrefs et prérequis).
  final bool isReady;
  final bool showTutorial;
  final int tutorialPhase;
  final bool showReviewPopup;
  final bool showDailyLimit;
  final bool openedWithDailyLimit;
  final NotificationQuotePayload? pendingNotificationPayload;

  HomeViewState copyWith({
    bool? isReady,
    bool? showTutorial,
    int? tutorialPhase,
    bool? showReviewPopup,
    bool? showDailyLimit,
    bool? openedWithDailyLimit,
    NotificationQuotePayload? pendingNotificationPayload,
  }) {
    return HomeViewState(
      isReady: isReady ?? this.isReady,
      showTutorial: showTutorial ?? this.showTutorial,
      tutorialPhase: tutorialPhase ?? this.tutorialPhase,
      showReviewPopup: showReviewPopup ?? this.showReviewPopup,
      showDailyLimit: showDailyLimit ?? this.showDailyLimit,
      openedWithDailyLimit: openedWithDailyLimit ?? this.openedWithDailyLimit,
      pendingNotificationPayload:
          pendingNotificationPayload ?? this.pendingNotificationPayload,
    );
  }
}

class HomeViewModel extends StateNotifier<HomeViewState> {
  HomeViewModel(this._ref) : super(const HomeViewState());

  final Ref _ref;

  static const int dailyQuoteLimit = 10;
  static const String _dailyQuotesDateKey = 'daily_quotes_date';
  static const String _dailyQuotesCountKey = 'daily_quotes_count';

  void hydrateTutorialFromPrefs(SharedPreferences prefs) {
    final show = prefs.getBool('showTutorial') ?? true;
    state = state.copyWith(showTutorial: show, tutorialPhase: 0);
  }

  Future<void> completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showTutorial', false);
    state = state.copyWith(showTutorial: false, tutorialPhase: 0);
  }

  void nextTutorialPhase() {
    if (state.tutorialPhase < 3) {
      state = state.copyWith(tutorialPhase: state.tutorialPhase + 1);
    }
  }

  void setShowReviewPopup(bool value) {
    state = state.copyWith(showReviewPopup: value);
  }

  void markDailyLimitAtLaunch() {
    state = state.copyWith(showDailyLimit: true, openedWithDailyLimit: true);
  }

  void clearDailyLimitFlags() {
    state = state.copyWith(showDailyLimit: false, openedWithDailyLimit: false);
  }

  void setShowDailyLimit(bool value) {
    state = state.copyWith(showDailyLimit: value);
  }

  void setReady(bool value) {
    state = state.copyWith(isReady: value);
  }

  void setPendingNotificationPayload(NotificationQuotePayload? value) {
    state = HomeViewState(
      isReady: state.isReady,
      showTutorial: state.showTutorial,
      tutorialPhase: state.tutorialPhase,
      showReviewPopup: state.showReviewPopup,
      showDailyLimit: state.showDailyLimit,
      openedWithDailyLimit: state.openedWithDailyLimit,
      pendingNotificationPayload: value,
    );
  }

  String _todayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<bool> checkDailyQuoteLimit() async {
    if (_ref.read(premiumProvider)) return false;
    final prefs = await SharedPreferences.getInstance();
    final today = _todayDateString();
    final savedDate = prefs.getString(_dailyQuotesDateKey) ?? '';
    if (savedDate != today) return false;
    final count = prefs.getInt(_dailyQuotesCountKey) ?? 0;
    return count >= dailyQuoteLimit;
  }

  Future<void> incrementDailyQuoteCount() async {
    if (_ref.read(premiumProvider)) return;
    final prefs = await SharedPreferences.getInstance();
    final today = _todayDateString();
    final savedDate = prefs.getString(_dailyQuotesDateKey) ?? '';
    if (savedDate != today) {
      await prefs.setString(_dailyQuotesDateKey, today);
      await prefs.setInt(_dailyQuotesCountKey, 1);
    } else {
      final count = prefs.getInt(_dailyQuotesCountKey) ?? 0;
      await prefs.setInt(_dailyQuotesCountKey, count + 1);
    }
  }
}

final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeViewState>((ref) {
  return HomeViewModel(ref);
});
