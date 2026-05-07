class ChooseQuoteItem {
  const ChooseQuoteItem({
    required this.text,
    required this.category,
    this.signature,
    this.bookTitle,
    this.url,
  });

  final String text;
  final String category;
  final String? signature;
  final String? bookTitle;
  final dynamic url;
}

