import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:businessmindset/models/quotes_model.dart';
import 'package:businessmindset/models/topics.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/utils/favorite_management.dart';

final homeQuoteEngineCoordinatorProvider = Provider<HomeQuoteEngineCoordinator>((ref) {
  return HomeQuoteEngineCoordinator(ref);
});

class HomeQuoteEngineCoordinator {
  HomeQuoteEngineCoordinator(this._ref);

  final Ref _ref;

  Future<Map<String, dynamic>> getRandomQuoteFromTopics({
    required String lang,
    required List<String> selectedTopics,
    required List<DayQuote> quotesGlobal,
  }) async {
    final random = Random();
    final premium = _ref.read(premiumProvider);

    final normalizedTopics = selectedTopics.isEmpty ? <String>['general'] : selectedTopics;
    final selectedTopicId = normalizedTopics[random.nextInt(normalizedTopics.length)];

    final availableQuotes = await getAvailableQuotesForTopic(
      topicId: selectedTopicId,
      lang: lang,
      premium: premium,
      quotesGlobal: quotesGlobal,
    );

    if (availableQuotes.isEmpty) {
      final cats = quotesTot.keys.toList();
      final randomCat = cats[random.nextInt(cats.length)];
      final quotes = quotesTot[randomCat]!;
      final randomQuote = quotes[random.nextInt(quotes.length)];
      final quoteText = randomQuote[lang] ?? randomQuote['en']!;
      return {
        'category': randomCat,
        'text': quoteText,
        'signature': randomQuote['signature'] as String?,
        'bookTitle': randomQuote['bookTitle']?[lang] ?? randomQuote['bookTitle']?['en'],
        'url': randomQuote['url'],
      };
    }

    final prefs = await SharedPreferences.getInstance();
    final affirmationPercentage = prefs.getInt('tone_value_AFFIRMATION') ?? 0;
    final noMercyPercentage = prefs.getInt('tone_value_NO MERCY') ?? 0;

    final weights = <double>[];
    for (final quote in availableQuotes) {
      double weight = 1.0;
      if (premium) {
        final tone = quote['tone'] as String?;
        if (tone == 'affirmative') {
          weight = (1.0 + (affirmationPercentage / 100.0)).clamp(0.01, double.infinity);
        } else if (tone == 'no mercy') {
          weight = (1.0 + (noMercyPercentage / 100.0)).clamp(0.01, double.infinity);
        }
      }
      weights.add(weight);
    }

    final totalWeight = weights.fold(0.0, (sum, w) => sum + w);
    final randomValue = random.nextDouble() * totalWeight;
    double cumulative = 0.0;
    var selectedIndex = 0;
    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (randomValue <= cumulative) {
        selectedIndex = i;
        break;
      }
    }
    return availableQuotes[selectedIndex];
  }

  Future<List<Map<String, dynamic>>> getAvailableQuotesForTopic({
    required String topicId,
    required String lang,
    required bool premium,
    required List<DayQuote> quotesGlobal,
  }) async {
    final availableQuotes = <Map<String, dynamic>>[];
    final prefs = await SharedPreferences.getInstance();
    final gender = prefs.getString('gender');
    final isFemale = gender == 'Female';

    if (topicId == personalizedFeedTopicId) {
      final random = Random();
      final planCategories = ['growth', 'discipline', 'confidence', 'strategy'];
      final planPercentages = <String, double>{};
      double totalPercentage = 0.0;
      for (final cat in planCategories) {
        final percentage = prefs.getDouble('plan_${cat}_percentage') ?? 0.0;
        if (percentage > 0.0) {
          planPercentages[cat] = percentage;
          totalPercentage += percentage;
        }
      }

      String selectedPlanCategory;
      if (planPercentages.isEmpty || totalPercentage == 0.0) {
        selectedPlanCategory = planCategories[random.nextInt(planCategories.length)];
      } else {
        final randomPlanValue = random.nextDouble() * totalPercentage;
        double cumulative = 0.0;
        selectedPlanCategory = planCategories.first;
        for (final entry in planPercentages.entries) {
          cumulative += entry.value;
          if (randomPlanValue <= cumulative) {
            selectedPlanCategory = entry.key;
            break;
          }
        }
      }

      final planToTopics = <String, List<String>>{
        'growth': ['growsucces', 'leadership', 'entrepreneurship'],
        'discipline': ['focdic', 'vispurp'],
        'confidence': ['confmind', 'resilience', 'womenemp'],
        'strategy': ['salebranding', 'wealthmoney'],
      };
      final topicsForPlan = planToTopics[selectedPlanCategory] ?? <String>[];
      final availableTopics = topicsForPlan.where((topic) {
        if (topic == 'womenemp' && !isFemale) return false;
        return true;
      }).toList();
      if (availableTopics.isEmpty) return availableQuotes;

      final selectedTopic = availableTopics[random.nextInt(availableTopics.length)];
      if (quotesTot.containsKey(selectedTopic)) {
        final quotes = quotesTot[selectedTopic]!;
        for (final raw in quotes) {
          if (raw is! Map) continue;
          final q = Map<String, dynamic>.from(raw);
          if (!premium && (q['isFree'] != true)) continue;
          final text = q[lang] ?? q['en'];
          if (text != null && text.isNotEmpty) {
            availableQuotes.add({
              'category': selectedTopic,
              'text': text,
              'signature': q['signature'] as String?,
              'bookTitle': q['bookTitle']?[lang] ?? q['bookTitle']?['en'],
              'url': q['url'],
              'topicSource': 'personalized_feed',
              'planCategory': q['personalized_plan'] as String?,
              'tone': q['tone'],
            });
          }
        }
      }
    } else if (topicId == 'favoritesquotes') {
      for (final fav in quotesGlobal) {
        availableQuotes.add({
          'category': fav.category ?? '',
          'text': fav.quote,
          'signature': fav.signature,
          'bookTitle': fav.bookTitle,
          'url': fav.url,
          'topicSource': 'favoritesquotes',
          'tone': null,
        });
      }
    } else {
      // Reuse generic multi-topic builder for single topic.
      final selectedTopics = <String>[topicId];
      return getAvailableQuotes(
        lang: lang,
        premium: premium,
        selectedTopics: selectedTopics,
        quotesGlobal: quotesGlobal,
      );
    }

    return availableQuotes;
  }

  Future<List<Map<String, dynamic>>> getAvailableQuotes({
    required String lang,
    required bool premium,
    required List<String> selectedTopics,
    required List<DayQuote> quotesGlobal,
  }) async {
    final availableQuotes = <Map<String, dynamic>>[];
    final prefs = await SharedPreferences.getInstance();
    final gender = prefs.getString('gender');
    final isFemale = gender == 'Female';

    for (final topicId in selectedTopics) {
      if (topicId == 'favoritesquotes') {
        for (final fav in quotesGlobal) {
          availableQuotes.add({
            'category': fav.category ?? '',
            'text': fav.quote,
            'signature': fav.signature,
            'bookTitle': fav.bookTitle,
            'url': fav.url,
            'topicSource': 'favoritesquotes',
          });
        }
        continue;
      }

      final entries = quotesTot.entries;
      for (final entry in entries) {
        final category = entry.key;
        if ((topicId == 'general' || topicId == 'no_mercy' || topicId == 'affirmative') &&
            category == 'womenemp' &&
            !isFemale) {
          continue;
        }
        if (topicId != 'general' &&
            topicId != 'businessic' &&
            topicId != 'frombook' &&
            topicId != 'no_mercy' &&
            topicId != 'affirmative' &&
            topicId != personalizedFeedTopicId &&
            category != topicId) {
          continue;
        }
        final quotes = entry.value;
        if (quotes is! Iterable) continue;
        for (final raw in quotes) {
          if (raw is! Map) continue;
          final q = Map<String, dynamic>.from(raw);

          if (topicId == 'businessic' && q['businessic'] != true) continue;
          if (topicId == 'frombook' && q['frombook'] != true) continue;
          if (topicId == 'no_mercy' && q['tone'] != 'no mercy') continue;
          if (topicId == 'affirmative' && q['tone'] != 'affirmative') continue;

          if (!premium && (q['isFree'] != true)) continue;
          final text = q[lang] ?? q['en'];
          if (text != null && text.isNotEmpty) {
            availableQuotes.add({
              'category': category,
              'text': text,
              'signature': q['signature'] as String?,
              'bookTitle': q['bookTitle']?[lang] ?? q['bookTitle']?['en'],
              'url': q['url'],
              'topicSource': topicId,
              'tone': q['tone'],
            });
          }
        }
      }
    }
    return availableQuotes;
  }

  Future<void> appendUniqueQuoteToHistory({
    required String lang,
    required List<String> selectedTopics,
    required List<DayQuote> quotesGlobal,
    required List<String> history,
    required List<Map<String, dynamic>> historyData,
  }) async {
    const maxAttempts = 10;
    Map<String, dynamic>? quoteData;
    String? newText;
    bool foundUnique = false;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      quoteData = await getRandomQuoteFromTopics(
        lang: lang,
        selectedTopics: selectedTopics,
        quotesGlobal: quotesGlobal,
      );
      final text = quoteData['text'] as String?;
      if (text == null || text.isEmpty) continue;
      if (!history.contains(text)) {
        newText = text;
        foundUnique = true;
        break;
      }
    }

    if (!foundUnique || newText == null || newText.isEmpty) {
      final premium = _ref.read(premiumProvider);
      final allQuotes = await getAvailableQuotes(
        lang: lang,
        premium: premium,
        selectedTopics: selectedTopics,
        quotesGlobal: quotesGlobal,
      );
      final all = allQuotes.map((q) => q['text'] as String).toList();
      if (all.isEmpty) return;
      final last = history.isNotEmpty ? history.last : null;
      final pool = (last == null || all.length == 1) ? all : all.where((q) => q != last).toList();
      pool.shuffle();
      newText = pool.first;
      quoteData = await findQuoteDataByText(
        text: newText,
        lang: lang,
        selectedTopics: selectedTopics,
        quotesGlobal: quotesGlobal,
      );
    }

    if (newText.isNotEmpty && quoteData != null) {
      history.add(newText);
      historyData.add(quoteData);
    }
  }

  Future<Map<String, dynamic>> findQuoteDataByText({
    required String text,
    required String lang,
    required List<String> selectedTopics,
    required List<DayQuote> quotesGlobal,
  }) async {
    final premium = _ref.read(premiumProvider);
    final availableQuotes = await getAvailableQuotes(
      lang: lang,
      premium: premium,
      selectedTopics: selectedTopics,
      quotesGlobal: quotesGlobal,
    );
    for (final q in availableQuotes) {
      if (q['text'] == text) return q;
    }
    return {'category': '', 'text': text};
  }
}
