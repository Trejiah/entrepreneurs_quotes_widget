import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../providers/habits_provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../theme/themedatas.dart';

Future<void> saveOneToCloud(String cat, String key, dynamic value) async {
  final authUser = FirebaseAuth.instance.currentUser;
  if(authUser == null) return;
  final uid = authUser.uid;
  final databaseRef = FirebaseDatabase.instance.ref('users/$uid');
  try {
    if(cat == ""){
      await databaseRef.update({key : value});
    }else{

      await databaseRef.child(cat).update({key : value});
    }

    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📋 [SaveCloud] Firebase save successful");
      debugPrint("   - Category: $cat");
      debugPrint("   - Key: $key");
      debugPrint("   - Valeur: $value");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("❌ [SaveCloud] Firebase save error");
      debugPrint("   Message: $e");
      debugPrint("   Stack: $st");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }
}

/// Save only "open" points to Firebase
Future<void> saveOpenPointsToCloud() async {
  final authUser = FirebaseAuth.instance.currentUser;
  if (authUser == null) return;

  final prefs = await SharedPreferences.getInstance();
  final openAllPoints = prefs.getInt("openAllPoints") ?? 1;
  final openTodayPoints = prefs.getInt("openTodayPoints") ?? 0;
  final openWeekPoints = prefs.getInt("openWeekPoints") ?? 0;

  final uid = authUser.uid;
  final databaseRef = FirebaseDatabase.instance.ref('users/$uid/mindsetPoints');

  try {
    await databaseRef.update({
      "openAll": openAllPoints,
      "openToday": openTodayPoints,
      "openWeek": openWeekPoints,
    });

    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📋 [SaveCloud] Points 'open' sauvegardés sur Firebase");
      debugPrint("   - openAll: $openAllPoints");
      debugPrint("   - openToday: $openTodayPoints");
      debugPrint("   - openWeek: $openWeekPoints");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("❌ [SaveCloud] Erreur de sauvegarde des points 'open'");
      debugPrint("   Message: $e");
      debugPrint("   Stack: $st");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }
}

/// Save only "like" points to Firebase
Future<void> saveLikePointsToCloud() async {
  final authUser = FirebaseAuth.instance.currentUser;
  if (authUser == null) return;

  final prefs = await SharedPreferences.getInstance();
  final likeAllPoints = prefs.getInt("likeAllPoints") ?? 0;
  final likeTodayPoints = prefs.getInt("likeTodayPoints") ?? 0;
  final likeWeekPoints = prefs.getInt("likeWeekPoints") ?? 0;

  final uid = authUser.uid;
  final databaseRef = FirebaseDatabase.instance.ref('users/$uid/mindsetPoints');

  try {
    await databaseRef.update({
      "likeAll": likeAllPoints,
      "likeToday": likeTodayPoints,
      "likeWeek": likeWeekPoints,
    });

    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📋 [SaveCloud] Points 'like' sauvegardés sur Firebase");
      debugPrint("   - likeAll: $likeAllPoints");
      debugPrint("   - likeToday: $likeTodayPoints");
      debugPrint("   - likeWeek: $likeWeekPoints");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("❌ [SaveCloud] Erreur de sauvegarde des points 'like'");
      debugPrint("   Message: $e");
      debugPrint("   Stack: $st");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }
}

/// Save only "share" points to Firebase
Future<void> saveSharePointsToCloud() async {
  final authUser = FirebaseAuth.instance.currentUser;
  if (authUser == null) return;

  final prefs = await SharedPreferences.getInstance();
  final shareAllPoints = prefs.getInt("shareAllPoints") ?? 0;
  final shareTodayPoints = prefs.getInt("shareTodayPoints") ?? 0;
  final shareWeekPoints = prefs.getInt("shareWeekPoints") ?? 0;

  final uid = authUser.uid;
  final databaseRef = FirebaseDatabase.instance.ref('users/$uid/mindsetPoints');

  try {
    await databaseRef.update({
      "shareAll": shareAllPoints,
      "shareToday": shareTodayPoints,
      "shareWeek": shareWeekPoints,
    });

    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📋 [SaveCloud] Points 'share' sauvegardés sur Firebase");
      debugPrint("   - shareAll: $shareAllPoints");
      debugPrint("   - shareToday: $shareTodayPoints");
      debugPrint("   - shareWeek: $shareWeekPoints");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("❌ [SaveCloud] Erreur de sauvegarde des points 'share'");
      debugPrint("   Message: $e");
      debugPrint("   Stack: $st");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }
}

