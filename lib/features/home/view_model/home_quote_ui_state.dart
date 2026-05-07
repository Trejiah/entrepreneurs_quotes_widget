import 'package:businessmindset/utils/favorite_management.dart';

/// État UI des citations pour Home.
class HomeQuoteUiState {
  const HomeQuoteUiState({
    this.currentQuote = '',
    this.currentQuoteData,
    this.quoteHistory = const [],
    this.quoteHistoryData = const [],
    this.historyIndex = 0,
    this.swipeDirection = 1,
    this.liked = false,
    this.favoritesGlobal = const [],
    this.persistedHistoryGlobal = const [],
    this.selectedTopics = const [],
  });

  final String currentQuote;
  final Map<String, dynamic>? currentQuoteData;
  final List<String> quoteHistory;
  final List<Map<String, dynamic>> quoteHistoryData;
  final int historyIndex;
  final int swipeDirection;
  final bool liked;
  final List<DayQuote> favoritesGlobal;
  final List<DayQuote> persistedHistoryGlobal;
  final List<String> selectedTopics;

  HomeQuoteUiState copyWith({
    String? currentQuote,
    Map<String, dynamic>? currentQuoteData,
    List<String>? quoteHistory,
    List<Map<String, dynamic>>? quoteHistoryData,
    int? historyIndex,
    int? swipeDirection,
    bool? liked,
    List<DayQuote>? favoritesGlobal,
    List<DayQuote>? persistedHistoryGlobal,
    List<String>? selectedTopics,
    bool clearCurrentQuoteData = false,
  }) {
    return HomeQuoteUiState(
      currentQuote: currentQuote ?? this.currentQuote,
      currentQuoteData:
          clearCurrentQuoteData ? null : (currentQuoteData ?? this.currentQuoteData),
      quoteHistory: quoteHistory ?? this.quoteHistory,
      quoteHistoryData: quoteHistoryData ?? this.quoteHistoryData,
      historyIndex: historyIndex ?? this.historyIndex,
      swipeDirection: swipeDirection ?? this.swipeDirection,
      liked: liked ?? this.liked,
      favoritesGlobal: favoritesGlobal ?? this.favoritesGlobal,
      persistedHistoryGlobal: persistedHistoryGlobal ?? this.persistedHistoryGlobal,
      selectedTopics: selectedTopics ?? this.selectedTopics,
    );
  }
}
