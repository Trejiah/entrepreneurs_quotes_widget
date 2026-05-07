import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:businessmindset/models/quotes_model.dart';

final homeSelectionCoordinatorProvider = Provider<HomeSelectionCoordinator>((ref) {
  return HomeSelectionCoordinator();
});

class SelectedQuoteResult {
  const SelectedQuoteResult({
    required this.quoteText,
    required this.metadata,
    required this.existingIndex,
    required this.isNewQuote,
  });

  final String quoteText;
  final Map<String, dynamic> metadata;
  final int existingIndex;
  final bool isNewQuote;
}

class HomeSelectionCoordinator {
  HomeSelectionCoordinator();

  Future<void> applyAppOrderedQuotes({
    required List<String> history,
    required List<Map<String, dynamic>> historyData,
    required String lang,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final orderedQuotes = prefs.getStringList('appOrderedQuotes') ?? [];
    if (orderedQuotes.isEmpty) return;

    for (final quoteText in orderedQuotes) {
      while (history.contains(quoteText)) {
        final index = history.indexOf(quoteText);
        history.removeAt(index);
        historyData.removeAt(index);
      }
    }

    for (final quoteText in orderedQuotes) {
      Map<String, dynamic>? quoteData;
      for (final entry in quotesTot.entries) {
        final topicKey = entry.key;
        final quotes = entry.value;
        if (quotes is! Iterable) continue;
        for (final raw in quotes) {
          if (raw is! Map) continue;
          final q = Map<String, dynamic>.from(raw);
          final text = q[lang] ?? q['en'];
          if (text == quoteText) {
            quoteData = {
              'text': text,
              'category': topicKey,
              'signature': q['signature'] as String?,
              'bookTitle': q['bookTitle']?[lang] ?? q['bookTitle']?['en'],
              'url': q['url'],
            };
            break;
          }
        }
        if (quoteData != null) break;
      }

      quoteData ??= {
        'text': quoteText,
        'category': null,
        'signature': null,
        'bookTitle': null,
        'url': null,
      };

      history.add(quoteText);
      historyData.add(quoteData);
    }
  }

  Future<SelectedQuoteResult?> consumeSelectedQuoteFromChoosePage({
    required List<String> history,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final quoteSelected = prefs.getBool('quoteSelectedFromChoosePage') ?? false;
    if (!quoteSelected) return null;

    await prefs.setBool('quoteSelectedFromChoosePage', false);
    final quoteText = prefs.getString('selectedQuoteText');
    if (quoteText == null || quoteText.isEmpty) return null;

    final metadata = <String, dynamic>{
      'category': prefs.getString('selectedQuoteCategory') ?? '',
      'text': quoteText,
      'signature': prefs.getString('selectedQuoteSignature'),
      'bookTitle': prefs.getString('selectedQuoteBookTitle'),
      'url': prefs.getString('selectedQuoteUrl'),
    };

    final existingIndex = history.indexOf(quoteText);
    final isNewQuote = existingIndex == -1;

    await prefs.remove('selectedQuoteText');
    await prefs.remove('selectedQuoteCategory');
    await prefs.remove('selectedQuoteSignature');
    await prefs.remove('selectedQuoteBookTitle');
    await prefs.remove('selectedQuoteUrl');

    return SelectedQuoteResult(
      quoteText: quoteText,
      metadata: metadata,
      existingIndex: existingIndex,
      isNewQuote: isNewQuote,
    );
  }
}
