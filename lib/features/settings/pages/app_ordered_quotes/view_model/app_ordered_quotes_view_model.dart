import 'package:businessmindset/features/settings/pages/app_ordered_quotes/model/app_ordered_quotes_models.dart';
import 'package:businessmindset/features/settings/pages/app_ordered_quotes/view_model/app_ordered_quotes_ui_state.dart';
import 'package:businessmindset/models/quotes_model.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppOrderedQuotesViewModel extends StateNotifier<AppOrderedQuotesUiState> {
  AppOrderedQuotesViewModel(this._ref) : super(const AppOrderedQuotesUiState());

  final Ref _ref;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final orderedQuotes = prefs.getStringList('appOrderedQuotes') ?? [];
    final allQuotes = _buildAllQuotes(_ref.read(languageProvider));
    state = state.copyWith(
      orderedQuotes: List<String>.from(orderedQuotes),
      allQuotes: allQuotes,
    );

    if (kDebugMode) {
      debugPrint('📋 [AppOrderedQuotesPage] Quotes loaded: ${orderedQuotes.length}');
    }
  }

  void onSearchChanged(String value) {
    state = state.copyWith(searchText: value);
  }

  void toggleQuote(String text) {
    final next = List<String>.from(state.orderedQuotes);
    if (next.contains(text)) {
      next.remove(text);
    } else {
      next.add(text);
    }
    state = state.copyWith(orderedQuotes: next);
  }

  Future<void> saveChoices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('appOrderedQuotes', state.orderedQuotes);

    if (kDebugMode) {
      debugPrint('📋 [AppOrderedQuotesPage] Sauvegarde');
      debugPrint('   - Ordered quotes: ${state.orderedQuotes.length} quotes');
    }
  }

  List<AppOrderedQuoteItem> _buildAllQuotes(String lang) {
    final allQuotes = <AppOrderedQuoteItem>[];
    for (final topicKey in quotesTot.keys) {
      final quotes = quotesTot[topicKey] as List;
      for (final raw in quotes) {
        if (raw is! Map) continue;
        final q = Map<String, dynamic>.from(raw);
        final text = q[lang] ?? q['en'];
        if (text != null && text.isNotEmpty) {
          allQuotes.add(
            AppOrderedQuoteItem(
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

