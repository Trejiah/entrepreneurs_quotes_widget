import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/save_cloud.dart';

class MindsetPointsService {
  MindsetPointsService._();

  static final MindsetPointsService instance = MindsetPointsService._();

  bool _saveEnabled = true; // Flag pour activer/désactiver la sauvegarde automatique (conservé pour compatibilité)

  // Stream to notify "+1" animations
  final StreamController<String> _incrementController = StreamController<String>.broadcast();
  Stream<String> get onIncrement => _incrementController.stream;
  
  // Enables auto-save
  void enableSave() {
    _saveEnabled = true;
    if (kDebugMode) {
      debugPrint("▶️ [MindsetPointsService] Auto-save enabled");
    }
  }
  
  // Disable auto-save (useful during Firebase data loading)
  void disableSave() {
    _saveEnabled = false;
    if (kDebugMode) {
      debugPrint("⏸️ [MindsetPointsService] Auto-save disabled");
    }
  }
  
  // Minimum delay between two "open" increments (in seconds) - 30 minutes
  static const int _minOpenIncrementDelay = 300;

  // Determine whether the week starts on Sunday (US) or Monday
  bool _isUSLocale() {
    final locale = PlatformDispatcher.instance.locale;
    return locale.countryCode == 'US';
  }

  // Compute the start of the current week
  DateTime _getWeekStart(DateTime date) {
    final isUS = _isUSLocale();
    final weekday = date.weekday; // 1 = lundi, 7 = dimanche
    
    if (isUS) {
      // Week starts on Sunday
      // weekday = 7 (Sunday) -> 0 days to subtract
      // weekday = 1 (Monday) -> 1 day to subtract
      // weekday = 6 (Saturday) -> 6 days to subtract
      final daysFromSunday = weekday == 7 ? 0 : weekday;
      return date.subtract(Duration(days: daysFromSunday));
    } else {
      // Week starts on Monday
      // weekday = 1 (Monday) -> 0 days to subtract
      // weekday = 2 (Tuesday) -> 1 day to subtract
      // weekday = 7 (Sunday) -> 6 days to subtract
      final daysFromMonday = weekday - 1;
      return date.subtract(Duration(days: daysFromMonday));
    }
  }

  // Check whether it's a new day
  Future<bool> _isNewDay(SharedPreferences prefs) async {
    final now = DateTime.now();
    final todayStr = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    
    final lastOpenDate = prefs.getString('lastOpenDate');
    
    // ⚠️ IMPORTANT: If lastOpenDate is null, initialize it but do NOT treat it as
    // that it's a new day (to avoid resetting counters if the app
    // is restarted the same day after a kill)
    if (lastOpenDate == null) {
      // Initialize lastOpenDate to today but return false
      // to avoid resetting the counters
      await prefs.setString('lastOpenDate', todayStr);
      return false;
    }
    
    if (lastOpenDate != todayStr) {
      // It really is a new day
      await prefs.setString('lastOpenDate', todayStr);
      return true;
    }
    
    // Same day
    return false;
  }

  // Check whether it's a new week
  Future<bool> _isNewWeek(SharedPreferences prefs) async {
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);
    final weekStartStr = '${weekStart.year.toString().padLeft(4, '0')}-'
        '${weekStart.month.toString().padLeft(2, '0')}-'
        '${weekStart.day.toString().padLeft(2, '0')}';
    
    final lastWeekStart = prefs.getString('lastOpenWeekStart');
    
    // ⚠️ IMPORTANT: If lastOpenWeekStart is null, initialize it but do NOT treat it as
    // that it's a new week (to avoid resetting counters if the app
    // is restarted the same week after a kill)
    if (lastWeekStart == null) {
      // Initialize lastOpenWeekStart to this week but return false
      // to avoid resetting the counters
      await prefs.setString('lastOpenWeekStart', weekStartStr);
      return false;
    }
    
    if (lastWeekStart != weekStartStr) {
      // It really is a new week
      await prefs.setString('lastOpenWeekStart', weekStartStr);
      return true;
    }
    
