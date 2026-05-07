// habits_providers.dart
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _two(int n) => n.toString().padLeft(2, '0');

const _dayCountKey = 'habits/howmany';
const _dayCountLegacyKey = 'howmany';

const _startHourKey = 'habits/startHour';
const _startHourLegacyKey = 'startHour';

const _startMinuteKey = 'habits/startMinute';
const _startMinuteLegacyKey = 'startMinute';

const _endHourKey = 'habits/endHour';
const _endHourLegacyKey = 'endHour';

const _endMinuteKey = 'habits/endMinute';
const _endMinuteLegacyKey = 'endMinute';

const _daySelectedKey = 'habits/daySelected';
const _daySelectedLegacyKey = 'daySelected';

int _readInt(SharedPreferences prefs, String key, int fallback, {String? legacyKey}) {
  final value = prefs.getInt(key);
  if (value != null) return value;
  if (legacyKey != null) {
    final legacyValue = prefs.getInt(legacyKey);
    if (legacyValue != null) return legacyValue;
  }
  return fallback;
}

List<String>? _readStringList(SharedPreferences prefs, String key, {String? legacyKey}) {
  final value = prefs.getStringList(key);
  if (value != null) return value;
  if (legacyKey != null) return prefs.getStringList(legacyKey);
  return null;
}

List<bool> _normalizeBoolList(List<bool> values, {bool fillValue = true}) {
  final list = List<bool>.from(values);
  if (list.length < 7) {
    list.addAll(List<bool>.filled(7 - list.length, fillValue));
  } else if (list.length > 7) {
    list.removeRange(7, list.length);
  }
  return list;
}

List<bool> _parseBoolList(List<String>? raw) {
  if (raw == null || raw.isEmpty) {
    return List<bool>.filled(7, true);
  }
  final parsed = raw.map((entry) {
    final normalized = entry.toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 't' || normalized == 'y';
  }).toList();
  return _normalizeBoolList(parsed);
}

int _clamp(int value, int min, int max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

class HabitsState {
  final int dayCount;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final UnmodifiableListView<bool> daySelectedMoToSu;

  HabitsState({
    required this.dayCount,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required List<bool> daySelectedMoToSu,
  }) : daySelectedMoToSu = UnmodifiableListView<bool>(List<bool>.from(daySelectedMoToSu));

  factory HabitsState.defaults() => HabitsState(
        dayCount: 3, // Valeur par défaut pour non-premium
        startHour: 8,
        startMinute: 0,
        endHour: 18, // 18h au lieu de 17h
        endMinute: 0,
        daySelectedMoToSu: const [true, true, true, true, true, true, true],
      );

  HabitsState copyWith({
    int? dayCount,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    List<bool>? daySelectedMoToSu,
  }) {
    return HabitsState(
      dayCount: dayCount ?? this.dayCount,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      daySelectedMoToSu: daySelectedMoToSu ?? List<bool>.from(this.daySelectedMoToSu),
    );
  }

  String get startHHmm => '${_two(startHour)}:${_two(startMinute)}';
  String get endHHmm => '${_two(endHour)}:${_two(endMinute)}';

  List<bool> localizedDays(bool startsOnSunday) {
    final base = List<bool>.from(daySelectedMoToSu);
    if (!startsOnSunday) {
      return base;
    }
    return [
      base[6],
      base[0],
      base[1],
      base[2],
      base[3],
      base[4],
      base[5],
    ];
  }
}

Future<HabitsState> loadHabitsStateFromPrefs(SharedPreferences prefs) async {
  try {
    await prefs.reload();
  } catch (_) {
    // ignore reload failures (not supported on all platforms)
  }

  final dayCount = _readInt(prefs, _dayCountKey, 3, legacyKey: _dayCountLegacyKey); // 3 par défaut pour non-premium
  final startHour = _clamp(_readInt(prefs, _startHourKey, 8, legacyKey: _startHourLegacyKey), 0, 23);
  final startMinute = _clamp(_readInt(prefs, _startMinuteKey, 0, legacyKey: _startMinuteLegacyKey), 0, 59);
  final endHour = _clamp(_readInt(prefs, _endHourKey, 18, legacyKey: _endHourLegacyKey), 0, 23); // 18h par défaut
  final endMinute = _clamp(_readInt(prefs, _endMinuteKey, 0, legacyKey: _endMinuteLegacyKey), 0, 59);
  final daySelected = _parseBoolList(_readStringList(prefs, _daySelectedKey, legacyKey: _daySelectedLegacyKey));

  return HabitsState(
    dayCount: dayCount,
    startHour: startHour,
    startMinute: startMinute,
    endHour: endHour,
    endMinute: endMinute,
    daySelectedMoToSu: daySelected,
  );
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPrefsProvider doit être override avant runApp()');
});

