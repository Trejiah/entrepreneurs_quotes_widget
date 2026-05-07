import 'package:businessmindset/features/settings/pages/lockscreen_choice/model/lockscreen_choice_models.dart';

class LockscreenChoiceUiState {
  const LockscreenChoiceUiState({
    this.lockscreenQuote,
    this.searchText = '',
    this.allQuotes = const [],
  });

  final String? lockscreenQuote;
  final String searchText;
  final List<LockscreenQuoteItem> allQuotes;

  List<LockscreenQuoteItem> get filteredQuotes {
    if (searchText.isEmpty) return allQuotes;
    final searchLower = searchText.toLowerCase();
    return allQuotes
        .where((quote) => quote.text.toLowerCase().startsWith(searchLower))
        .toList(growable: false);
  }

  LockscreenChoiceUiState copyWith({
    Object? lockscreenQuote = _sentinel,
    String? searchText,
    List<LockscreenQuoteItem>? allQuotes,
  }) {
    return LockscreenChoiceUiState(
      lockscreenQuote: identical(lockscreenQuote, _sentinel)
          ? this.lockscreenQuote
          : lockscreenQuote as String?,
      searchText: searchText ?? this.searchText,
      allQuotes: allQuotes ?? this.allQuotes,
    );
  }
}

const Object _sentinel = Object();

