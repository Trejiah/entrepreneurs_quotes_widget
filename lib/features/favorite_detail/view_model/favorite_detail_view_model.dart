import 'dart:math';

import 'package:businessmindset/features/favorite_detail/model/favorite_detail_models.dart';
import 'package:businessmindset/features/favorite_detail/view_model/favorite_detail_ui_state.dart';
import 'package:businessmindset/models/quotes_model.dart' show quotesTot;
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart' show premiumProvider;
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/utils/favorite_management.dart'
    show
        DayQuote,
        loadAllFavorite,
        loadAllHistory,
        monthNames,
        saveAllFavorite;
import 'package:businessmindset/utils/quote_utils.dart' show findQuoteMetadata;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteDetailNotifier extends StateNotifier<FavoriteDetailUiState> {
  FavoriteDetailNotifier(this._ref, this.input)
      : super(const FavoriteDetailUiState());

  final Ref _ref;
  final FavoriteDetailInput input;

  late List<DayQuote> _persistedQuotes;

  Future<void> loadQuotesIntoGlobal() async {
    final loaded = await loadAllFavorite();
    final quotesGlobal = List<DayQuote>.from(loaded);
    final historyGlobal = await loadAllHistory();
    _persistedQuotes = List<DayQuote>.from(loaded);

    final isChecked = input.pageStyle == 'search'
        ? List<bool>.filled(quotesGlobal.length, true)
        : List<bool>.generate(historyGlobal.length, (i) {
            final quote = historyGlobal[i].quote;
            return quotesGlobal.any((q) => q.quote == quote);
          });

    state = state.copyWith(
      quotesGlobal: quotesGlobal,
      historyGlobal: historyGlobal,
      isChecked: isChecked,
    );
  }

  Future<void> onSearchChanged(String value) async {
    final premium = _ref.read(premiumProvider);
    final search = value;
    final useSearch = search.trim().length >= 3;

    List<DayQuote> nextResults = const [];
    if (useSearch) {
      final needle = search.toLowerCase();
      if (input.pageStyle == 'search') {
        nextResults = state.quotesGlobal
            .where((dq) => dq.quote.toLowerCase().contains(needle))
            .toList();
      } else {
        final visibleHistory = reverseAndLimit(state.historyGlobal, premium);
        nextResults = visibleHistory
            .where((dq) => dq.quote.toLowerCase().contains(needle))
            .toList();
      }
    }

    state = state.copyWith(
      search: search,
      results: useSearch ? nextResults : const [],
      suggestionAllowed: false,
      randomQuote: '',
    );

    // Suggestions only on the "search" page (favorites) and only when no results.
    if (input.pageStyle == 'search' && useSearch && nextResults.isEmpty) {
      await prepareSuggestionIfAllowed();
    }
  }

  List<DayQuote> reverseAndLimit(
    List<DayQuote> list,
    bool premium, {
    int limit = 10,
  }) {
    final reversed = List<DayQuote>.from(list.reversed);
    if (premium) return reversed;
    return reversed.take(min(limit, reversed.length)).toList();
  }

  Future<void> prepareSuggestionIfAllowed() async {
    final lang = _ref.read(languageProvider);
    final premium = _ref.read(premiumProvider);

    bool allowed = await canShowSuggestion(premium);
    if (input.pageStyle != 'search') allowed = false;

    if (!allowed) {
      state = state.copyWith(
        suggestionAllowed: false,
        randomQuote: '',
      );
      return;
    }

    await getRandomQuoteAnyCategory(lang);
    await incrementSuggestionCounterIfNeeded(premium);
    state = state.copyWith(suggestionAllowed: true);
  }

  Future<bool> canShowSuggestion(bool premium) async {
    if (premium) return true;

    final prefs = await SharedPreferences.getInstance();
    final today = _todayStamp();

    final savedDay = prefs.getString('suggestion/day');
    int count = prefs.getInt('suggestion/count') ?? 0;

    if (savedDay != today) {
      await prefs.setString('suggestion/day', today);
      await prefs.setInt('suggestion/count', 0);
      count = 0;
    }

    return count < 3;
  }

  Future<void> incrementSuggestionCounterIfNeeded(bool premium) async {
    if (premium) return;

    final prefs = await SharedPreferences.getInstance();
    final today = _todayStamp();

    final savedDay = prefs.getString('suggestion/day');
    int count = prefs.getInt('suggestion/count') ?? 0;

    if (savedDay != today) {
      await prefs.setString('suggestion/day', today);
      count = 0;
    }

    await prefs.setInt('suggestion/count', count + 1);
  }

  Future<void> getRandomQuoteAnyCategory(String lang) async {
    final random = Random();

    final favQuotes = await loadAllFavorite();
    final favTexts = favQuotes.map((e) => e.quote.trim()).toSet();

    final allQuotes = <String>[];
    for (final cat in quotesTot.keys) {
      final quotes = quotesTot[cat] ?? [];
      for (final q in quotes) {
        final text = q[lang] ?? q['en'];
        if (text != null && text.trim().isNotEmpty) {
          allQuotes.add(text.trim());
        }
      }
    }

    final availableQuotes =
        allQuotes.where((q) => !favTexts.contains(q)).toList();

    final randomQuote = availableQuotes.isEmpty
        ? 'All available quotes are already in your favorites!'
        : availableQuotes[random.nextInt(availableQuotes.length)];

    state = state.copyWith(
      randomQuote: randomQuote,
      suggesting: false,
    );
  }

  Future<void> likeRandomSuggestion() async {
    final quote = state.randomQuote.trim();
    if (quote.isEmpty) return;

    await addCurrentQuoteToGlobalAndSave2(quote);

    // Marquer que la liste des favoris a changé + tracker comme un "Like".
    state = state.copyWith(
      search: '',
      results: const [],
      favoritesModified: true,
    );
    MixpanelService.instance.track('[Quote] Like', {});
  }

  Future<void> onLeftFavoriteTapped({
    required int originalIndex,
    required String quoteText,
    required bool currentlyChecked,
  }) async {
    if (originalIndex < 0) return;

    if (currentlyChecked) {
      final next = List<bool>.from(state.isChecked);
      if (originalIndex < next.length) next[originalIndex] = false;
      state = state.copyWith(isChecked: next);
      await removeQuoteFromGlobalAndSave(quoteText, removeAllMatches: true);
    } else {
      final next = List<bool>.from(state.isChecked);
      if (originalIndex < next.length) next[originalIndex] = true;
      state = state.copyWith(isChecked: next);
      await saveQuote(quoteText);
    }
  }

  Future<void> saveQuote(String currentQuote) async {
    await addCurrentQuoteToGlobalAndSave2(currentQuote);
    state = state.copyWith(favoritesModified: true);
    MixpanelService.instance.track('[Quote] Like', {});
  }

  Future<void> removeQuoteFromGlobalAndSave(
    String currentQuote, {
    bool removeAllMatches = false,
  }) async {
    if (removeAllMatches) {
      _persistedQuotes.removeWhere((e) => e.quote == currentQuote);
    } else {
      final idx = _persistedQuotes.indexWhere((e) => e.quote == currentQuote);
      if (idx != -1) _persistedQuotes.removeAt(idx);
    }

    await saveAllFavorite(_persistedQuotes);
    state = state.copyWith(favoritesModified: true);
    MixpanelService.instance.track('[Quote] Unlike', {});
  }

  Future<void> addCurrentQuoteToGlobalAndSave2(String currentQuote) async {
    final lang = _ref.read(languageProvider);
    final now = DateTime.now();

    final monthName =
        monthNames[lang]?[now.month - 1] ?? monthNames['en']![now.month - 1];

    final metadata = findQuoteMetadata(currentQuote, lang);

    final alreadyInUI = state.quotesGlobal.any((e) => e.quote == currentQuote);
    if (!alreadyInUI) {
      final nextQuotes = List<DayQuote>.from(state.quotesGlobal)
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

      final nextChecked = List<bool>.from(state.isChecked)..add(true);
      state = state.copyWith(quotesGlobal: nextQuotes, isChecked: nextChecked);
    }

    final alreadyPersisted =
        _persistedQuotes.any((e) => e.quote == currentQuote);
    if (!alreadyPersisted) {
      _persistedQuotes.add(
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
      await saveAllFavorite(_persistedQuotes);
    }
  }

  String _todayStamp() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
  }

  void trackShareResult(bool shared) {
    if (shared) {
      MixpanelService.instance.track(
        '[Quote] Share',
        {'status': 'success'},
      );
    } else {
      MixpanelService.instance.track(
        '[Quote] Share',
        {'status': 'cancelled'},
      );
    }
  }
}