final habitsStateProvider = StateNotifierProvider<HabitsNotifier, HabitsState>((ref) {
  throw UnimplementedError('habitsStateProvider doit être override avant runApp()');
});

final startsOnSundayProvider = StateProvider<bool>((ref) => false);

final userNameStateProvider = StateProvider<String>((ref) => "Nobody");

final dayCountProvider = Provider<int>((ref) => ref.watch(habitsStateProvider).dayCount);

final startHourProvider = Provider<int>((ref) => ref.watch(habitsStateProvider).startHour);

final startMinuteProvider = Provider<int>((ref) => ref.watch(habitsStateProvider).startMinute);

final endHourProvider = Provider<int>((ref) => ref.watch(habitsStateProvider).endHour);

final endMinuteProvider = Provider<int>((ref) => ref.watch(habitsStateProvider).endMinute);

final daySelectedMoToSuProvider = Provider<List<bool>>((ref) {
  final state = ref.watch(habitsStateProvider);
  return List<bool>.from(state.daySelectedMoToSu);
});

final startHHmmProvider = Provider<String>((ref) => ref.watch(habitsStateProvider).startHHmm);

final endHHmmProvider = Provider<String>((ref) => ref.watch(habitsStateProvider).endHHmm);

final startHourStrProvider = Provider<String>((ref) => _two(ref.watch(habitsStateProvider).startHour));

final startMinuteStrProvider = Provider<String>((ref) => _two(ref.watch(habitsStateProvider).startMinute));

final endHourStrProvider = Provider<String>((ref) => _two(ref.watch(habitsStateProvider).endHour));

final endMinuteStrProvider = Provider<String>((ref) => _two(ref.watch(habitsStateProvider).endMinute));

final daySelectedLocalizedProvider = Provider<List<bool>>((ref) {
  final startsOnSunday = ref.watch(startsOnSundayProvider);
  final state = ref.watch(habitsStateProvider);
  return state.localizedDays(startsOnSunday);
});

class HabitsNotifier extends StateNotifier<HabitsState> {
  HabitsNotifier(this._prefs, HabitsState initialState) : super(initialState);

  final SharedPreferences _prefs;

  Future<void> setHabits({
    int? dayCount,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    List<bool>? daySelectedMoToSu,
  }) async {
    final normalizedDays = daySelectedMoToSu != null ? _normalizeBoolList(daySelectedMoToSu) : null;

    final newState = state.copyWith(
      dayCount: dayCount,
      startHour: startHour != null ? _clamp(startHour, 0, 23) : null,
      startMinute: startMinute != null ? _clamp(startMinute, 0, 59) : null,
      endHour: endHour != null ? _clamp(endHour, 0, 23) : null,
      endMinute: endMinute != null ? _clamp(endMinute, 0, 59) : null,
      daySelectedMoToSu: normalizedDays,
    );

    state = newState;
    await _persist(newState);
  }

  Future<void> setDaySelectedLocalized(List<bool> localized, {required bool startsOnSunday}) async {
    final moToSu = _fromLocalized(localized, startsOnSunday: startsOnSunday);
    await setHabits(daySelectedMoToSu: moToSu);
  }

  Future<void> reload() async {
    final refreshed = await loadHabitsStateFromPrefs(_prefs);
    state = refreshed;
  }

  List<bool> _fromLocalized(List<bool> localized, {required bool startsOnSunday}) {
    final normalized = _normalizeBoolList(localized);
    if (!startsOnSunday) return normalized;
    return [
      normalized[1],
      normalized[2],
      normalized[3],
      normalized[4],
      normalized[5],
      normalized[6],
      normalized[0],
    ];
  }

  Future<void> _persist(HabitsState value) async {
    await _prefs.setInt(_dayCountKey, value.dayCount);
    await _prefs.setInt(_dayCountLegacyKey, value.dayCount);

    await _prefs.setInt(_startHourKey, value.startHour);
    await _prefs.setInt(_startHourLegacyKey, value.startHour);

    await _prefs.setInt(_startMinuteKey, value.startMinute);
    await _prefs.setInt(_startMinuteLegacyKey, value.startMinute);

    await _prefs.setInt(_endHourKey, value.endHour);
    await _prefs.setInt(_endHourLegacyKey, value.endHour);

    await _prefs.setInt(_endMinuteKey, value.endMinute);
    await _prefs.setInt(_endMinuteLegacyKey, value.endMinute);

    final asStrings = value.daySelectedMoToSu.map((e) => e.toString()).toList(growable: false);
    await _prefs.setStringList(_daySelectedKey, asStrings);
    await _prefs.setStringList(_daySelectedLegacyKey, asStrings);
  }
}

