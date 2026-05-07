import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:businessmindset/utils/favorite_management.dart';
import 'package:businessmindset/utils/quote_utils.dart';

final homeQuotesCoordinatorProvider = Provider<HomeQuotesCoordinator>((ref) {
  return HomeQuotesCoordinator();
});

class HomeQuotesCoordinator {
  Future<({List<DayQuote> favorites, List<DayQuote> history})> loadStoredQuotes() async {
    final favorites = await loadAllFavorite();
    final history = await loadAllHistory();
    return (favorites: favorites, history: history);
  }

  bool isQuoteLiked({
    required List<DayQuote> favorites,
    required String currentQuote,
  }) {
    return favorites.any((e) => e.quote == currentQuote);
  }

  QuoteMetadata? resolveCurrentQuoteMetadata({
    required String currentQuote,
    required Map<String, dynamic>? currentQuoteData,
    required String lang,
  }) {
    if (currentQuoteData != null) {
      final text = (currentQuoteData['text'] as String?) ?? currentQuote;
      if (text.isEmpty) return null;
      return QuoteMetadata(
        category: (currentQuoteData['category'] as String?) ?? '',
        text: text,
        signature: currentQuoteData['signature'] as String?,
        bookTitle: currentQuoteData['bookTitle'] as String?,
        url: currentQuoteData['url'] as String?,
      );
    }
    return findQuoteMetadata(currentQuote, lang);
  }

  Future<List<DayQuote>> appendToHistoryAndSave({
    required List<DayQuote> history,
    required String currentQuote,
    required QuoteMetadata? metadata,
    required String lang,
  }) async {
    final now = DateTime.now();
    final monthName = monthNames[lang]?[now.month - 1] ?? monthNames['en']![now.month - 1];
    final updated = List<DayQuote>.from(history)
      ..add(
        DayQuote(
          day: now.day,
          month: monthName,
          year: now.year,
          quote: currentQuote,
          category: metadata?.category,
          signature: metadata?.signature,
          bookTitle: metadata?.bookTitle,
          url: metadata?.url,
        ),
      );

    if (updated.length > 50) {
      updated.removeRange(0, updated.length - 50);
    }

    await saveAllHistory(updated);
    return updated;
  }

  Future<List<DayQuote>> appendToFavoritesAndSave({
    required List<DayQuote> favorites,
    required String currentQuote,
    required QuoteMetadata? metadata,
    required String lang,
  }) async {
    final now = DateTime.now();
    final monthName = monthNames[lang]?[now.month - 1] ?? monthNames['en']![now.month - 1];
    final updated = List<DayQuote>.from(favorites)
      ..add(
        DayQuote(
          day: now.day,
          month: monthName,
          year: now.year,
          quote: currentQuote,
          category: metadata?.category,
          signature: metadata?.signature,
          bookTitle: metadata?.bookTitle,
          url: metadata?.url,
        ),
      );

    await saveAllFavorite(updated);
    return updated;
  }

  Future<({List<DayQuote> favorites, bool removed})> removeFromFavoritesAndSave({
    required List<DayQuote> favorites,
    required String currentQuote,
    bool removeAllMatches = false,
  }) async {
    final updated = List<DayQuote>.from(favorites);
    bool removed = false;

    if (removeAllMatches) {
      final before = updated.length;
      updated.removeWhere((e) => e.quote == currentQuote);
      removed = updated.length != before;
    } else {
      final idx = updated.indexWhere((e) => e.quote == currentQuote);
      if (idx != -1) {
        updated.removeAt(idx);
        removed = true;
      }
    }

    if (removed) {
      await saveAllFavorite(updated);
    }
    return (favorites: updated, removed: removed);
  }
}
