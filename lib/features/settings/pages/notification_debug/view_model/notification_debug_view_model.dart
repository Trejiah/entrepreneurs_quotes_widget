import 'package:businessmindset/features/settings/pages/notification_debug/view_model/notification_debug_ui_state.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationDebugViewModel extends StateNotifier<NotificationDebugUiState> {
  NotificationDebugViewModel(this._ref) : super(const NotificationDebugUiState());

  final Ref _ref;

  Future<void> checkNotifications() async {
    state = state.copyWith(debugInfo: 'Verification en cours...');

    final habits = _ref.read(habitsStateProvider);
    final now = DateTime.now();

    final buffer = StringBuffer();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('DIAGNOSTIC DES NOTIFICATIONS');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');
    buffer.writeln('Heure actuelle:');
    buffer.writeln(
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    );
    buffer.writeln('');
    buffer.writeln('Configuration:');
    buffer.writeln('Nombre: ${habits.dayCount}');
    buffer.writeln(
      'Debut: ${habits.startHour.toString().padLeft(2, '0')}:${habits.startMinute.toString().padLeft(2, '0')}',
    );
    buffer.writeln(
      'Fin: ${habits.endHour.toString().padLeft(2, '0')}:${habits.endMinute.toString().padLeft(2, '0')}',
    );
    buffer.writeln('Jours: ${_formatDays(habits.daySelectedMoToSu.toList())}');
    buffer.writeln('');

    final todayStart = DateTime(
      now.year,
      now.month,
      now.day,
      habits.startHour,
      habits.startMinute,
    );
    final isPast = todayStart.isBefore(now);
    if (isPast) {
      buffer.writeln('ATTENTION:');
      buffer.writeln("L'heure de debut est deja passee aujourd'hui !");
      buffer.writeln(
        'Les notifications seront programmees pour le prochain jour selectionne.',
      );
      buffer.writeln('');
    }

    final todayWeekday = now.weekday;
    final todayIndex = todayWeekday - 1;
    final isTodaySelected = habits.daySelectedMoToSu[todayIndex];
    if (!isTodaySelected) {
      buffer.writeln('ATTENTION:');
      buffer.writeln("Le jour actuel n'est PAS selectionne !");
      buffer.writeln(
        "Les notifications ne seront pas programmees pour aujourd'hui.",
      );
      buffer.writeln('');
    }

    await NotificationService.instance.debugPendingNotifications();

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');
    buffer.writeln('Verification terminee.');
    buffer.writeln('Consultez les logs de la console pour plus de details.');

    state = state.copyWith(debugInfo: buffer.toString());
  }

  Future<void> testNotificationNow() async {
    state = state.copyWith(debugInfo: "Programmation d'un test dans 1 minute...");

    final lang = _ref.read(languageProvider);
    final prefs = _ref.read(sharedPrefsProvider);
    final now = DateTime.now();
    final testTime = now.add(const Duration(minutes: 1));

    await _ref.read(habitsStateProvider.notifier).setHabits(
          dayCount: 1,
          startHour: testTime.hour,
          startMinute: testTime.minute,
          endHour: testTime.hour,
          endMinute: testTime.minute,
          daySelectedMoToSu: List.filled(7, true),
        );

    final habits = _ref.read(habitsStateProvider);
    await NotificationService.instance.scheduleFromHabits(
      prefs: prefs,
      habits: habits,
      languageCode: lang,
      triggeredAutomatically: false,
    );
    await NotificationService.instance.debugPendingNotifications();

    state = state.copyWith(
      debugInfo:
          'Test programme pour ${testTime.hour.toString().padLeft(2, '0')}:${testTime.minute.toString().padLeft(2, '0')}\n\n'
          'Une notification devrait apparaitre dans 1 minute.\n\n'
          'Consultez les logs pour verifier.',
    );
  }

  String _formatDays(List<bool> days) {
    const dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final selected = <String>[];
    for (var i = 0; i < days.length && i < dayNames.length; i++) {
      if (days[i]) selected.add(dayNames[i]);
    }
    return selected.isEmpty ? 'Aucun jour selectionne !' : selected.join(', ');
  }
}