/// Save only all points (open, like, share) to Firebase
Future<void> saveAllPointsToCloud() async {
  final authUser = FirebaseAuth.instance.currentUser;
  if (authUser == null) return;

  final prefs = await SharedPreferences.getInstance();
  
  // Points open
  final openAllPoints = prefs.getInt("openAllPoints") ?? 1;
  final openTodayPoints = prefs.getInt("openTodayPoints") ?? 0;
  final openWeekPoints = prefs.getInt("openWeekPoints") ?? 0;
  
  // Points like
  final likeAllPoints = prefs.getInt("likeAllPoints") ?? 0;
  final likeTodayPoints = prefs.getInt("likeTodayPoints") ?? 0;
  final likeWeekPoints = prefs.getInt("likeWeekPoints") ?? 0;
  
  // Points share
  final shareAllPoints = prefs.getInt("shareAllPoints") ?? 0;
  final shareTodayPoints = prefs.getInt("shareTodayPoints") ?? 0;
  final shareWeekPoints = prefs.getInt("shareWeekPoints") ?? 0;

  final uid = authUser.uid;
  final databaseRef = FirebaseDatabase.instance.ref('users/$uid/mindsetPoints');

  try {
    await databaseRef.update({
      "openAll": openAllPoints,
      "openToday": openTodayPoints,
      "openWeek": openWeekPoints,
      "likeAll": likeAllPoints,
      "likeToday": likeTodayPoints,
      "likeWeek": likeWeekPoints,
      "shareAll": shareAllPoints,
      "shareToday": shareTodayPoints,
      "shareWeek": shareWeekPoints,
    });

    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📋 [SaveCloud] All points saved to Firebase");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("❌ [SaveCloud] Points save error");
      debugPrint("   Message: $e");
      debugPrint("   Stack: $st");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }
}

/// Save only totals (days, quotes) to Firebase
Future<void> saveTotalsToCloud() async {
  final authUser = FirebaseAuth.instance.currentUser;
  if (authUser == null) return;

  final prefs = await SharedPreferences.getInstance();
  final totDays = prefs.getInt("totDays") ?? 1;
  final todayTotQuotes = prefs.getInt("todayTotQuotes") ?? 1;
  final weekTotQuotes = prefs.getInt("weekTotQuotes") ?? 1;
  final allTotQuotes = prefs.getInt("allTotQuotes") ?? 1;

  final uid = authUser.uid;
  final databaseRef = FirebaseDatabase.instance.ref('users/$uid/totals');

  try {
    await databaseRef.update({
      "days": totDays,
      "todayQuotes": todayTotQuotes,
      "weekQuotes": weekTotQuotes,
      "allQuotes": allTotQuotes,
    });

    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📋 [SaveCloud] Totals saved to Firebase");
      debugPrint("   - days: $totDays");
      debugPrint("   - todayQuotes: $todayTotQuotes");
      debugPrint("   - weekQuotes: $weekTotQuotes");
      debugPrint("   - allQuotes: $allTotQuotes");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("❌ [SaveCloud] Totals save error");
      debugPrint("   Message: $e");
      debugPrint("   Stack: $st");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }
}

