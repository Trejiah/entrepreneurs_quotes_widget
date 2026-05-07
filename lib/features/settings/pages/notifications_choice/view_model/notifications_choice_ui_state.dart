import 'package:businessmindset/features/settings/pages/notifications_choice/model/notifications_choice_models.dart';

class NotificationsChoiceUiState {
  const NotificationsChoiceUiState({
    this.selectedQuotes = const [],
    this.searchText = '',
    this.allQuotes = const [],
  });

  final List<String> selectedQuotes;
  final String searchText;
  final List<NotificationQuoteItem> allQuotes;

  List<NotificationQuoteItem> get filteredQuotes {
    if (searchText.isEmpty) return allQuotes;
    final searchLower = searchText.toLowerCase();
    return allQuotes
        .where((quote) => quote.text.toLowerCase().startsWith(searchLower))
        .toList(growable: false);
  }

  NotificationsChoiceUiState copyWith({
    List<String>? selectedQuotes,
    String? searchText,
    List<NotificationQuoteItem>? allQuotes,
  }) {
    return NotificationsChoiceUiState(
      selectedQuotes: selectedQuotes ?? this.selectedQuotes,
      searchText: searchText ?? this.searchText,
      allQuotes: allQuotes ?? this.allQuotes,
    );
  }
}

