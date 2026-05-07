import 'package:businessmindset/features/settings/pages/choose_quote/model/choose_quote_models.dart';

class ChooseQuoteUiState {
  const ChooseQuoteUiState({
    this.searchText = '',
    this.allQuotes = const [],
  });

  final String searchText;
  final List<ChooseQuoteItem> allQuotes;

  List<ChooseQuoteItem> get filteredQuotes {
    if (searchText.isEmpty) return allQuotes;
    final searchLower = searchText.toLowerCase();
    return allQuotes
        .where((quote) => quote.text.toLowerCase().startsWith(searchLower))
        .toList(growable: false);
  }

  ChooseQuoteUiState copyWith({
    String? searchText,
    List<ChooseQuoteItem>? allQuotes,
  }) {
    return ChooseQuoteUiState(
      searchText: searchText ?? this.searchText,
      allQuotes: allQuotes ?? this.allQuotes,
    );
  }
}

