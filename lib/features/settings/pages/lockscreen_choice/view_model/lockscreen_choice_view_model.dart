import 'package:businessmindset/features/settings/pages/lockscreen_choice/model/lockscreen_choice_models.dart';
import 'package:businessmindset/features/settings/pages/lockscreen_choice/view_model/lockscreen_choice_ui_state.dart';
import 'package:businessmindset/models/quotes_model.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockscreenChoiceViewModel extends StateNotifier<LockscreenChoiceUiState> {
  LockscreenChoiceViewModel(this._ref)
      : super(const LockscreenChoiceUiState());

  final Ref _ref;
  static const MethodChannel _widgetChannel =
      MethodChannel('businessmindset/deeplink');

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    String? forcedQuote;
    try {
      forcedQuote = await _widgetChannel.invokeMethod<String>(
        'getLockscreenForcedQuote',
      );
      if (kDebugMode) {
        debugPrint(
          '📋 [LockscreenChoicePage] Citation forcée chargée: ${forcedQuote ?? 'null'}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ [LockscreenChoicePage] Error while loading the forced quote: $e',
        );
      }
      forcedQuote = prefs.getString('lockscreenForcedQuote');
    }

    final allQuotes = _buildAllQuotes(_ref.read(languageProvider));
    state = state.copyWith(lockscreenQuote: forcedQuote, allQuotes: allQuotes);
  }

  void onSearchChanged(String value) {
    state = state.copyWith(searchText: value);
  }

  void toggleQuote(String text) {
    if (state.lockscreenQuote == text) {
      state = state.copyWith(lockscreenQuote: null);
    } else {
      state = state.copyWith(lockscreenQuote: text);
    }
  }

  Future<void> saveChoices() async {
    final prefs = await SharedPreferences.getInstance();

    final quote = state.lockscreenQuote;
    if (quote != null) {
      await prefs.setString('lockscreenForcedQuote', quote);
    } else {
      await prefs.remove('lockscreenForcedQuote');
    }

    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📋 [LockscreenChoicePage] Sauvegarde');
      debugPrint('   - Forced quote: $quote');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    try {
      if (quote != null) {
        await _widgetChannel.invokeMethod('setLockscreenForcedQuote', {
          'quote': quote,
        });
      } else {
        await _widgetChannel.invokeMethod('clearLockscreenForcedQuote');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ [LockscreenChoicePage] Error while saving to the widget: $e',
        );
      }
    }

    try {
      await _widgetChannel.invokeMethod('forceLockScreenWidgetNewQuote');
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ [LockscreenChoicePage] Error while reloading the widget: $e',
        );
      }
    }
  }

  List<LockscreenQuoteItem> _buildAllQuotes(String lang) {
    final allQuotes = <LockscreenQuoteItem>[];
    for (final topicKey in quotesTot.keys) {
      final quotes = quotesTot[topicKey] as List;
      for (final raw in quotes) {
        if (raw is! Map) continue;
        final q = Map<String, dynamic>.from(raw);
        final text = q[lang] ?? q['en'];
        if (text != null && text.isNotEmpty) {
          allQuotes.add(
            LockscreenQuoteItem(
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

