import 'dart:io' show Platform;

class SharePreviewInput {
  const SharePreviewInput({
    required this.imageBytes,
    required this.quote,
    this.signature,
    this.bookTitle,
  });

  final List<int> imageBytes;
  final String quote;
  final String? signature;
  final String? bookTitle;
}

class SharePreviewTextBuilder {
  static const String appStoreUrl =
      'https://apps.apple.com/us/app/business-mindset-quotes/id6754601387';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.bakemono.businessmindset';

  static String build({
    required String quote,
    String? signature,
    String? bookTitle,
  }) {
    final appLink = Platform.isIOS ? appStoreUrl : playStoreUrl;
    final buffer = StringBuffer()..writeln(quote);
    if (signature != null && signature.isNotEmpty) {
      buffer.writeln('— $signature');
    }
    if (bookTitle != null && bookTitle.isNotEmpty) {
      buffer.writeln(bookTitle);
    }
    buffer.writeln('');
    buffer.writeln(appLink);
    return buffer.toString().trim();
  }
}