    // Same week
    return false;
  }

  // Reset daily counters
  Future<void> _resetDayCounters(SharedPreferences prefs) async {
    await prefs.setInt('openTodayPoints', 0);
    await prefs.setInt('likeTodayPoints', 0);
    await prefs.setInt('shareTodayPoints', 0);
    await prefs.setInt('todayTotQuotes', 0);
  }

  // Reset weekly counters
  Future<void> _resetWeekCounters(SharedPreferences prefs) async {
    await prefs.setInt('openWeekPoints', 0);
    await prefs.setInt('likeWeekPoints', 0);
    await prefs.setInt('shareWeekPoints', 0);
    await prefs.setInt('weekTotQuotes', 0);
  }

  // Initialize day/week resets (call at app launch only)
  Future<void> initializeDayWeekResets() async {
    final prefs = await SharedPreferences.getInstance();
    
    // If onboarding was just completed, don't reset the counters
    // and make sure AllPoints values are copied to TodayPoints and WeekPoints
    final justCompletedOnboarding = prefs.getBool("justCompletedOnboarding") ?? false;
    if (justCompletedOnboarding) {
      // Copy AllPoints values to TodayPoints and WeekPoints to ensure they are synced
      final openAllPoints = prefs.getInt('openAllPoints') ?? 1;
      final likeAllPoints = prefs.getInt('likeAllPoints') ?? 0;
      final shareAllPoints = prefs.getInt('shareAllPoints') ?? 0;
      
      // Copier vers TodayPoints
      await prefs.setInt('openTodayPoints', openAllPoints);
      await prefs.setInt('likeTodayPoints', likeAllPoints);
      await prefs.setInt('shareTodayPoints', shareAllPoints);
      
      // Copier vers WeekPoints
      await prefs.setInt('openWeekPoints', openAllPoints);
      await prefs.setInt('likeWeekPoints', likeAllPoints);
      await prefs.setInt('shareWeekPoints', shareAllPoints);
      
      // Remove the flag for next opens
      await prefs.setBool("justCompletedOnboarding", false);
      
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("📋 [MindsetPointsService] Onboarding finished, syncing counters");
        debugPrint("   - openAllPoints: $openAllPoints -> copied to Today/Week");
        debugPrint("   - likeAllPoints: $likeAllPoints -> copied to Today/Week");
        debugPrint("   - shareAllPoints: $shareAllPoints -> copied to Today/Week");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
      
      // Save synced points to Firebase
      await saveAllPointsToCloud();
      
      return;
    }
    
    final isNewDay = await _isNewDay(prefs);
    final isNewWeek = await _isNewWeek(prefs);
    
    if (isNewDay) {
      await _resetDayCounters(prefs);
      
      // Increment totDays only once per day
      final totDays = (prefs.getInt('totDays') ?? 0) + 1;
      await prefs.setInt('totDays', totDays);
    }
    
    if (isNewWeek) {
      await _resetWeekCounters(prefs);
    }
    
    // Save if any resets were performed
    // Save only points and totals (not all data)
    if (isNewDay || isNewWeek) {
      await saveAllPointsToCloud();
      await saveTotalsToCloud();
    }
  }

  // Note: _scheduleSave() and _saveImmediately() were removed
  // because they called saveAllCloud() which overwrote all data.
  // Now each increment method only saves
  // the data it modifies (saveOpenPointsToCloud, saveLikePointsToCloud, etc.)

  // Increment open points
  Future<void> incrementOpen() async {
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("increment open !");
    }
    final prefs = await SharedPreferences.getInstance();
    
    // Increment counters (without reset; resets happen at app launch)
    final openAllPoints = (prefs.getInt('openAllPoints') ?? 0) + 1;
    final openTodayPoints = (prefs.getInt('openTodayPoints') ?? 0) + 1;
    final openWeekPoints = (prefs.getInt('openWeekPoints') ?? 0) + 1;
    if (kDebugMode) {
      debugPrint("nouvelle valeur de openTodayPoints : $openTodayPoints");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
    await prefs.setInt('openAllPoints', openAllPoints);
    await prefs.setInt('openTodayPoints', openTodayPoints);
    await prefs.setInt('openWeekPoints', openWeekPoints);
    
    // Save the timestamp of the last open increment
    await prefs.setInt('lastOpenIncrementTimestamp', DateTime.now().millisecondsSinceEpoch);
    
    // Save ONLY "open" points to Firebase (not all data)
    await saveOpenPointsToCloud();
    
    // Notifier l'animation
    _incrementController.add('open');
  }
  
  // Mark that the app went to the background (home screen)
  Future<void> markAppWentToBackground() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('appWentToBackgroundTimestamp', DateTime.now().millisecondsSinceEpoch);
    
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📱 [MindsetPointsService] App went to background");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }
  
  // Mark that the app was killed
  Future<void> markAppKilled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('appKilledTimestamp', DateTime.now().millisecondsSinceEpoch);
    
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📱 [MindsetPointsService] App killed - Timestamp saved");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }
  
  // Increment open points on return from background (with time limit)
  // Only if the app was actually in the background (home screen)
  Future<void> incrementOpenOnResume() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Verify that the app was actually in the background
    final backgroundTimestamp = prefs.getInt('appWentToBackgroundTimestamp');
    if (backgroundTimestamp == null) {
      // The app wasn't in the background (we're returning from another in-app page)
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("📱 [MindsetPointsService] App resumed (mais pas depuis l'arrière-plan)");
        debugPrint("   ⏭️ Pas d'incrément (navigation interne à l'app)");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
      return;
    }
    
    // Reset the timestamp (the app is now in the foreground)
    await prefs.remove('appWentToBackgroundTimestamp');
    
    final lastIncrement = prefs.getInt('lastOpenIncrementTimestamp') ?? 0;
    final elapsedSeconds = (now - lastIncrement) ~/ 1000;
    final backgroundDurationSeconds = (now - backgroundTimestamp) ~/ 1000;
    
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📱 [MindsetPointsService] App resumed depuis l'arrière-plan");
      debugPrint("   - Background time: ${backgroundDurationSeconds}s");
      debugPrint("   - Time since last open increment: ${elapsedSeconds}s");
      debugPrint("   - Minimum required delay: ${_minOpenIncrementDelay}s");
    }
    
    // If more than 5 minutes elapsed since last increment, increment
    if (elapsedSeconds >= _minOpenIncrementDelay) {
      if (kDebugMode) {
        debugPrint("   ✅ Open increment allowed");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
      await incrementOpen();
    } else {
      if (kDebugMode) {
        final remainingSeconds = _minOpenIncrementDelay - elapsedSeconds;
        debugPrint("   ⏳ Open increment blocked (wait ${remainingSeconds}s more)");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
    }
  }
  
  // Increment open points on app startup (with time limit)
  // Only if more than 300 seconds have elapsed since the app kill
  // or since the last increment (if the kill wasn't detected)
  Future<void> incrementOpenOnStartup() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Check whether the app was previously killed
    final killedTimestamp = prefs.getInt('appKilledTimestamp');
    final lastIncrement = prefs.getInt('lastOpenIncrementTimestamp') ?? 0;
    
    if (killedTimestamp == null) {
      // No kill timestamp saved (first open or kill not detected)
      // Check the time elapsed since the last increment
      final elapsedSinceLastIncrementSeconds = (now - lastIncrement) ~/ 1000;
      
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("📱 [MindsetPointsService] App started (no kill timestamp)");
        debugPrint("   - Time since last open increment: ${elapsedSinceLastIncrementSeconds}s");
        debugPrint("   - Minimum required delay: ${_minOpenIncrementDelay}s");
      }
      
      // If it's the first open (no last increment) or more than 300s have elapsed
      if (lastIncrement == 0 || elapsedSinceLastIncrementSeconds >= _minOpenIncrementDelay) {
        if (kDebugMode) {
          if (lastIncrement == 0) {
            debugPrint("   ✅ Open increment allowed (first open)");
          } else {
            debugPrint("   ✅ Open increment allowed (more than ${_minOpenIncrementDelay}s elapsed)");
          }
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        }
        await incrementOpen();
      } else {
        if (kDebugMode) {
          final remainingSeconds = _minOpenIncrementDelay - elapsedSinceLastIncrementSeconds;
          debugPrint("   ⏳ Open increment blocked (wait ${remainingSeconds}s more)");
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        }
      }
      return;
    }
    
    // Reset the timestamp (the app is now started)
    await prefs.remove('appKilledTimestamp');
    
    final elapsedSinceKillSeconds = (now - killedTimestamp) ~/ 1000;
    final elapsedSinceLastIncrementSeconds = (now - lastIncrement) ~/ 1000;
    
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📱 [MindsetPointsService] App started after kill");
      debugPrint("   - Time since kill: ${elapsedSinceKillSeconds}s");
      debugPrint("   - Time since last open increment: ${elapsedSinceLastIncrementSeconds}s");
      debugPrint("   - Minimum required delay: ${_minOpenIncrementDelay}s");
    }
    
    // If more than 300 seconds elapsed since kill AND since last increment, increment
    if (elapsedSinceKillSeconds >= _minOpenIncrementDelay && elapsedSinceLastIncrementSeconds >= _minOpenIncrementDelay) {
      if (kDebugMode) {
        debugPrint("   ✅ Open increment allowed");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
      await incrementOpen();
    } else {
      if (kDebugMode) {
        final remainingSeconds = _minOpenIncrementDelay - (elapsedSinceKillSeconds > elapsedSinceLastIncrementSeconds ? elapsedSinceKillSeconds : elapsedSinceLastIncrementSeconds);
        debugPrint("   ⏳ Open increment blocked (wait ${remainingSeconds}s more)");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
    }
  }

  // Increment like points
  Future<void> incrementLike() async {
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("increment like !");
    }
    final prefs = await SharedPreferences.getInstance();
    
    // Increment counters (without reset; resets happen at app launch)
    final likeAllPoints = (prefs.getInt('likeAllPoints') ?? 0) + 1;
    final likeTodayPoints = (prefs.getInt('likeTodayPoints') ?? 0) + 1;
    final likeWeekPoints = (prefs.getInt('likeWeekPoints') ?? 0) + 1;

    if (kDebugMode) {
      debugPrint("nouvelle valeur de likeTodayPoints : $likeTodayPoints");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
    await prefs.setInt('likeAllPoints', likeAllPoints);
    await prefs.setInt('likeTodayPoints', likeTodayPoints);
    await prefs.setInt('likeWeekPoints', likeWeekPoints);
    
    // Save ONLY "like" points to Firebase (not all data)
    await saveLikePointsToCloud();
    
    // Notifier l'animation
    _incrementController.add('like');
  }

  // Increment share points
  Future<void> incrementShare() async {
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("increment share !");
    }
    final prefs = await SharedPreferences.getInstance();
    
    // Increment counters (without reset; resets happen at app launch)
    final shareAllPoints = (prefs.getInt('shareAllPoints') ?? 0) + 1;
    final shareTodayPoints = (prefs.getInt('shareTodayPoints') ?? 0) + 1;
    final shareWeekPoints = (prefs.getInt('shareWeekPoints') ?? 0) + 1;

    if (kDebugMode) {
      debugPrint("nouvelle valeur de shareTodayPoints : $shareTodayPoints");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
    await prefs.setInt('shareAllPoints', shareAllPoints);
    await prefs.setInt('shareTodayPoints', shareTodayPoints);
    await prefs.setInt('shareWeekPoints', shareWeekPoints);
    
    // Save ONLY "share" points to Firebase (not all data)
    await saveSharePointsToCloud();
    
    // Notifier l'animation
    _incrementController.add('share');
  }

  // Increment quote counter (only for new quotes)
  Future<void> incrementQuote() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Increment counters (without reset; resets happen at app launch)
    final allTotQuotes = (prefs.getInt('allTotQuotes') ?? 1) + 1;
    final todayTotQuotes = (prefs.getInt('todayTotQuotes') ?? 1) + 1;
    final weekTotQuotes = (prefs.getInt('weekTotQuotes') ?? 1) + 1;
    
    await prefs.setInt('allTotQuotes', allTotQuotes);
    await prefs.setInt('todayTotQuotes', todayTotQuotes);
    await prefs.setInt('weekTotQuotes', weekTotQuotes);
    
    // Save ONLY totals to Firebase (not all data)
    await saveTotalsToCloud();
    
    // No "+1" animation for quotes (only save points)
  }

  // Methods to retrieve the current values
  Future<Map<String, int>> getAllValues() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'openAllPoints': prefs.getInt('openAllPoints') ?? 1,
      'likeAllPoints': prefs.getInt('likeAllPoints') ?? 0,
      'shareAllPoints': prefs.getInt('shareAllPoints') ?? 0,
      'openTodayPoints': prefs.getInt('openTodayPoints') ?? 1,
      'likeTodayPoints': prefs.getInt('likeTodayPoints') ?? 0,
      'shareTodayPoints': prefs.getInt('shareTodayPoints') ?? 0,
      'openWeekPoints': prefs.getInt('openWeekPoints') ?? 1,
      'likeWeekPoints': prefs.getInt('likeWeekPoints') ?? 0,
      'shareWeekPoints': prefs.getInt('shareWeekPoints') ?? 0,
      'totDays': prefs.getInt('totDays') ?? 1,
      'todayTotQuotes': prefs.getInt('todayTotQuotes') ?? 1,
      'weekTotQuotes': prefs.getInt('weekTotQuotes') ?? 1,
      'allTotQuotes': prefs.getInt('allTotQuotes') ?? 1,
    };
  }

  void dispose() {
    _incrementController.close();
  }
}

