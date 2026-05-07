// Generates `android/app/src/main/kotlin/com/bakemono/businessmindset/widget/quotes/QuotesModel.kt`
// from [lib/models/quotes_model.dart].
//
// Mirrors what was done once by hand for iOS: the native Android widget
// cannot call Flutter code, so we embed the whole quote database as a
// plain Kotlin object graph that the Glance widget can read directly.
//
// Run from the repo root:
//   dart run tool/generate_kotlin_quotes.dart
//
// Like the iOS generator, the emitted file is committed to the repo and
// should not be hand-edited; re-run this script after any change to
// `lib/models/quotes_model.dart`.

import 'dart:io';

import '../lib/models/quotes_model.dart' as src;

const _outputPath =
    'android/app/src/main/kotlin/com/bakemono/businessmindset/widget/quotes/QuotesModel.kt';

const _header = '''//
// QuotesModel.kt
// Generated automatically from lib/models/quotes_model.dart by
// tool/generate_kotlin_quotes.dart — do not edit manually, re-run the
// generator instead. Mirrors ios/BusinessMindsetWidget/QuotesModel.swift.
//
@file:Suppress("ObjectPropertyName", "SpellCheckingInspection", "MaxLineLength")

package com.bakemono.businessmindset.widget.quotes

data class BookTitle(val en: String?, val fr: String?)

data class QuoteData(
    val en: String?,
    val fr: String?,
    val signature: String?,
    val bookTitle: BookTitle?,
    val url: String?,
    val personalizedPlan: String?,
    val isFree: Boolean?,
    val businessic: Boolean?,
    val frombook: Boolean?,
    val tone: String?,
)
''';

void main() {
  final buf = StringBuffer()..writeln(_header);

  final categories = <String>[];
  for (final entry in src.quotesTot.entries) {
    final category = entry.key.toString();
    categories.add(category);
    buf
      ..writeln()
      ..writeln('private val quotesTot_$category: List<QuoteData> = listOf(');
    final quotes = entry.value as List<dynamic>;
    for (var i = 0; i < quotes.length; i++) {
      final raw = quotes[i];
      if (raw is! Map) continue;
      final Map<String, dynamic> q = Map<String, dynamic>.from(raw);
      buf.write('    ');
      _writeQuote(buf, q);
      if (i != quotes.length - 1) {
        buf.writeln(',');
      } else {
        buf.writeln();
      }
    }
    buf.writeln(')');
  }

  buf
    ..writeln()
    ..writeln('internal val quotesTot: Map<String, List<QuoteData>> = mapOf(');
  for (var i = 0; i < categories.length; i++) {
    final c = categories[i];
    final comma = i == categories.length - 1 ? '' : ',';
    buf.writeln('    "$c" to quotesTot_$c$comma');
  }
  buf.writeln(')');

  final file = File(_outputPath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(buf.toString());

  stdout.writeln('Wrote ${file.path}');
  final lineCount = buf.toString().split('\n').length;
  stdout.writeln('Categories: ${categories.length}, total lines: $lineCount');
}

void _writeQuote(StringBuffer buf, Map<String, dynamic> q) {
  buf.writeln('QuoteData(');
  buf.writeln('        en = ${_kString(q['en'])},');
  buf.writeln('        fr = ${_kString(q['fr'])},');
  buf.writeln('        signature = ${_kString(q['signature'])},');
  buf.writeln('        bookTitle = ${_kBookTitle(q['bookTitle'])},');
  buf.writeln('        url = ${_kString(q['url'])},');
  buf.writeln('        personalizedPlan = ${_kString(q['personalized_plan'])},');
  buf.writeln('        isFree = ${_kBool(q['isFree'])},');
  buf.writeln('        businessic = ${_kBool(q['businessic'])},');
  buf.writeln('        frombook = ${_kBool(q['frombook'])},');
  buf.writeln('        tone = ${_kString(q['tone'])},');
  buf.write('    )');
}

String _kString(Object? value) {
  if (value == null) return 'null';
  if (value is! String) return 'null';
  return '"${_escape(value)}"';
}

String _kBool(Object? value) {
  if (value == null) return 'null';
  if (value is bool) return value ? 'true' : 'false';
  return 'null';
}

String _kBookTitle(Object? value) {
  if (value == null) return 'null';
  if (value is Map) {
    final en = value['en'];
    final fr = value['fr'];
    return 'BookTitle(en = ${_kString(en)}, fr = ${_kString(fr)})';
  }
  return 'null';
}

String _escape(String input) {
  final buf = StringBuffer();
  for (final rune in input.runes) {
    switch (rune) {
      case 0x5c: // \
        buf.write(r'\\');
        break;
      case 0x22: // "
        buf.write(r'\"');
        break;
      case 0x24: // $
        buf.write(r'\$');
        break;
      case 0x0a: // \n
        buf.write(r'\n');
        break;
      case 0x0d: // \r
        buf.write(r'\r');
        break;
      case 0x09: // \t
        buf.write(r'\t');
        break;
      default:
        buf.writeCharCode(rune);
    }
  }
  return buf.toString();
}
