import 'package:collection/collection.dart';

import '../models/quotes_model.dart';

class QuoteMetadata {
  final String category;
  final String text;
  final String? signature;
  final String? bookTitle;
  final String? url;

  const QuoteMetadata({
    required this.category,
    required this.text,
    this.signature,
    this.bookTitle,
    this.url,
  });
}

QuoteMetadata? findQuoteMetadata(String text, String lang) {
  for (final entry in quotesTot.entries) {
    final category = entry.key;
    final quotes = entry.value;
    if (quotes is! Iterable) continue;
    for (final raw in quotes) {
      if (raw is! Map) continue;
      final Map<String, dynamic> q = Map<String, dynamic>.from(raw);
      final possibleTexts = _localizedTexts(q);
      if (possibleTexts.contains(text)) {
        final resolvedText = _localizedString(q, lang) ?? text;
        return QuoteMetadata(
          category: category.toString(),
          text: resolvedText,
          signature: _localizedString(q['signature'], lang),
          bookTitle: _localizedString(q['bookTitle'], lang),
          url: q['url'] as String?,
        );
      }
    }
  }
  return null;
}

List<String> _localizedTexts(Map<String, dynamic> entry) {
  final result = <String>[];
  for (final key in ['fr', 'en']) {
    final value = entry[key];
    if (value is String && value.isNotEmpty) {
      result.add(value);
    }
  }
  // Some entries may be under another language code; we extract them too.
  entry.entries
      .where((e) => e.value is String && e.key.length == 2)
      .forEach((e) {
    final value = e.value as String;
    if (value.isNotEmpty && !result.contains(value)) {
      result.add(value);
    }
  });
  return result;
}

String? _localizedString(dynamic raw, String lang) {
  if (raw == null) return null;
  if (raw is String) return raw;
  if (raw is Map) {
    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    return map[lang] as String? ??
        map['en'] as String? ??
        map.values.firstWhereOrNull((value) => value is String && value.isNotEmpty) as String?;
  }
  return raw.toString();
}