Future<void> saveAllCloud() async {
  final authUser = FirebaseAuth.instance.currentUser;
  if(authUser == null) return;


  final prefs = await SharedPreferences.getInstance();
  final userName = prefs.getString("userName") ?? "Nobody";//nom de l'utilisateur
  final language = prefs.getString("language") ?? "en";//langue de l'app
  final currentThemeIndex = prefs.getInt("themeIndex") ?? prefs.getInt("currentThemeIndex") ?? 0;//Theme choisi
  final isCustomTheme = prefs.getBool("isCustomTheme") ?? false;//Type de thème (custom ou app)
  // Defaults for non-premium: 3 notifications, 8am-6pm, every day
  final startHour = prefs.getInt("startHour") ?? 8;//heure de début des notif
  final startMinute = prefs.getInt("startMinute") ?? 0;//minutes de début des notif
  final endHour = prefs.getInt("endHour") ?? 18;//heure de fin des notif
  final endMinute = prefs.getInt("endMinute") ?? 0;//minutes de fin des notif
  final manyCount = prefs.getInt("manyCount") ?? 3;//nombre d'occurences dans la journée
  final daySelected = prefs.getStringList("daySelected") ?? [];//jours de notifications
  final openAllPoints = prefs.getInt("openAllPoints") ?? 1;//total Mindset Points open
  final likeAllPoints = prefs.getInt("likeAllPoints") ?? 0;//total Mindset Points like
  final shareAllPoints = prefs.getInt("shareAllPoints") ?? 0;//total Mindset Points share
  final openTodayPoints = prefs.getInt("openTodayPoints") ?? 0;//total Mindset Points open
  final likeTodayPoints = prefs.getInt("likeTodayPoints") ?? 0;//total Mindset Points like
  final shareTodayPoints = prefs.getInt("shareTodayPoints") ?? 0;//total Mindset Points share
  final openWeekPoints = prefs.getInt("openWeekPoints") ?? 0;//total Mindset Points open
  final likeWeekPoints = prefs.getInt("likeWeekPoints") ?? 0;//total Mindset Points like
  final shareWeekPoints = prefs.getInt("shareWeekPoints") ?? 0;//total Mindset Points share
  final totDays = prefs.getInt("totDays") ?? 1;//total jours de présence
  final todayTotQuotes = prefs.getInt("todayTotQuotes") ?? 1;//total quotes vues aujourd'hui
  final weekTotQuotes = prefs.getInt("weekTotQuotes") ?? 1;//total quotes vues semaines
  final allTotQuotes = prefs.getInt("allTotQuotes") ?? 1;//total quotes vues
  final history50 = prefs.getString("history50") ?? "";//json des 50 dernières citations vues avec date
  final favoris = prefs.getString("quotes/entries") ?? "";//json des favoris avec date
  final whereFound = prefs.getString("whereFound");//réponse à whereFound
  final age = prefs.getString("age");//réponse à age
  final gender = prefs.getString("gender");//réponse à gender
  final situation = prefs.getString("situation");//réponse à situation
  final mindset = prefs.getString("mindset");//réponse à mindset
  final goals = prefs.getString("goals");//réponse à goals
  // Data is saved with keys "focus" and "challenge" in onboarding14.dart
  // Load from "focus" and "challenge", with fallback on "mainfocus" and "bigchall" for compatibility
  final mainfocus = prefs.getStringList("focus") ?? prefs.getStringList("mainfocus") ?? [];//liste des main focus
  final bigchall = prefs.getStringList("challenge") ?? prefs.getStringList("bigchall") ?? [];//liste des bigchall
  final topics = prefs.getStringList("topics") ?? [];//liste des topics
  
  // Preferred tones
  final noMercyTone = prefs.getInt("tone_value_NO MERCY") ?? 0;
  final affirmationTone = prefs.getInt("tone_value_AFFIRMATION") ?? 0;
  
  // Personalized plan
  final growthPlan = prefs.getDouble("plan_growth_percentage") ?? 25.0;
  final disciplinePlan = prefs.getDouble("plan_discipline_percentage") ?? 25.0;
  final confidencePlan = prefs.getDouble("plan_confidence_percentage") ?? 25.0;
  final strategyPlan = prefs.getDouble("plan_strategy_percentage") ?? 25.0;

  final uid = authUser.uid;
  final databaseRef = FirebaseDatabase.instance.ref('users/$uid');

  try {
    final data = {
      "userName": userName,
      "language": language,
      "currentThemeIndex": currentThemeIndex,
      "themeIndex": currentThemeIndex,
      "isCustomTheme": isCustomTheme,
      "notif": {
        "startHour": startHour,
        "startMinute": startMinute,
        "endHour": endHour,
        "endMinute": endMinute,
        "manyCount": manyCount,
        "daySelected": daySelected,
      },
      "mindsetPoints": {
        "openAll": openAllPoints,
        "likeAll": likeAllPoints,
        "shareAll": shareAllPoints,
        "openToday": openTodayPoints,
        "likeToday": likeTodayPoints,
        "shareToday": shareTodayPoints,
        "openWeek": openWeekPoints,
        "likeWeek": likeWeekPoints,
        "shareWeek": shareWeekPoints,
      },
      "totals": {
        "days": totDays,
        "todayQuotes": todayTotQuotes,
        "weekQuotes": weekTotQuotes,
        "allQuotes": allTotQuotes,
      },
      "history50": history50,
      "favoris": favoris,
      "survey": {
        "whereFound": whereFound,
        "age": age,
        "gender": gender,
        "situation": situation,
        "mindset": mindset,
        "goals": goals,
        "focus": mainfocus,
        "challenge": bigchall,
        "topics": topics,
      },
      "tones": {
        "tone_value_NO MERCY": noMercyTone,
        "tone_value_AFFIRMATION": affirmationTone,
      },
      "personalized_plan": {
        "plan_growth_percentage": growthPlan,
        "plan_discipline_percentage": disciplinePlan,
        "plan_confidence_percentage": confidencePlan,
        "plan_strategy_percentage": strategyPlan,
      },
    };

    await databaseRef.update(data);
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📋 [SaveCloud] Full Firebase save successful");
      debugPrint("   - userName: $userName");
      debugPrint("   - language: $language");
      debugPrint("   - themeIndex: $currentThemeIndex");
      debugPrint("   - isCustomTheme: $isCustomTheme");
      debugPrint("   - habits: manyCount=$manyCount, startHour=$startHour, endHour=$endHour");
      debugPrint("   - daySelected: $daySelected");
      debugPrint("   - mindsetPoints: openAll=$openAllPoints, likeAll=$likeAllPoints, shareAll=$shareAllPoints");
      debugPrint("   - totals: days=$totDays, todayQuotes=$todayTotQuotes, weekQuotes=$weekTotQuotes, allQuotes=$allTotQuotes");
      debugPrint("   - tones: NO MERCY=$noMercyTone, AFFIRMATION=$affirmationTone");
      debugPrint("   - plan: growth=$growthPlan%, discipline=$disciplinePlan%, confidence=$confidencePlan%, strategy=$strategyPlan%");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("❌ [SaveCloud] Full Firebase save error");
      debugPrint("   Message: $e");
      debugPrint("   Stack: $st");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }
}

