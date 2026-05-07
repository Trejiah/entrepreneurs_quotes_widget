import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/save_cloud.dart';
import '../providers/widget_preferences.dart';
import '../services/widget_subscription_sync.dart';

const _kQuotesKey = "quotes/entries";
const MethodChannel _widgetBridgeChannel = MethodChannel('businessmindset/deeplink');

/// Représente une ligne de sauvegarde
class DayQuote {
  final int day;
  final String month; // traduit
  final int year;
  final String quote;
  final String? category;
  final String? signature;
  final String? bookTitle;
  final String? url;

  const DayQuote({
    required this.day,
    required this.month,
    required this.year,
    required this.quote,
    this.category,
    this.signature,
    this.bookTitle,
    this.url,
  });

  Map<String, dynamic> toJson() => {
        "day": day,
        "month": month,
        "year": year,
        "quote": quote,
        if (category != null) "category": category,
        if (signature != null) "signature": signature,
        if (bookTitle != null) "bookTitle": bookTitle,
        if (url != null) "url": url,
      };

  factory DayQuote.fromJson(Map<String, dynamic> j) => DayQuote(
        day: (j["day"] as num).toInt(),
        month: j["month"] as String,
        year: (j["year"] as num).toInt(),
        quote: j["quote"] as String,
        category: j["category"] as String?,
        signature: j["signature"] as String?,
        bookTitle: j["bookTitle"] as String?,
        url: j["url"] as String?,
      );
}

/// --- Utils ---

final Map<String, List<String>> monthNames = {
  "en": [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ],
  "fr": [
    "Janvier",
    "Février",
    "Mars",
    "Avril",
    "Mai",
    "Juin",
    "Juillet",
    "Août",
    "Septembre",
    "Octobre",
    "Novembre",
    "Décembre",
  ],
};

Future<List<DayQuote>> loadAllFavorite() async {
  final prefs = await SharedPreferences.getInstance();
  await _syncFavoritesFromWidget(prefs);
  return _decodeFavorites(prefs.getString(_kQuotesKey));
}

Future<List<DayQuote>> loadAllHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString("history50");
  if (raw == null || raw.isEmpty) return [];
  final list = (jsonDecode(raw) as List)
      .whereType<Map<String, dynamic>>()
      .map((e) => DayQuote.fromJson(e))
      .toList();
  return list;
}

Future<void> saveAllHistory(List<DayQuote> entries) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    "history50",
    jsonEncode(entries.map((e) => e.toJson()).toList()),
  );
  saveOneToCloud("","history50",jsonEncode(entries.map((e) => e.toJson()).toList()));
}

Future<void> saveAllFavorite(List<DayQuote> entries) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kQuotesKey,
    jsonEncode(entries.map((e) => e.toJson()).toList()),
  );
  await saveWidgetFavorites(prefs, entries);
  await _notifyWidgetFavoritesChanged(prefs, entries);
  saveOneToCloud("","favoris",jsonEncode(entries.map((e) => e.toJson()).toList()));
}

Future<void> _syncFavoritesFromWidget(SharedPreferences prefs) async {
  List<dynamic>? rawList;
  try {
    rawList = await _widgetBridgeChannel.invokeMethod<List<dynamic>>('getWidgetFavorites');
  } on MissingPluginException {
    // Platform bridge not available (e.g., Android) -> nothing to sync
    return;
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Failed to request widget favorites: $error');
      debugPrint('$stackTrace');
    }
    return;
  }

  if (rawList == null) {
    return;
  }

  final widgetFavorites = rawList
      .map((entry) {
        if (entry is Map) {
          final map = <String, dynamic>{};
          entry.forEach((key, value) {
            if (key is String) {
              map[key] = value;
            }
          });
          if (map["quote"] is String) {
            return DayQuote.fromJson(map);
          }
        }
        return null;
      })
      .whereType<DayQuote>()
      .toList();

  final localFavorites = _decodeFavorites(prefs.getString(_kQuotesKey));
  if (_favoritesEqual(widgetFavorites, localFavorites)) {
    return;
  }

  final encoded = jsonEncode(widgetFavorites.map((e) => e.toJson()).toList());
  await prefs.setString(_kQuotesKey, encoded);
  await saveWidgetFavorites(prefs, widgetFavorites);
  saveOneToCloud("", "favoris", encoded);

  if (kDebugMode) {
    debugPrint('Synchronized ${widgetFavorites.length} favorites from widget.');
  }
}

List<DayQuote> _decodeFavorites(String? raw) {
  if (raw == null || raw.isEmpty) {
    return [];
  }

  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .map((entry) {
            if (entry is Map<String, dynamic>) {
              return DayQuote.fromJson(entry);
            }
            if (entry is Map) {
              final map = <String, dynamic>{};
              entry.forEach((key, value) {
                if (key is String) {
                  map[key] = value;
                }
              });
              if (map.isNotEmpty) {
                return DayQuote.fromJson(map);
              }
            }
            return null;
          })
          .whereType<DayQuote>()
          .toList();
    }
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Failed to decode favorites payload: $error');
      debugPrint('$stackTrace');
    }
  }

  return [];
}

bool _favoritesEqual(List<DayQuote> a, List<DayQuote> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;

  final signaturesA = a.map((e) => jsonEncode(e.toJson())).toList()..sort();
  final signaturesB = b.map((e) => jsonEncode(e.toJson())).toList()..sort();
  return listEquals(signaturesA, signaturesB);
}

Future<void> _notifyWidgetFavoritesChanged(SharedPreferences prefs, List<DayQuote> entries) async {
  final favoritesPayload = entries.map((e) => e.toJson()).toList(growable: false);
  try {
    final topics = await loadWidgetTopics(prefs);
    final frequency = await loadWidgetFrequency(prefs);
    final buttons = await loadWidgetButtons(prefs);
    final lang = prefs.getString("language") ?? "en";
    final args = {
      "configured": prefs.getBool("widgetConfigured") ?? false,
      "themeIndex": prefs.getInt("widgetThemeIndex") ?? 0,
      "topics": topics,
      "favorites": favoritesPayload,
      "frequency": frequency,
      "buttons": buttons.toList(growable: false),
      "language": lang,
      "premiumExpirationEpochMs": await fetchWidgetPremiumExpirationEpochMs(),
    };
    await _widgetBridgeChannel.invokeMethod("updateWidgetData", args);
    if (kDebugMode) {
      debugPrint("Notified widget about favorites update (${favoritesPayload.length} items).");
    }
  } on MissingPluginException {
    // Platform non pris en charge (Android, tests) : ignorer silencieusement.
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint("Failed to notify widget about favorites update: $error");
      debugPrint('$stackTrace');
    }
  }
}