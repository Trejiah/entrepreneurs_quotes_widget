import 'package:flutter/foundation.dart';

import 'package:businessmindset/data/diagnostic_mapping.dart';

class PlanCategory {
  final String key;
  final String nameKey;
  final List<int> phraseIndices;
  int totPoints;
  double percentage;

  PlanCategory({
    required this.key,
    required this.nameKey,
    required this.phraseIndices,
    this.totPoints = 0,
    this.percentage = 0.0,
  });
}

void applyPhraseExclusions(List<PlanCategory> categories) {
  // Apply exclusions with priority orders
  // Indices are 0-indexed
  
  for (var cat in categories) {
    final phrasesToRemove = <int>[];
    
    if (cat.key == "growth") {
      // 0 exclut 5
      if (cat.phraseIndices.contains(0) && cat.phraseIndices.contains(5)) {
        phrasesToRemove.add(5);
        if (kDebugMode) debugPrint("🚫 [OnBoarding31] Growth: excluding phrase 6 (index 5) because phrase 1 (index 0) present");
      }
      // 1 exclut 3
      if (cat.phraseIndices.contains(1) && cat.phraseIndices.contains(3)) {
        phrasesToRemove.add(3);
        if (kDebugMode) debugPrint("🚫 [OnBoarding31] Growth: excluding phrase 4 (index 3) because phrase 2 (index 1) present");
      }
    }
    
    if (cat.key == "discipline") {
      // 0 exclut 3
      if (cat.phraseIndices.contains(0) && cat.phraseIndices.contains(3)) {
        phrasesToRemove.add(3);
        if (kDebugMode) debugPrint("🚫 [OnBoarding31] Discipline: excluding phrase 4 (index 3) because phrase 1 (index 0) present");
      }
      // 1 exclut 5
      if (cat.phraseIndices.contains(1) && cat.phraseIndices.contains(5)) {
        phrasesToRemove.add(5);
        if (kDebugMode) debugPrint("🚫 [OnBoarding31] Discipline: excluding phrase 6 (index 5) because phrase 2 (index 1) present");
      }
      
      // Priority order for 2, 4, 6: 2 > 4 > 6
      // If 2 is present → exclude 4 and 6
      if (cat.phraseIndices.contains(2)) {
        if (cat.phraseIndices.contains(4)) {
          phrasesToRemove.add(4);
          if (kDebugMode) debugPrint("🚫 [OnBoarding31] Discipline: excluding phrase 5 (index 4) because phrase 3 (index 2) present");
        }
        if (cat.phraseIndices.contains(6)) {
          phrasesToRemove.add(6);
          if (kDebugMode) debugPrint("🚫 [OnBoarding31] Discipline: excluding phrase 7 (index 6) because phrase 3 (index 2) present");
        }
      } else {
        // If 2 is not present but 4 and 6 are → keep only 4
        if (cat.phraseIndices.contains(4) && cat.phraseIndices.contains(6)) {
          phrasesToRemove.add(6);
          if (kDebugMode) debugPrint("🚫 [OnBoarding31] Discipline: excluding phrase 7 (index 6) because phrase 5 (index 4) present (priority 4 > 6)");
        }
        // If 2 and 4 are not present but 6 is → keep 6 (nothing to do)
      }
    }
    
    if (cat.key == "confidence") {
      // Priority order for 0, 3, 5: 0 > 3 > 5
      // If 0 is present → exclude 3 and 5
      if (cat.phraseIndices.contains(0)) {
        if (cat.phraseIndices.contains(3)) {
          phrasesToRemove.add(3);
          if (kDebugMode) debugPrint("🚫 [OnBoarding31] Confidence: excluding phrase 4 (index 3) because phrase 1 (index 0) present");
        }
        if (cat.phraseIndices.contains(5)) {
          phrasesToRemove.add(5);
          if (kDebugMode) debugPrint("🚫 [OnBoarding31] Confidence: excluding phrase 6 (index 5) because phrase 1 (index 0) present");
        }
      } else {
        // If 0 is not present but 3 and 5 are → keep only 3
        if (cat.phraseIndices.contains(3) && cat.phraseIndices.contains(5)) {
          phrasesToRemove.add(5);
          if (kDebugMode) debugPrint("🚫 [OnBoarding31] Confidence: excluding phrase 6 (index 5) because phrase 4 (index 3) present (priority 3 > 5)");
        }
        // If 0 and 3 are not present but 5 is → keep 5 (nothing to do)
      }
      
      // 1 exclut 6
      if (cat.phraseIndices.contains(1) && cat.phraseIndices.contains(6)) {
        phrasesToRemove.add(6);
        if (kDebugMode) debugPrint("🚫 [OnBoarding31] Confidence: excluding phrase 7 (index 6) because phrase 2 (index 1) present");
      }
    }
    
    if (cat.key == "strategy") {
      // 0 exclut 3
      if (cat.phraseIndices.contains(0) && cat.phraseIndices.contains(3)) {
        phrasesToRemove.add(3);
        if (kDebugMode) debugPrint("🚫 [OnBoarding31] Strategy: excluding phrase 4 (index 3) because phrase 1 (index 0) present");
      }
      
      // Priority order for 5, 2, 1: 5 > 2 > 1
      // If 5 is present → exclude 2 and 1
      if (cat.phraseIndices.contains(5)) {
        if (cat.phraseIndices.contains(2)) {
          phrasesToRemove.add(2);
          if (kDebugMode) debugPrint("🚫 [OnBoarding31] Strategy: excluding phrase 3 (index 2) because phrase 6 (index 5) present");
        }
        if (cat.phraseIndices.contains(1)) {
          phrasesToRemove.add(1);
          if (kDebugMode) debugPrint("🚫 [OnBoarding31] Strategy: excluding phrase 2 (index 1) because phrase 6 (index 5) present");
        }
      } else {
        // If 5 is not present but 2 and 1 are → keep only 2
        if (cat.phraseIndices.contains(2) && cat.phraseIndices.contains(1)) {
          phrasesToRemove.add(1);
          if (kDebugMode) debugPrint("🚫 [OnBoarding31] Strategy: excluding phrase 2 (index 1) because phrase 3 (index 2) present (priority 2 > 1)");
        }
        // If 5 and 2 are not present but 1 is → keep 1 (nothing to do)
      }
    }
    
    cat.phraseIndices.removeWhere((p) => phrasesToRemove.contains(p));
    
    if (kDebugMode && phrasesToRemove.isNotEmpty) {
      debugPrint("🗑️ [OnBoarding31] Phrases removed from ${cat.key}: $phrasesToRemove");
      debugPrint("📝 [OnBoarding31] Phrases finales de ${cat.key}: ${cat.phraseIndices}");
    }
  }
}

