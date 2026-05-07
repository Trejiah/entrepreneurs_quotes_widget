import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:businessmindset/services/revenuecat_service.dart';
import 'package:businessmindset/features/home/view_model/home_premium_coordinator.dart';

final homeResumeCoordinatorProvider = Provider<HomeResumeCoordinator>((ref) {
  return HomeResumeCoordinator(ref);
});

class ResumeSyncResult {
  const ResumeSyncResult({
    required this.widgetRefreshNeeded,
    required this.topicsChanged,
  });

  final bool widgetRefreshNeeded;
  final bool topicsChanged;
}

class ResumeTopicRegenerationDecision {
  const ResumeTopicRegenerationDecision({
    required this.shouldRegenerateQuote,
    required this.nextSuppressFlag,
  });

  final bool shouldRegenerateQuote;
  final bool nextSuppressFlag;
}

class HomeResumeCoordinator {
  HomeResumeCoordinator(this._ref);

  final Ref _ref;

  Future<ResumeSyncResult> syncOnResume({
    required bool forceWidgetRefresh,
    required Future<void> Function() validateAndFixSelectedTopics,
    required Future<bool> Function() validateAndFixWidgetTopics,
  }) async {
    final info = await RevenueCatService.instance.getCustomerInfo(forceRefresh: true);
    final prefs = await SharedPreferences.getInstance();

    final syncResult =
        await _ref.read(homePremiumCoordinatorProvider).applyPremiumStateFromCustomerInfo(info);

    final topicsBeforeValidation = prefs.getStringList('selectedTopics') ?? [];
    await validateAndFixSelectedTopics();
    final topicsAfterValidation = prefs.getStringList('selectedTopics') ?? [];

    final widgetTopicsChanged = await validateAndFixWidgetTopics();
    final topicsChanged = _topicsChanged(topicsBeforeValidation, topicsAfterValidation);
    final widgetRefreshNeeded = widgetTopicsChanged ||
        syncResult.subscriptionWidgetSyncNeeded ||
        forceWidgetRefresh;

    return ResumeSyncResult(
      widgetRefreshNeeded: widgetRefreshNeeded,
      topicsChanged: topicsChanged,
    );
  }

  bool _topicsChanged(List<String> before, List<String> after) {
    final beforeSet = before.toSet();
    final afterSet = after.toSet();
    return beforeSet.length != afterSet.length || !beforeSet.containsAll(afterSet);
  }

  ResumeTopicRegenerationDecision decideTopicRegenerationAfterResume({
    required bool isHomeReady,
    required bool suppressNextResumeTopicRegeneration,
    required bool topicsChanged,
  }) {
    if (!isHomeReady) {
      return const ResumeTopicRegenerationDecision(
        shouldRegenerateQuote: false,
        nextSuppressFlag: false,
      );
    }
    if (suppressNextResumeTopicRegeneration) {
      return const ResumeTopicRegenerationDecision(
        shouldRegenerateQuote: false,
        nextSuppressFlag: false,
      );
    }
    return ResumeTopicRegenerationDecision(
      shouldRegenerateQuote: topicsChanged,
      nextSuppressFlag: false,
    );
  }
}
