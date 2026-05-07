class LockscreenQuoteItem {
  const LockscreenQuoteItem({
    required this.text,
    this.signature,
    this.bookTitle,
    this.url,
    this.category,
  });

  final String text;
  final String? signature;
  final String? bookTitle;
  final dynamic url;
  final String? category;
}