void addDefaultPhrasesForEmptyPlanCategories(List<PlanCategory> categories) {
  // Default phrases for empty categories (index in the phrase array)
  // These phrases will be added if a category has no phrase after all steps
  // Indices correspond to existing phrases in DiagnosticPhrases:
  // - growth: index 5 = "You're driven by progress and long-term achievement."
  // - discipline: index 6 = "You value focus and structure — pillars of long-term growth."
  // - confidence: index 5 = "You're committed to strengthening your mindset and grounding your confidence."
  // - strategy: index 2 = "You're working toward long-term stability and financial independence."
  const Map<String, int> defaultPhraseIndices = {
    'growth': 5,
    'discipline': 6,
    'confidence': 5,
    'strategy': 2,
  };
  
  for (var cat in categories) {
    if (cat.phraseIndices.isEmpty) {
      final defaultIndex = defaultPhraseIndices[cat.key];
      if (defaultIndex != null) {
        cat.phraseIndices.add(defaultIndex);
        if (kDebugMode) {
          debugPrint("📝 [OnBoarding31] Category ${cat.key} empty → default phrase added (index $defaultIndex)");
        }
      }
    }
  }
}

void calculatePlanCategoryPercentages(List<PlanCategory> categories) {
  if (kDebugMode) {
    debugPrint("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    debugPrint("📊 [OnBoarding31] PERCENTAGE COMPUTATION:");
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  }
  
  // Compute the total points
  int totalPoints = categories.fold(0, (sum, cat) => sum + cat.totPoints);
  
  if (kDebugMode) {
    debugPrint("  Total points: $totalPoints");
    debugPrint("\n  Points per category:");
    for (var cat in categories) {
      debugPrint("    • ${cat.key}: ${cat.totPoints} points");
    }
  }
  
  if (totalPoints == 0) {
    // If no points, split evenly
    if (kDebugMode) {
      debugPrint("\n  ⚠️  No total points, even split at 25% per category");
    }
    for (var cat in categories) {
      cat.percentage = 25.0;
    }
    return;
  }
  
  // Compute initial percentages
  if (kDebugMode) {
    debugPrint("\n  📐 Computing initial percentages:");
  }
  for (var cat in categories) {
    final initialPercentage = (cat.totPoints / totalPoints) * 100.0;
    cat.percentage = initialPercentage;
    if (kDebugMode) {
      debugPrint("    • ${cat.key}: ${cat.totPoints} / $totalPoints = ${initialPercentage.toStringAsFixed(2)}%");
    }
  }
  
  // Make sure each category has at least 10%
  final categoriesBelow10 = categories.where((c) => c.percentage < 10.0).toList();
  
  if (categoriesBelow10.isNotEmpty) {
    if (kDebugMode) {
      debugPrint("\n  ⚠️  Categories below 10%:");
      for (var cat in categoriesBelow10) {
        debugPrint("    • ${cat.key}: ${cat.percentage.toStringAsFixed(2)}%");
      }
    }
    
    double totalToRedistribute = 0.0;
    
    // Compute how much to add to reach 10%
    for (var cat in categoriesBelow10) {
      final needed = 10.0 - cat.percentage;
      totalToRedistribute += needed;
      cat.percentage = 10.0;
      if (kDebugMode) {
        debugPrint("    • ${cat.key}: ${cat.percentage.toStringAsFixed(2)}% → 10.00% (+${needed.toStringAsFixed(2)}%)");
      }
    }
    
    if (kDebugMode) {
      debugPrint("\n  📉 Total to redistribute: ${totalToRedistribute.toStringAsFixed(2)}%");
    }
    
    // Redistribute evenly from the other categories
    final categoriesAbove10 = categories.where((c) => c.percentage > 10.0).toList();
    
    if (categoriesAbove10.isNotEmpty) {
      // Reduce proportionally to maintain relative proportions
      double totalAbove10 = categoriesAbove10.fold(0.0, (sum, cat) => sum + cat.percentage);
      double ratio = (totalAbove10 - totalToRedistribute) / totalAbove10;
      
      if (kDebugMode) {
        debugPrint("  📊 Total of categories > 10%: ${totalAbove10.toStringAsFixed(2)}%");
        debugPrint("  📊 Reduction ratio: ${ratio.toStringAsFixed(4)}");
        debugPrint("  Adjusted categories:");
      }
      
      for (var cat in categoriesAbove10) {
        final before = cat.percentage;
        cat.percentage = (cat.percentage * ratio).clamp(10.0, 100.0);
        if (kDebugMode) {
          debugPrint("    • ${cat.key}: ${before.toStringAsFixed(2)}% → ${cat.percentage.toStringAsFixed(2)}%");
        }
      }
    }
    
    // Normalize so the sum is exactly 100%
    // Use an iterative approach to guarantee a minimum of 10%
    double currentSum = categories.fold(0.0, (sum, cat) => sum + cat.percentage);
    if (kDebugMode) {
      debugPrint("\n  🔄 Normalisation (somme actuelle: ${currentSum.toStringAsFixed(2)}%)");
    }
    
    if ((currentSum - 100.0).abs() > 0.01) {
      double difference = 100.0 - currentSum;
      
      // Redistribute the difference only among categories that can absorb it
      // (those above 10% or at 10% if the difference is positive)
      List<PlanCategory> adjustableCategories;
      if (difference > 0) {
        // We can increase all categories
        adjustableCategories = categories;
      } else {
        // We can only reduce those > 10%
        adjustableCategories = categories.where((c) => c.percentage > 10.0).toList();
      }
      
      if (adjustableCategories.isNotEmpty) {
        double adjustmentPerCategory = difference / adjustableCategories.length;
        
        if (kDebugMode) {
          debugPrint("  Ajustement total: ${difference.toStringAsFixed(2)}%");
          debugPrint("  Adjustment per adjustable category: ${adjustmentPerCategory.toStringAsFixed(2)}%");
          debugPrint("  Adjustable categories: ${adjustableCategories.length}");
        }
        
        for (var cat in adjustableCategories) {
          final before = cat.percentage;
          cat.percentage = (cat.percentage + adjustmentPerCategory).clamp(10.0, 100.0);
          if (kDebugMode) {
            debugPrint("    • ${cat.key}: ${before.toStringAsFixed(2)}% → ${cat.percentage.toStringAsFixed(2)}%");
          }
        }
        
        // Check again and adjust if needed (case where some categories reached 10% or 100%)
        double newSum = categories.fold(0.0, (sum, cat) => sum + cat.percentage);
        double remainingDifference = 100.0 - newSum;
        
        if ((remainingDifference.abs() > 0.01) && adjustableCategories.length > 1) {
          // Redistribute the remaining difference among categories that can still move
          List<PlanCategory> stillAdjustable = adjustableCategories.where((c) {
            if (remainingDifference > 0) {
              return c.percentage < 100.0;
            } else {
              return c.percentage > 10.0;
            }
          }).toList();
          
          if (stillAdjustable.isNotEmpty) {
            double finalAdjustment = remainingDifference / stillAdjustable.length;
            for (var cat in stillAdjustable) {
              cat.percentage = (cat.percentage + finalAdjustment).clamp(10.0, 100.0);
            }
          }
        }
      }
      
      // Check the final sum
      double finalSum = categories.fold(0.0, (sum, cat) => sum + cat.percentage);
      if (kDebugMode) {
        debugPrint("  ✅ Somme finale: ${finalSum.toStringAsFixed(2)}%");
        debugPrint("  📊 Pourcentages finaux:");
        for (var cat in categories) {
          debugPrint("    • ${cat.key}: ${cat.percentage.toStringAsFixed(2)}%");
        }
      }
    } else {
      if (kDebugMode) {
        debugPrint("  ✅ Sum already at 100%, no normalization needed");
      }
    }
  } else {
    if (kDebugMode) {
      debugPrint("\n  ✅ Toutes les catégories sont au-dessus de 10%, pas d'ajustement nécessaire");
    }
  }
}

/// Recompute plan categories from onboarding answers (prefs-loaded map).
/// Returns `null` when [answers] is null (caller should keep previous UI state).
List<PlanCategory>? rebuildOnboardingPlanCategories(Map<String, dynamic>? answers) {
  if (answers == null) {
    if (kDebugMode) {
      debugPrint('❌ [OnboardingDiagnostic] No answer available');
    }
    return null;
  }

  if (kDebugMode) {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🔍 [OnboardingDiagnostic] DIAGNOSTIC COMPUTATION START');
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('\n📦 [OnboardingDiagnostic] ANSWER CONTENT:');
    debugPrint('───────────────────────────────────────────────────────────');
    for (var entry in answers.entries) {
      if (entry.value == null) {
        debugPrint('  ${entry.key}: null');
      } else if (entry.value is List) {
        debugPrint('  ${entry.key}: [${(entry.value as List).join(", ")}]');
      } else {
        debugPrint('  ${entry.key}: ${entry.value}');
      }
    }
    debugPrint('───────────────────────────────────────────────────────────\n');
  }

  final mapping = DiagnosticMapping.getMapping();

  final categories = <PlanCategory>[
    PlanCategory(key: 'growth', nameKey: 'plan_category_growth', phraseIndices: []),
    PlanCategory(key: 'discipline', nameKey: 'plan_category_discipline', phraseIndices: []),
    PlanCategory(key: 'confidence', nameKey: 'plan_category_confidence', phraseIndices: []),
    PlanCategory(key: 'strategy', nameKey: 'plan_category_strategy', phraseIndices: []),
  ];

  if (kDebugMode) {
    debugPrint('📊 [OnboardingDiagnostic] CATEGORY INITIALIZATION:');
    for (var cat in categories) {
      debugPrint('  ${cat.key}: 0 points, 0 phrases');
    }
    debugPrint('\n');
  }

  for (var questionKey in ['situation', 'improvement', 'focus', 'challenge', 'topics']) {
    final questionData = mapping[questionKey];
    if (questionData == null) {
      if (kDebugMode) {
        debugPrint('⚠️ [OnboardingDiagnostic] No mapping for question: $questionKey');
      }
      continue;
    }

    final answersList = answers[questionKey];
    if (answersList == null || (answersList is List && answersList.isEmpty)) {
      if (kDebugMode) {
        debugPrint('⏭️  [OnboardingDiagnostic] No answer for: $questionKey');
      }
      continue;
    }

    final List<String> answersToProcess;
    if (questionKey == 'situation') {
      final situationValue = answersList as String?;
      answersToProcess =
          (situationValue != null && situationValue.isNotEmpty) ? [situationValue] : <String>[];
    } else {
      answersToProcess = (answersList as List).cast<String>();
    }

    if (kDebugMode && answersToProcess.isNotEmpty) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📝 [OnboardingDiagnostic] TRAITEMENT DE: $questionKey');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    for (var answer in answersToProcess) {
      final answerData = questionData[answer];
      if (answerData == null) {
        if (kDebugMode) debugPrint('  ⚠️  No mapping for: $answer');
        continue;
      }

      final category = answerData['category'] as String;
      final phraseIndex = answerData['phraseIndex'] as int;
      final points = answerData['points'] as Map<String, dynamic>;

      if (kDebugMode) {
        debugPrint('\n  ✅ Answer: $answer');
        debugPrint('     → Category: $category');
        debugPrint('     → Phrase index: $phraseIndex');
        debugPrint('     → Points assigned:');
        for (var pointEntry in points.entries) {
          final pointValue = (pointEntry.value as num?)?.toInt() ?? 0;
          debugPrint('        • ${pointEntry.key}: +$pointValue');
        }
      }

      final pointsBefore = <String, int>{};
      for (var cat in categories) {
        pointsBefore[cat.key] = cat.totPoints;
        final pointsForCat = (points[cat.key] as num).toInt();
        cat.totPoints += pointsForCat;
      }

      if (kDebugMode) {
        debugPrint('     → Points after addition:');
        for (var cat in categories) {
          final added = cat.totPoints - pointsBefore[cat.key]!;
          if (added > 0) {
            debugPrint(
                '        • ${cat.key}: ${pointsBefore[cat.key]} → ${cat.totPoints} (+$added)');
          }
        }
      }

      final categoryObj = categories.firstWhere((c) => c.key == category);
      final phraseAlreadyExists = categoryObj.phraseIndices.contains(phraseIndex);
      if (!phraseAlreadyExists) {
        categoryObj.phraseIndices.add(phraseIndex);
        if (kDebugMode) {
          debugPrint('     → Phrase $phraseIndex added to category $category');
          debugPrint('     → Phrases de $category: ${categoryObj.phraseIndices}');
        }
      } else if (kDebugMode) {
        debugPrint('     → Phrase $phraseIndex already present in $category');
      }
    }
  }

  if (kDebugMode) {
    debugPrint('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📊 [OnboardingDiagnostic] POINTS AVANT EXCLUSIONS:');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    var totalBefore = 0;
    for (var cat in categories) {
      totalBefore += cat.totPoints;
      debugPrint('  ${cat.key}: ${cat.totPoints} points, phrases: ${cat.phraseIndices}');
    }
    debugPrint('  TOTAL: $totalBefore points\n');
  }

  applyPhraseExclusions(categories);
  addDefaultPhrasesForEmptyPlanCategories(categories);

  if (kDebugMode) {
    debugPrint('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📊 [OnboardingDiagnostic] POINTS AFTER EXCLUSIONS:');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    var totalAfter = 0;
    for (var cat in categories) {
      totalAfter += cat.totPoints;
      debugPrint('  ${cat.key}: ${cat.totPoints} points, phrases: ${cat.phraseIndices}');
    }
    debugPrint('  TOTAL: $totalAfter points\n');
  }

  calculatePlanCategoryPercentages(categories);

  if (kDebugMode) {
    debugPrint('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📊 [OnboardingDiagnostic] FINAL RESULTS:');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    var totalFinal = 0;
    var totalPercentage = 0.0;
    for (var cat in categories) {
      totalFinal += cat.totPoints;
      totalPercentage += cat.percentage;
      debugPrint('  ${cat.key}:');
      debugPrint('    • Points: ${cat.totPoints}');
      debugPrint('    • Pourcentage: ${cat.percentage.toStringAsFixed(2)}%');
      debugPrint(
          '    • Phrases: ${cat.phraseIndices.isEmpty ? "aucune" : cat.phraseIndices.join(", ")}');
    }
    debugPrint('\n  TOTAL:');
    debugPrint('    • Points: $totalFinal');
    debugPrint('    • Pourcentage: ${totalPercentage.toStringAsFixed(2)}%');
    debugPrint('═══════════════════════════════════════════════════════════\n');
  }

  return categories;
}
