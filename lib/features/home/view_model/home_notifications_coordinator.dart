import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:businessmindset/features/home/view_model/home_view_model.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/services/mindset_points_service.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/services/notification_service.dart';
import 'package:businessmindset/services/review_popup_service.dart';

/// Tranche D : notifications planifiées, tap depuis une notification, popup d’avis, init points.
final homeNotificationsCoordinatorProvider =
    Provider<HomeNotificationsCoordinator>((ref) {
  return HomeNotificationsCoordinator(ref);
});

class HomeNotificationsCoordinator {
  HomeNotificationsCoordinator(this._ref);

  final Ref _ref;

  Future<void> initializePointsDayWeekResets() {
    return MindsetPointsService.instance.initializeDayWeekResets();
  }

  void markAppOpenedForReviewPrompt() {
    ReviewPopupService.instance.markAppOpened();
  }

  Future<void> rescheduleNotificationsFromHabits() async {
    final prefs = _ref.read(sharedPrefsProvider);
    final habits = _ref.read(habitsStateProvider);
    final lang = _ref.read(languageProvider);
    await NotificationService.instance.scheduleFromHabits(
      prefs: prefs,
      habits: habits,
      languageCode: lang,
      triggeredAutomatically: true,
    );
  }

  Future<void> maybePresentReviewPopupAfterUserAction() async {
    if (_ref.read(homeViewModelProvider).showReviewPopup) return;
    final shouldShow = await ReviewPopupService.instance.shouldShowPopup(
      isOnHomepage: true,
    );
    if (!shouldShow) return;
    await ReviewPopupService.instance.onPopupShown();
    MixpanelService.instance.track('[Review] Popup affiché');
    _ref.read(homeViewModelProvider.notifier).setShowReviewPopup(true);
  }

  Future<void> onReviewPopupDismissedByUser() async {
    await ReviewPopupService.instance.onPopupRefused();
    _ref.read(homeViewModelProvider.notifier).setShowReviewPopup(false);
  }

  Future<void> onReviewPopupAcceptedByUser() async {
    await ReviewPopupService.instance.onPopupAccepted();
    _ref.read(homeViewModelProvider.notifier).setShowReviewPopup(false);
  }
}
