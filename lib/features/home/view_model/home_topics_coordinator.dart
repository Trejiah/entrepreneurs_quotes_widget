import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:businessmindset/models/topics.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/core/app_localizations.dart';

final homeTopicsCoordinatorProvider = Provider<HomeTopicsCoordinator>((ref) {
  return HomeTopicsCoordinator(ref);
});

class HomeTopicsCoordinator {
  HomeTopicsCoordinator(this._ref);

  final Ref _ref;

  Future<List<String>> validateAndFixSelectedTopics() async {
    final premium = _ref.read(premiumProvider);
    final prefs = await SharedPreferences.getInstance();
    const freeTopics = {'favoritesquotes', 'general', 'resilience', 'vispurp'};

    final savedTopics = prefs.getStringList('selectedTopics') ?? [];
    if (savedTopics.isEmpty) {
      final defaults = premium ? <String>[personalizedFeedTopicId] : <String>['general'];
      await prefs.setStringList('selectedTopics', defaults);
      return defaults;
    }

    if (!premium) {
      final hasLockedTopics = savedTopics.any((topicId) => !freeTopics.contains(topicId));
      if (hasLockedTopics) {
        const corrected = <String>['general'];
        await prefs.setStringList('selectedTopics', corrected);
        return corrected;
      }
    }
    return savedTopics;
  }

  String topicsButtonText({
    required String lang,
    required List<String> selectedTopics,
  }) {
    if (selectedTopics.isEmpty) return translate('selectedTopics', lang);
    if (selectedTopics.length == 1) {
      final topicId = selectedTopics.first;
      if (topicId == personalizedFeedTopicId) return translate('personalized_feed', lang);
      if (topicId == 'general') return translate('General', lang);
      if (topicId == 'favoritesquotes') return translate('Favoritesquotes', lang);
      return translate(topicId, lang);
    }
    return translate('selectedTopics', lang);
  }
}
