import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/favorite_management.dart';
import '../data/widget_frequency.dart';
import '../data/widget_buttons.dart';

const String widgetTopicsKey = 'widget/topics';
const String widgetFavoritesKey = 'widget/favorites';
const String widgetFrequencyKey = 'widget/updateFrequency';
const String widgetButtonsKey = 'widget/buttons';

Future<List<String>> loadWidgetTopics(SharedPreferences prefs) async {
  try {
    await prefs.reload();
  } catch (_) {
    // reload not supported on all platforms
  }
  return prefs.getStringList(widgetTopicsKey) ?? const ["general"];
}

Future<void> saveWidgetTopics(SharedPreferences prefs, List<String> topics) async {
  await prefs.setStringList(widgetTopicsKey, topics);
}

Future<List<DayQuote>> loadWidgetFavorites(SharedPreferences prefs) async {
  try {
    await prefs.reload();
  } catch (_) {
    // reload not supported on all platforms
  }
  final raw = prefs.getString(widgetFavoritesKey);
  if (raw == null || raw.isEmpty) return const [];
  final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
  return decoded
      .whereType<Map<String, dynamic>>()
      .map(DayQuote.fromJson)
      .toList(growable: false);
}

Future<void> saveWidgetFavorites(SharedPreferences prefs, List<DayQuote> entries) async {
  final encoded = jsonEncode(entries.map((e) => e.toJson()).toList(growable: false));
  await prefs.setString(widgetFavoritesKey, encoded);
}

Future<String> loadWidgetFrequency(SharedPreferences prefs) async {
  try {
    await prefs.reload();
  } catch (_) {}
  return prefs.getString(widgetFrequencyKey) ?? defaultWidgetFrequencyId;
}

Future<void> saveWidgetFrequency(SharedPreferences prefs, String frequencyId) async {
  await prefs.setString(widgetFrequencyKey, frequencyId);
}

Future<Set<String>> loadWidgetButtons(SharedPreferences prefs) async {
  try {
    await prefs.reload();
  } catch (_) {}
  final list = prefs.getStringList(widgetButtonsKey);
  if (list == null || list.isEmpty) {
    return {...defaultWidgetButtonSelection};
  }
  return list.toSet();
}

Future<void> saveWidgetButtons(SharedPreferences prefs, Set<String> buttonIds) async {
  await prefs.setStringList(widgetButtonsKey, buttonIds.toList());
}

