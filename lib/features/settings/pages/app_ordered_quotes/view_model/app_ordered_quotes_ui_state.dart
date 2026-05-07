import 'package:businessmindset/features/settings/pages/app_ordered_quotes/model/app_ordered_quotes_models.dart';

class AppOrderedQuotesUiState {
  const AppOrderedQuotesUiState({
    this.orderedQuotes = const [],
    this.searchText = '',
    this.allQuotes = const [],
  });

  final List<String> orderedQuotes;
  final String searchText;
  final List<AppOrderedQuoteItem> allQuotes;

  List<AppOrderedQuoteItem> get filteredQuotes {
    if (searchText.isEmpty) return allQuotes;
    final searchLower = searchText.toLowerCase();
    return allQuotes
        .where((quote) => quote.text.toLowerCase().startsWith(searchLower))
        .toList(growable: false);
  }

  AppOrderedQuotesUiState copyWith({
    List<String>? orderedQuotes,
    String? searchText,
    List<AppOrderedQuoteItem>? allQuotes,
  }) {
    return AppOrderedQuotesUiState(
      orderedQuotes: orderedQuotes ?? this.orderedQuotes,
      searchText: searchText ?? this.searchText,
      allQuotes: allQuotes ?? this.allQuotes,
    );
  }
}

