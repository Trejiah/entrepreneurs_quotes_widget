// Mapping of onboarding answers to phrases and points
// Based on the PDF "Calcul diagnostic App Business Mindset"

class DiagnosticMapping {
  // Structure for an answer
  static Map<String, Map<String, dynamic>> getMapping() {
    return {
      // Situation professionnelle
      "situation": {
        "Employee": {
          "phraseIndex": 0,
          "category": "discipline",
          "points": {"growth": 1, "discipline": 1, "confidence": 0, "strategy": 0}
        },
        "Entrepreneur": {
          "phraseIndex": 0,
          "category": "strategy",
          "points": {"growth": 2, "discipline": 1, "confidence": 1, "strategy": 2}
        },
        "Leader": {
          "phraseIndex": 0,
          "category": "growth",
          "points": {"growth": 2, "discipline": 0, "confidence": 2, "strategy": 1}
        },
        "Looking2": {
          "phraseIndex": 0,
          "category": "confidence",
          "points": {"growth": 1, "discipline": 1, "confidence": 2, "strategy": 0}
        },
        "Looking": {
          "phraseIndex": 0,
          "category": "strategy",
          "points": {"growth": 2, "discipline": 0, "confidence": 1, "strategy": 2}
        },
        "Student": {
          "phraseIndex": 0,
          "category": "growth",
          "points": {"growth": 2, "discipline": 2, "confidence": 1, "strategy": 0}
        },
      },
      // Improvement needed
      "improvement": {
        "myconsistency": {
          "phraseIndex": 0,
          "category": "discipline",
          "points": {"growth": 0, "discipline": 5, "confidence": 2, "strategy": 0}
        },
        "myfocus": {
          "phraseIndex": 1,
          "category": "discipline",
          "points": {"growth": 2, "discipline": 5, "confidence": 0, "strategy": 0}
        },
        "myambition": {
          "phraseIndex": 0,
          "category": "growth",
          "points": {"growth": 5, "discipline": 2, "confidence": 0, "strategy": 3}
        },
        "myconfidence": {
          "phraseIndex": 0,
          "category": "confidence",
          "points": {"growth": 0, "discipline": 0, "confidence": 5, "strategy": 0}
        },
        "mygoals": {
          "phraseIndex": 1,
          "category": "growth",
          "points": {"growth": 0, "discipline": 3, "confidence": 3, "strategy": 3}
        },
      },
      // Focus principal
      "focus": {
        "startingbus": {
          "phraseIndex": 0,
          "category": "strategy",
          "points": {"growth": 2, "discipline": 0, "confidence": 0, "strategy": 2}
        },
        "saclingrev": {
          "phraseIndex": 1,
          "category": "strategy",
          "points": {"growth": 1, "discipline": 0, "confidence": 0, "strategy": 3}
        },
        "improvprod": {
          "phraseIndex": 2,
          "category": "discipline",
          "points": {"growth": 1, "discipline": 3, "confidence": 0, "strategy": 0}
        },
        "finfree": {
          "phraseIndex": 2,
          "category": "strategy",
          "points": {"growth": 0, "discipline": 0, "confidence": 1, "strategy": 3}
        },
        "betlead": {
          "phraseIndex": 1,
          "category": "confidence",
          "points": {"growth": 2, "discipline": 0, "confidence": 2, "strategy": 0}
        },
        "preprol": {
          "phraseIndex": 2,
          "category": "growth",
          "points": {"growth": 2, "discipline": 0, "confidence": 2, "strategy": 0}
        },
      },
      // Main challenge
      "challenge": {
        "staycons": {
          "phraseIndex": 3,
          "category": "discipline",
          "points": {"growth": 0, "discipline": 3, "confidence": 1, "strategy": 0}
        },
        "presdeal": {
          "phraseIndex": 2,
          "category": "confidence",
          "points": {"growth": 0, "discipline": 3, "confidence": 1, "strategy": 0}
        },
        "mantim": {
          "phraseIndex": 4,
          "category": "discipline",
          "points": {"growth": 0, "discipline": 3, "confidence": 0, "strategy": 1}
        },
        "keepfoc": {
          "phraseIndex": 5,
          "category": "discipline",
          "points": {"growth": 1, "discipline": 3, "confidence": 0, "strategy": 0}
        },
        "doubt": {
          "phraseIndex": 3,
          "category": "confidence",
          "points": {"growth": 1, "discipline": 0, "confidence": 3, "strategy": 0}
        },
        "motivd": {
          "phraseIndex": 4,
          "category": "confidence",
          "points": {"growth": 0, "discipline": 2, "confidence": 2, "strategy": 0}
        },
      },
      // Selected topics
      "topics": {
        "confmind": {
          "phraseIndex": 5,
          "category": "confidence",
          "points": {"growth": 1, "discipline": 0, "confidence": 3, "strategy": 0}
        },
        "focdic": {
          "phraseIndex": 6,
          "category": "discipline",
          "points": {"growth": 0, "discipline": 3, "confidence": 0, "strategy": 0}
        },
        "resilience": {
          "phraseIndex": 6,
          "category": "confidence",
          "points": {"growth": 0, "discipline": 3, "confidence": 0, "strategy": 0}
        },
        "vispurp": {
          "phraseIndex": 3,
          "category": "growth",
          "points": {"growth": 3, "discipline": 0, "confidence": 1, "strategy": 0}
        },
        "entrepreneurship": {
          "phraseIndex": 3,
          "category": "strategy",
          "points": {"growth": 2, "discipline": 0, "confidence": 0, "strategy": 2}
        },
        "leadership": {
          "phraseIndex": 4,
          "category": "growth",
          "points": {"growth": 2, "discipline": 0, "confidence": 2, "strategy": 0}
        },
        "salebranding": {
          "phraseIndex": 4,
          "category": "strategy",
          "points": {"growth": 1, "discipline": 0, "confidence": 0, "strategy": 3}
        },
        "growsucces": {
          "phraseIndex": 5,
          "category": "growth",
          "points": {"growth": 3, "discipline": 0, "confidence": 0, "strategy": 0}
        },
        "wealthmoney": {
          "phraseIndex": 5,
          "category": "strategy",
          "points": {"growth": 0, "discipline": 0, "confidence": 0, "strategy": 3}
        },
        "womenemp": {
          "phraseIndex": 7,
          "category": "confidence",
          "points": {"growth": 0, "discipline": 0, "confidence": 2, "strategy": 0}
        },
        "businessic": {
          "phraseIndex": 6,
          "category": "growth",
          "points": {"growth": 2, "discipline": 0, "confidence": 0, "strategy": 1}
        },
        "frombook": {
          "phraseIndex": 7,
          "category": "growth",
          "points": {"growth": 2, "discipline": 1, "confidence": 0, "strategy": 0}
        },
      },
    };
  }

