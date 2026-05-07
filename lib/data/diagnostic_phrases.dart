// Diagnostic phrases by category
// Indices correspond to numbers in the PDF
// Use the translate function for translation

import '../core/app_localizations.dart';

class DiagnosticPhrases {
  // Translation keys for each phrase per category
  static const List<String> growthPhraseKeys = [
    'diagnostic_growth_0', // 0
    'diagnostic_growth_1', // 1
    'diagnostic_growth_2', // 2
    'diagnostic_growth_3', // 3
    'diagnostic_growth_4', // 4
    'diagnostic_growth_5', // 5 - aussi utilisé comme phrase par défaut si catégorie vide
    'diagnostic_growth_6', // 6
    'diagnostic_growth_7', // 7
  ];

  static const List<String> disciplinePhraseKeys = [
    'diagnostic_discipline_0', // 0
    'diagnostic_discipline_1', // 1
    'diagnostic_discipline_2', // 2
    'diagnostic_discipline_3', // 3
    'diagnostic_discipline_4', // 4
    'diagnostic_discipline_5', // 5
    'diagnostic_discipline_6', // 6 - aussi utilisé comme phrase par défaut si catégorie vide
  ];

  static const List<String> confidencePhraseKeys = [
    'diagnostic_confidence_0', // 0
    'diagnostic_confidence_1', // 1
    'diagnostic_confidence_2', // 2
    'diagnostic_confidence_3', // 3
    'diagnostic_confidence_4', // 4
    'diagnostic_confidence_5', // 5 - aussi utilisé comme phrase par défaut si catégorie vide
    'diagnostic_confidence_6', // 6
    'diagnostic_confidence_7', // 7
  ];

  static const List<String> strategyPhraseKeys = [
    'diagnostic_strategy_0', // 0
    'diagnostic_strategy_1', // 1
    'diagnostic_strategy_2', // 2 - aussi utilisé comme phrase par défaut si catégorie vide
    'diagnostic_strategy_3', // 3
    'diagnostic_strategy_4', // 4
    'diagnostic_strategy_5', // 5
  ];

  static List<String> getPhrasesForCategory(String category, String lang) {
    List<String> phraseKeys;
    switch (category) {
      case 'growth':
        phraseKeys = List.from(growthPhraseKeys);
        break;
      case 'discipline':
        phraseKeys = List.from(disciplinePhraseKeys);
        break;
      case 'confidence':
        phraseKeys = List.from(confidencePhraseKeys);
        break;
      case 'strategy':
        phraseKeys = List.from(strategyPhraseKeys);
        break;
      default:
        return [];
    }
    
    // Translate each phrase
    return phraseKeys.map((key) => translate(key, lang)).toList();
  }
}

