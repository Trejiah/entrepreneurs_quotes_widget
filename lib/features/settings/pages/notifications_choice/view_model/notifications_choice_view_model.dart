import 'package:businessmindset/features/settings/pages/notifications_choice/model/notifications_choice_models.dart';
import 'package:businessmindset/features/settings/pages/notifications_choice/view_model/notifications_choice_ui_state.dart';
import 'package:businessmindset/models/quotes_model.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsChoiceViewModel
    extends StateNotifier<NotificationsChoiceUiState> {
  NotificationsChoiceViewModel(this._ref)
      : super(const NotificationsChoiceUiState());

  final Ref _ref;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final selected =
        prefs.getStringList('notificationsPriorityQuotes') ?? const <String>[];
    final allQuotes = _buildAllQuotes(_ref.read(languageProvider));
    state = state.copyWith(
      selectedQuotes: List<String>.from(selected),
      allQuotes: allQuotes,
    );
  }

  void onSearchChanged(String value) {
    state = state.copyWith(searchText: value);
  }

  void toggleQuote(String text) {
    final next = List<String>.from(state.selectedQuotes);
    if (next.contains(text)) {
      next.remove(text);
    } else {
      next.add(text);
    }
    state = state.copyWith(selectedQuotes: next);
  }

  Future<void> saveChoices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('notificationsPriorityQuotes', state.selectedQuotes);

    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📋 [NotificationsChoicePage] Sauvegarde');
      debugPrint(
          '   - Citations prioritaires: ${state.selectedQuotes.length} citations');
      if (state.selectedQuotes.isNotEmpty) {
        debugPrint('   - Détail (dans l\'ordre):');
        for (var i = 0; i < state.selectedQuotes.length; i++) {
          final text = state.selectedQuotes[i];
          final preview =
              text.length > 100 ? '${text.substring(0, 100)}...' : text;
          debugPrint('     ${i + 1}. $preview');
        }
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    final habits = _ref.read(habitsStateProvider);
    final lang = _ref.read(languageProvider);
    await NotificationService.instance.scheduleFromHabits(
      prefs: prefs,
      habits: habits,
      languageCode: lang,
      triggeredAutomatically: false,
    );
  }

  List<NotificationQuoteItem> _buildAllQuotes(String lang) {
    final allQuotes = <NotificationQuoteItem>[];
    for (final topicKey in quotesTot.keys) {
      final quotes = quotesTot[topicKey] as List;
      for (final raw in quotes) {
        if (raw is! Map) continue;
        final q = Map<String, dynamic>.from(raw);
        final text = q[lang] ?? q['en'];
        if (text != null && text.isNotEmpty) {
          allQuotes.add(
            NotificationQuoteItem(
              text: text,
              signature: q['signature'] as String?,
              bookTitle: q['bookTitle']?[lang] ?? q['bookTitle']?['en'],
              url: q['url'],
              category: topicKey.toString(),
            ),
          );
        }
      }
    }

    allQuotes.sort((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));
    return allQuotes;
  }
}

