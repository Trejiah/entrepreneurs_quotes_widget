import 'package:businessmindset/utils/favorite_management.dart';

class FavoriteDetailUiState {
  const FavoriteDetailUiState({
    this.quotesGlobal = const [],
    this.historyGlobal = const [],
    this.results = const [],
    this.isChecked = const [],
    this.search = '',
    this.randomQuote = '',
    this.suggestionAllowed = false,
    this.suggesting = false,
    this.favoritesModified = false,
  });

  final List<DayQuote> quotesGlobal;
  final List<DayQuote> historyGlobal;
  final List<DayQuote> results;
  final List<bool> isChecked;
  final String search;
  final String randomQuote;
  final bool suggestionAllowed;
  final bool suggesting;
  final bool favoritesModified;

  bool get useSearch => search.trim().length >= 3;

  FavoriteDetailUiState copyWith({
    List<DayQuote>? quotesGlobal,
    List<DayQuote>? historyGlobal,
    List<DayQuote>? results,
    List<bool>? isChecked,
    String? search,
    String? randomQuote,
    bool? suggestionAllowed,
    bool? suggesting,
    bool? favoritesModified,
  }) {
    return FavoriteDetailUiState(
      quotesGlobal: quotesGlobal ?? this.quotesGlobal,
      historyGlobal: historyGlobal ?? this.historyGlobal,
      results: results ?? this.results,
      isChecked: isChecked ?? this.isChecked,
      search: search ?? this.search,
      randomQuote: randomQuote ?? this.randomQuote,
      suggestionAllowed: suggestionAllowed ?? this.suggestionAllowed,
      suggesting: suggesting ?? this.suggesting,
      favoritesModified: favoritesModified ?? this.favoritesModified,
    );
  }
}