Future<void> loadAllCloud(WidgetRef ref) async {
  final authUser = FirebaseAuth.instance.currentUser;
  if (authUser == null) return;

  // Local helpers to cast cleanly
  int asInt(dynamic v, int def) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  double asDouble(dynamic v, double def) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? def;
    return def;
  }

  String asString(dynamic v, String def) {
    if (v is String) return v;
    if (v == null) return def;
    return v.toString();
  }

  List<String> asStrList(dynamic v) {
    if (v is List) {
      return v
          .map((e) => e?.toString() ?? "")
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  Map<String, dynamic> asMap(dynamic v) {
    if (v is Map) {
      return Map<String, dynamic>.from(v);
    }
    return <String, dynamic>{};
  }

  final uid = authUser.uid;
  final databaseRef = FirebaseDatabase.instance.ref('users/$uid');

  try {
    final snap = await databaseRef.get();
    if (!snap.exists) {
      return;
    }

    final root = asMap(snap.value);

    // Niveaux 1
    final userName      = asString(root["userName"], "Nobody");
    final currentThemeIndex  = asInt(root["themeIndex"] ?? root["currentThemeIndex"], 0);
    final isCustomTheme = root["isCustomTheme"] == true;

    // Sub-objects
    final notif         = asMap(root["notif"]);
    final points        = asMap(root["mindsetPoints"]);
    final totals        = asMap(root["totals"]);
    final survey        = asMap(root["survey"]);
    final tones         = asMap(root["tones"]);
    final personalizedPlan = asMap(root["personalized_plan"]);
    final language      = asString(root["language"], "en");

    // Notif
    final startHour     = asInt(notif["startHour"], 6);
    final startMinute   = asInt(notif["startMinute"], 0);
    final endHour       = asInt(notif["endHour"], 17);
    final endMinute     = asInt(notif["endMinute"], 0);
    final manyCount     = asInt(notif["manyCount"], 3);
    final daySelected   = asStrList(notif["daySelected"]);

    // Mindset points
    final openAllPoints   = asInt(points["openAll"], 1);
    final likeAllPoints   = asInt(points["likeAll"], 0);
    final shareAllPoints  = asInt(points["shareAll"], 0);
    final openTodayPoints = asInt(points["openToday"], 0);
    final likeTodayPoints = asInt(points["likeToday"], 0);
    final shareTodayPoints= asInt(points["shareToday"], 0);
    final openWeekPoints  = asInt(points["openWeek"], 0);
    final likeWeekPoints  = asInt(points["likeWeek"], 0);
    final shareWeekPoints = asInt(points["shareWeek"], 0);

    // Totaux
    final totDays        = asInt(totals["days"], 1);
    final todayTotQuotes = asInt(totals["todayQuotes"], 1);
    final weekTotQuotes  = asInt(totals["weekQuotes"], 1);
    final allTotQuotes   = asInt(totals["allQuotes"], 1);

    // Strings (JSON) stored flat
    final history50      = asString(root["history50"], "");
    final favoris        = asString(root["favoris"], "");

    // Survey
    final whereFound   = survey["whereFound"]; // peut être null
    final age          = survey["age"];
    final gender       = survey["gender"];
    final situation    = survey["situation"];
    final mindset      = survey["mindset"];
    final goals        = survey["goals"];
    // focus == mainfocus and challenge == bigchall
    // Load from "focus" and "challenge", with fallback on "mainfocus" and "bigchall" for compatibility
    final focusData = survey["focus"] ?? survey["mainfocus"];
    final challengeData = survey["challenge"] ?? survey["bigchall"];
    final mainfocus    = asStrList(focusData);
    final bigchall     = asStrList(challengeData);
    final topics       = asStrList(survey["topics"]);

    // Local write (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("userName", userName);
    await prefs.setInt("currentThemeIndex", currentThemeIndex);
    await prefs.setInt("themeIndex", currentThemeIndex);
    await prefs.setBool("isCustomTheme", isCustomTheme);
    await prefs.setString("language", language);

    final moToSu = daySelected
        .map((entry) {
          final normalized = entry.toLowerCase();
          return normalized == 'true' || normalized == '1' || normalized == 't' || normalized == 'y';
        })
        .toList();

    await ref.read(habitsStateProvider.notifier).setHabits(
      dayCount: manyCount,
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
      daySelectedMoToSu: moToSu,
    );

    // Also save to the legacy keys for compatibility
    await prefs.setInt("manyCount", manyCount);
    await prefs.setInt("howmany", manyCount); // Clé legacy
    await prefs.setStringList("daySelected", daySelected);

    await prefs.setInt("openAllPoints", openAllPoints);
    await prefs.setInt("likeAllPoints", likeAllPoints);
    await prefs.setInt("shareAllPoints", shareAllPoints);
    await prefs.setInt("openTodayPoints", openTodayPoints);
    await prefs.setInt("likeTodayPoints", likeTodayPoints);
    await prefs.setInt("shareTodayPoints", shareTodayPoints);
    await prefs.setInt("openWeekPoints", openWeekPoints);
    await prefs.setInt("likeWeekPoints", likeWeekPoints);
    await prefs.setInt("shareWeekPoints", shareWeekPoints);

    await prefs.setInt("totDays", totDays);
    await prefs.setInt("todayTotQuotes", todayTotQuotes);
    await prefs.setInt("weekTotQuotes", weekTotQuotes);
    await prefs.setInt("allTotQuotes", allTotQuotes);

    await prefs.setString("history50", history50);
    await prefs.setString("quotes/entries", favoris);

    // These fields can be null → only set if non-null
    if (whereFound != null) await prefs.setString("whereFound", asString(whereFound, ""));
    if (age != null)        await prefs.setString("age", asString(age, ""));
    if (gender != null)     await prefs.setString("gender", asString(gender, ""));
    if (situation != null) await prefs.setString("situation", asString(situation, ""));
    if (mindset != null)    await prefs.setString("mindset", asString(mindset, ""));
    if (goals != null)      await prefs.setString("goals", asString(goals, ""));

    // focus == mainfocus and challenge == bigchall
    await prefs.setStringList("focus", mainfocus);
    await prefs.setStringList("challenge", bigchall);
    await prefs.setStringList("topics", topics);
    
    // Load preferred tones
    final noMercyTone = tones["tone_value_NO MERCY"];
    final affirmationTone = tones["tone_value_AFFIRMATION"];
    if (noMercyTone != null) {
      await prefs.setInt("tone_value_NO MERCY", asInt(noMercyTone, 0));
    }
    if (affirmationTone != null) {
      await prefs.setInt("tone_value_AFFIRMATION", asInt(affirmationTone, 0));
    }
    
    // Load percentages of the personalized plan
    final growthPlan = personalizedPlan["plan_growth_percentage"];
    final disciplinePlan = personalizedPlan["plan_discipline_percentage"];
    final confidencePlan = personalizedPlan["plan_confidence_percentage"];
    final strategyPlan = personalizedPlan["plan_strategy_percentage"];
    
    if (growthPlan != null) {
      await prefs.setDouble("plan_growth_percentage", asDouble(growthPlan, 25.0));
    }
    if (disciplinePlan != null) {
      await prefs.setDouble("plan_discipline_percentage", asDouble(disciplinePlan, 25.0));
    }
    if (confidencePlan != null) {
      await prefs.setDouble("plan_confidence_percentage", asDouble(confidencePlan, 25.0));
    }
    if (strategyPlan != null) {
      await prefs.setDouble("plan_strategy_percentage", asDouble(strategyPlan, 25.0));
    }

    // ⚠️ Check whether the custom theme with image exists locally
    // If isCustomTheme is true but the theme doesn't exist or its image is missing,
    // reset to false and use the default theme
    bool finalIsCustomTheme = isCustomTheme;
    if (isCustomTheme) {
      final customThemes = ref.read(themeCustomListProvider);
      if (currentThemeIndex >= 0 && currentThemeIndex < customThemes.length) {
        final theme = customThemes[currentThemeIndex];
        final isImage = theme["isImage"] == true;
        final imageName = theme["imageName"] as String?;
        final hasImage = isImage && imageName != null && imageName.isNotEmpty;
        
        if (hasImage) {
          // Check whether the image exists locally
          final file = File(imageName);
          if (!file.existsSync()) {
            // Image doesn't exist → use default theme
            finalIsCustomTheme = false;
            if (kDebugMode) {
              debugPrint("⚠️ [SaveCloud] Custom theme with image not found locally");
              debugPrint("   - themeIndex: $currentThemeIndex");
              debugPrint("   - Image path: $imageName");
              debugPrint("   - isCustomTheme reset to false → using default theme");
            }
          }
        }
      } else {
        // Invalid index → use default theme
        finalIsCustomTheme = false;
        if (kDebugMode) {
          debugPrint("⚠️ [SaveCloud] Invalid custom theme index: $currentThemeIndex");
          debugPrint("   - isCustomTheme reset to false → using default theme");
        }
      }
    }

    // Update providers
    ref.read(userNameStateProvider.notifier).state = userName;
    ref.read(themeIndexProvider.notifier).setIndex(finalIsCustomTheme ? currentThemeIndex : 0);
    ref.read(isCustomThemeProvider.notifier).setValue(finalIsCustomTheme);
    ref.read(languageProvider.notifier).state = language;
    
    // Also save in SharedPreferences
    await prefs.setBool("isCustomTheme", finalIsCustomTheme);
    if (!finalIsCustomTheme) {
      await prefs.setInt("themeIndex", 0);
      await prefs.setInt("currentThemeIndex", 0);
    }

    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📋 [SaveCloud] Firebase → Local load successful");
      debugPrint("   - userName: $userName");
      debugPrint("   - language: $language");
      debugPrint("   - themeIndex: $currentThemeIndex");
      debugPrint("   - isCustomTheme: $isCustomTheme");
      debugPrint("   - habits: manyCount=$manyCount, startHour=$startHour, endHour=$endHour");
      debugPrint("   - daySelected: $daySelected");
      debugPrint("   - mindsetPoints: openAll=$openAllPoints, likeAll=$likeAllPoints, shareAll=$shareAllPoints");
      debugPrint("   - totals: days=$totDays, todayQuotes=$todayTotQuotes, weekQuotes=$weekTotQuotes, allQuotes=$allTotQuotes");
      debugPrint("   - survey: gender=$gender, age=$age, situation=$situation, mindset=$mindset, goals=$goals");
      debugPrint("   - mainfocus: $mainfocus");
      debugPrint("   - bigchall: $bigchall");
      debugPrint("   - topics: $topics");
      debugPrint("   - tones: NO MERCY=$noMercyTone, AFFIRMATION=$affirmationTone");
      debugPrint("   - plan: growth=$growthPlan%, discipline=$disciplinePlan%, confidence=$confidencePlan%, strategy=$strategyPlan%");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("❌ [SaveCloud] Error while loading Firebase → Local");
      debugPrint("   Message: $e");
      debugPrint("   Stack: $st");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }
}