  // Exclusions: phrases that cannot coexist
  // Format: {category: {phraseIndex1: [phraseIndex2, phraseIndex3], ...}}
  // NOTE: The full logic with priority orders is implemented in onboarding31.dart
  // 
  // Simple rules (direct exclusions):
  // - Growth: 0 exclut 5, 1 exclut 3
  // - Discipline: 0 exclut 3, 1 exclut 5
  // - Confidence: 0 excludes 3 and 5, 1 excludes 6
  // - Strategy: 0 excludes 3, 5 excludes 2 and 1
  //
  // Priority orders (handled in onboarding31.dart):
  // - Discipline (2, 4, 6): 2 > 4 > 6
  //   → If 2 present: exclude 4 and 6
  //   → If 2 absent but 4 and 6 present: keep only 4
  //   → If 2 and 4 absent but 6 present: keep 6
  // - Confidence (0, 3, 5): 0 > 3 > 5
  //   → If 0 present: exclude 3 and 5
  //   → If 0 absent but 3 and 5 present: keep only 3
  //   → If 0 and 3 absent but 5 present: keep 5
  // - Strategy (5, 2, 1): 5 > 2 > 1
  //   → If 5 present: exclude 2 and 1
  //   → If 5 absent but 2 and 1 present: keep only 2
  //   → If 5 and 2 absent but 1 present: keep 1
  static Map<String, Map<int, List<int>>> getExclusions() {
    return {
      "growth": {
        0: [5], // Si phrase 0 (Growth), exclure phrase 5 (Growth)
        1: [3], // Si phrase 1 (Growth), exclure phrase 3 (Growth)
      },
      "discipline": {
        0: [3], // Si phrase 0 (Discipline), exclure phrase 3 (Discipline)
        1: [5], // Si phrase 1 (Discipline), exclure phrase 5 (Discipline)
        // Note: 2, 4, 6 handled with priority order in onboarding31.dart
      },
      "confidence": {
        0: [3, 5], // Si phrase 0 (Confidence), exclure phrases 3 et 5 (Confidence)
        1: [6], // Si phrase 1 (Confidence), exclure phrase 6 (Confidence)
        // Note: 0, 3, 5 handled with priority order in onboarding31.dart
      },
      "strategy": {
        0: [3], // Si phrase 0 (Strategy), exclure phrase 3 (Strategy)
        // Note: 5, 2, 1 handled with priority order in onboarding31.dart
      },
    };
  }
  
  // Special exclusion rules (priorities)
  // Format: {category: {setOfPhrases: [phrasesToKeep], ...}}
  static Map<String, Map<String, List<int>>> getPriorityRules() {
    return {
      "discipline": {
        "2,5,6": [2, 5, 6], // Si 2, 5, 6 présents -> garder tous
      },
      "confidence": {
        "0,3,5": [0, 3, 5], // Si 0, 3, 5 présents -> garder tous
      },
      "strategy": {
        "1,2,5": [5, 2, 1], // Si 1, 2, 5 présents -> priorité 5, 2, 1
      },
    };
  }
}

