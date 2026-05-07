import 'package:businessmindset/features/settings/pages/choose_quote/model/choose_quote_models.dart';
import 'package:businessmindset/features/settings/pages/choose_quote/view_model/choose_quote_ui_state.dart';
import 'package:businessmindset/models/quotes_model.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/services/widget_subscription_sync.dart';
import 'package:businessmindset/utils/favorite_management.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChooseQuoteViewModel extends StateNotifier<ChooseQuoteUiState> {
  ChooseQuoteViewModel(this._ref) : super(const ChooseQuoteUiState());

  final Ref _ref;
  static const MethodChannel _widgetChannel =
      MethodChannel('businessmindset/deeplink');

  void init() {
    final lang = _ref.read(languageProvider);
    final allQuotes = <ChooseQuoteItem>[];

    for (final topicKey in quotesTot.keys) {
      final quotes = quotesTot[topicKey] as List;
      for (final raw in quotes) {
        if (raw is! Map) continue;
        final q = Map<String, dynamic>.from(raw);
        final text = q[lang] ?? q['en'];
        if (text != null && text.isNotEmpty) {
          allQuotes.add(
            ChooseQuoteItem(
              text: text,
              category: topicKey.toString(),
              signature: q['signature'] as String?,
              bookTitle: q['bookTitle']?[lang] ?? q['bookTitle']?['en'],
              url: q['url'],
            ),
          );
        }
      }
    }

    allQuotes.sort((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));
    state = state.copyWith(allQuotes: allQuotes);
  }

  void onSearchChanged(String value) {
    state = state.copyWith(searchText: value);
  }

  Future<void> selectQuote(ChooseQuoteItem quote) async {
    try {
      final lang = _ref.read(languageProvider);
      final date = DateTime.now();
      final monthName =
          monthNames[lang]?[date.month - 1] ?? monthNames['en']![date.month - 1];

      final quoteMetadata = <String, dynamic>{
        'quote': quote.text,
        'category': quote.category,
        'signature': quote.signature,
        'bookTitle': quote.bookTitle,
        'url': quote.url,
        'languageCode': lang,
        'day': date.day,
        'month': monthName,
        'year': date.year,
      };
      final premiumExpirationEpochMs = await fetchWidgetPremiumExpirationEpochMs();

      await _widgetChannel.invokeMethod('updateWidgetData', {
        'quote': quote.text,
        'widgetQuoteDetails': quoteMetadata,
        'premiumExpirationEpochMs': premiumExpirationEpochMs,
      });
      await _widgetChannel.invokeMethod('reloadWidgets');

      if (kDebugMode) {
        debugPrint('📋 [ChooseQuotePage] Widget updated - Citation: ${quote.text}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [ChooseQuotePage] Error while updating the widget: $e');
      }
    }
  }
}

