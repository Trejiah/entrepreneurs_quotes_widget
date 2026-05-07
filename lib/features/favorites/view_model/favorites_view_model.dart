import 'package:businessmindset/features/favorites/model/favorites_models.dart';
import 'package:businessmindset/features/favorites/view_model/favorites_ui_state.dart';
import 'package:businessmindset/models/topics.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesNotifier extends StateNotifier<FavoritesUiState> {
  FavoritesNotifier()
      : super(
          FavoritesUiState(topics: buildFavoriteTopicsList()),
        );

  static const String _selectedTopicsKey = 'selectedTopics';

  Future<void> loadSelectedTopics({required bool premium}) async {
    final prefs = await SharedPreferences.getInstance();
    final savedTopics = prefs.getStringList(_selectedTopicsKey) ?? [];

    List<String> selected = List<String>.from(savedTopics);

    if (selected.isEmpty) {
      selected = [
        premium ? personalizedFeedTopicId : 'general',
      ];
      await _saveSelectedTopics(selected);
    }

    if (!premium) {
      final hasLockedTopics = selected.any(
        (topicId) => !kFreeFavoriteTopicIds.contains(topicId),
      );
      if (hasLockedTopics) {
        selected = ['general'];
        await _saveSelectedTopics(selected);
      }
    }

    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📋 [FavoritesPage] Loading selected topics');
      debugPrint('   - premium: $premium');
      debugPrint('   - topics: $selected');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    state = state.copyWith(
      selectedTopics: selected,
      isLoaded: true,
    );
  }

  Future<void> toggleTopic(String topicId) async {
    final selected = List<String>.from(state.selectedTopics);
    if (selected.contains(topicId)) {
      selected.remove(topicId);
    } else {
      selected.add(topicId);
    }
    state = state.copyWith(
      selectedTopics: selected,
      favoritesModified: true,
    );
  }

  bool isTopicSelected(String topicId) => state.selectedTopics.contains(topicId);

  bool isTopicLocked(String topicId, {required bool premium}) {
    if (premium) return false;
    return !kFreeFavoriteTopicIds.contains(topicId);
  }

  Future<bool> persistSelectionAndReschedule({
    required bool premium,
    required HabitsState habits,
    required String languageCode,
  }) async {
    List<String> selected = List<String>.from(state.selectedTopics);
    if (selected.isEmpty) {
      selected = [premium ? personalizedFeedTopicId : 'general'];
    }

    await _saveSelectedTopics(selected);

    if (premium) {
      MixpanelService.instance.track('[Topics] Selected', {
        'topics': selected,
        'topics_string': selected.join(','),
        'topics_count': selected.length,
      });
    }

    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📋 [FavoritesPage] Confirmation - Topics saved');
      debugPrint('   - topics: $selected');
      debugPrint('   - nombre de topics: ${selected.length}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await NotificationService.instance.scheduleFromHabits(
        prefs: prefs,
        habits: habits,
        languageCode: languageCode,
        triggeredAutomatically: false,
      );
      if (kDebugMode) {
        debugPrint(
          '📋 [FavoritesPage] Notifications rescheduled with new topics',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ [FavoritesPage] Error while rescheduling notifications: $e',
        );
      }
    }

    state = state.copyWith(selectedTopics: selected);
    return state.favoritesModified;
  }

  Future<void> _saveSelectedTopics(List<String> topics) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedTopicsKey, topics);
    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📋 [FavoritesPage] Saving selected topics');
      debugPrint('   - topics: $topics');
      debugPrint('   - nombre de topics: ${topics.length}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }
}
