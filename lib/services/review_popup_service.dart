import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ReviewPopupState {
  neverShown,      // Jamais affiché
  firstRefused,    // Premier "Maybe later"
  secondRefused,   // Deuxième "Maybe later"
  dontAskAgain,    // Ne plus demander
}

class ReviewPopupService {
  ReviewPopupService._();
  static final ReviewPopupService instance = ReviewPopupService._();

  // SharedPreferences keys
  static const String _keyActionCount = 'reviewPopupActionCount';
  static const String _keyState = 'reviewPopupState';
  static const String _keyLastRefusedDate = 'reviewPopupLastRefusedDate';
  static const String _keyLastShownDate = 'reviewPopupLastShownDate';
  static const String _keyLastAppOpenDate = 'reviewPopupLastAppOpenDate';
  static const String _keyHasRated = 'reviewHasRated';
  static const String _keyRatedDate = 'reviewRatedDate';

  // Seuils d'actions
  static const int _firstShowThreshold = 3;
  static const int _subsequentShowThreshold = 5;
  static const int _weekDelayDays = 7;

  /// Mark app open (call at startup)
  Future<void> markAppOpened() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    await prefs.setString(_keyLastAppOpenDate, _formatDate(today));
    
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📱 [ReviewPopup] App ouverte - Date: ${_formatDate(today)}");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
    await prefs.setInt(_keyActionCount, 0);
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("🔄 [ReviewPopup] Counter reset on startup (new day)");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }

  /// Increment the action counter
  Future<void> trackAction() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_keyActionCount) ?? 0;
    final newCount = currentCount + 1;
    await prefs.setInt(_keyActionCount, newCount);
    
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📊 [ReviewPopup] Action tracked - Counter: $newCount");
      
      // Show the current status and what is expected
      final status = await _getCurrentStatus(prefs, newCount);
      debugPrint("📍 [ReviewPopup] Statut: $status");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }
  
  /// Return the current status (in French) for debugging
  Future<String> _getCurrentStatus(SharedPreferences prefs, int actionCount) async {
    final stateStr = prefs.getString(_keyState) ?? 'never_shown';
    final state = _parseState(stateStr);
    final today = DateTime.now();
    // Check whether onboarding is finished
    final hasOnboard = prefs.getBool("hasOnboard") ?? false;
    if (!hasOnboard) {
      return "⏸️ En attente de la fin de l'onboarding";
    }
    
    // Check whether already shown today
    final lastShownDate = prefs.getString(_keyLastShownDate);
    if (lastShownDate == _formatDate(today)) {
      return "⏸️ Déjà affiché aujourd'hui - Attente du lendemain";
    }
    switch (state) {
      case ReviewPopupState.dontAskAgain:
        debugPrint("State : dontAskAgain");
        return "🚫 Ne plus demander (déjà refusé 2 fois ou accepté)";
        
      case ReviewPopupState.neverShown:
        debugPrint("State : neverShown");
        if (actionCount < _firstShowThreshold) {
          final remaining = _firstShowThreshold - actionCount;
          return "⏳ En attente des 3 premières actions ($remaining restantes)";
        } else {
          return "✅ Prêt à s'afficher (3 actions atteintes)";
        }
        
      case ReviewPopupState.firstRefused:
        debugPrint("State : firstRefused");
        final lastRefusedDateStr = prefs.getString(_keyLastRefusedDate);
        final lastAppOpenDateStr = prefs.getString(_keyLastAppOpenDate);
        
        if (lastRefusedDateStr != null && lastAppOpenDateStr != null) {
          final lastRefusedDate = _parseDate(lastRefusedDateStr);
          final lastAppOpenDate = _parseDate(lastAppOpenDateStr);
          
          // Check whether we're on the day of refusal
          if (_formatDate(lastAppOpenDate) == _formatDate(lastRefusedDate)) {
            return "⏸️ Même jour que le 1er refus - Attente du lendemain pour recommencer le comptage";
          }
          
          // Next day, count actions
          if (actionCount < _subsequentShowThreshold) {
            final remaining = _subsequentShowThreshold - actionCount;
            return "⏳ Jour suivant du 1er refus - En attente de 5 actions ($remaining restantes)";
          } else {
            return "✅ Jour suivant du 1er refus - Prêt à s'afficher (5 actions atteintes)";
          }
        }
        return "⏸️ Après 1er refus - En attente de la prochaine ouverture";
        
      case ReviewPopupState.secondRefused:
        debugPrint("State : secondRefused");
        final lastRefusedDateStr = prefs.getString(_keyLastRefusedDate);
        if (lastRefusedDateStr != null) {
          final lastRefusedDate = _parseDate(lastRefusedDateStr);
          final daysSinceRefusal = today.difference(lastRefusedDate).inDays;

          if (daysSinceRefusal < _weekDelayDays) {
            final remainingDays = _weekDelayDays - daysSinceRefusal;
            return "⏸️ Rappel hebdomadaire - En attente ($remainingDays jours restants)";
          } else {
            return "✅ Rappel hebdomadaire - Prêt à s'afficher";
          }
        }
        return "⏸️ Rappel hebdomadaire - Données manquantes";
    }
  }

  /// Check whether the popup should be shown
  /// Returns true if the popup should be shown, false otherwise
  Future<bool> shouldShowPopup({required bool isOnHomepage}) async {
    // Do not show if not on the homepage
    if (!isOnHomepage) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    // Do not show if onboarding is not finished
    final hasOnboard = prefs.getBool("hasOnboard") ?? false;
    if (!hasOnboard) {
      return false;
    }
    final stateStr = prefs.getString(_keyState) ?? 'never_shown';
    final state = _parseState(stateStr);

    // Don't ask again if already refused twice
    if (state == ReviewPopupState.dontAskAgain) {
      return false;
    }

    // Check whether already shown today
    final today = DateTime.now();
    final todayStr = _formatDate(today);
    final lastShownDate = prefs.getString(_keyLastShownDate);
    if (lastShownDate == todayStr) {
      // Already shown today, do not re-show
      return false;
    }

    final actionCount = prefs.getInt(_keyActionCount) ?? 0;

    // First display: after 3 actions
    if (state == ReviewPopupState.neverShown) {
      if (actionCount >= _firstShowThreshold) {
        if (kDebugMode) {
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          debugPrint("✅ [ReviewPopup] First display triggered (3 actions)");
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        }
        return true;
      }
      return false;
    }

    // After first refusal: on the next open, after 5 actions
    if (state == ReviewPopupState.firstRefused) {
      // Verify that we're indeed at the next app open
      final lastRefusedDateStr = prefs.getString(_keyLastRefusedDate);
      final lastAppOpenDateStr = prefs.getString(_keyLastAppOpenDate);
      
      if (lastRefusedDateStr != null && lastAppOpenDateStr != null) {
        final lastRefusedDate = _parseDate(lastRefusedDateStr);
        final lastAppOpenDate = _parseDate(lastAppOpenDateStr);
        
        // Only start counting from the next open (different day)
        if (lastAppOpenDate.isAfter(lastRefusedDate) || 
            _formatDate(lastAppOpenDate) != _formatDate(lastRefusedDate)) {
          // We're on the next open, check the action count
          if (actionCount >= _subsequentShowThreshold) {
            if (kDebugMode) {
              debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
              debugPrint("✅ [ReviewPopup] Second display triggered (5 actions after first refusal, next open)");
              debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            }
            return true;
          }
        } else {
          // Same day as refusal, don't count yet
          if (kDebugMode) {
            debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            debugPrint("⏸️ [ReviewPopup] Same day as refusal - Waiting for next open");
            debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          }
          return false;
        }
      }
      return false;
    }

    // Weekly reminder: every week until accepted
    if (state == ReviewPopupState.secondRefused) {
      final lastRefusedDateStr = prefs.getString(_keyLastRefusedDate);
      if (lastRefusedDateStr != null) {
        final lastRefusedDate = _parseDate(lastRefusedDateStr);
        final daysSinceRefusal = today.difference(lastRefusedDate).inDays;

        if (daysSinceRefusal >= _weekDelayDays) {
          if (kDebugMode) {
            debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            debugPrint("✅ [ReviewPopup] Weekly reminder triggered ($daysSinceRefusal days elapsed)");
            debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          }
          return true;
        }
      }
      return false;
    }

    return false;
  }

  /// Mark the popup as shown
  Future<void> onPopupShown() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    await prefs.setString(_keyLastShownDate, _formatDate(today));

  }

  /// Handle popup refusal
  Future<void> onPopupRefused() async {
    final prefs = await SharedPreferences.getInstance();
    final stateStr = prefs.getString(_keyState) ?? 'never_shown';
    final state = _parseState(stateStr);
    
    final today = DateTime.now();
    await prefs.setString(_keyLastRefusedDate, _formatDate(today));

    // Update the state
    ReviewPopupState newState;
    if (state == ReviewPopupState.neverShown) {
      newState = ReviewPopupState.firstRefused;
    } else if (state == ReviewPopupState.firstRefused) {
      newState = ReviewPopupState.secondRefused;
    } else {
      // Keep reminding every week until accepted
      newState = ReviewPopupState.secondRefused;
    }

    await prefs.setString(_keyState, _stateToString(newState));
    
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("❌ [ReviewPopup] Popup refused - State: ${_stateToString(newState)}");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }

  /// Handle popup acceptance (open the store)
  Future<void> onPopupAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    // Mark as "don't ask again" after acceptance
    await prefs.setString(_keyState, _stateToString(ReviewPopupState.dontAskAgain));

    // Record that the user clicked to rate (button or star)
    final today = DateTime.now();
    await prefs.setBool(_keyHasRated, true);
    await prefs.setString(_keyRatedDate, _formatDate(today));
    
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("⭐ [ReviewPopup] User clicked to rate - Date: ${_formatDate(today)}");
      debugPrint("✅ [ReviewPopup] Popup accepted - Don't ask again");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }

  /// Returns true if the user already clicked to rate (button or star)
  Future<bool> hasRated() async {
    final prefs = await SharedPreferences.getInstance();
    final rated = prefs.getBool(_keyHasRated) ?? false;
    if (kDebugMode) {
      final ratedDate = prefs.getString(_keyRatedDate);
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("🔍 [ReviewPopup] A déjà noté: $rated${ratedDate != null ? ' (le $ratedDate)' : ''}");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
    return rated;
  }

  // Helpers
  ReviewPopupState _parseState(String stateStr) {
    switch (stateStr) {
      case 'never_shown':
        return ReviewPopupState.neverShown;
      case 'first_refused':
        return ReviewPopupState.firstRefused;
      case 'second_refused':
        return ReviewPopupState.secondRefused;
      case 'dont_ask_again':
        return ReviewPopupState.dontAskAgain;
      default:
        return ReviewPopupState.neverShown;
    }
  }

  String _stateToString(ReviewPopupState state) {
    switch (state) {
      case ReviewPopupState.neverShown:
        return 'never_shown';
      case ReviewPopupState.firstRefused:
        return 'first_refused';
      case ReviewPopupState.secondRefused:
        return 'second_refused';
      case ReviewPopupState.dontAskAgain:
        return 'dont_ask_again';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}

