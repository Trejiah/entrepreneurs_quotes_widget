import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/app_localizations.dart';
import '../providers/habits_provider.dart';
import '../models/quotes_model.dart';
import '../models/topics.dart';
import '../utils/favorite_management.dart';

@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  debugPrint('[NotificationService] background handler invoked (type: ${response.notificationResponseType})');
  NotificationService.instance.handleBackgroundNotificationResponse(response);
}

class NotificationQuotePayload {
  final String quote;
  final String category;
  final String? signature;
  final String? bookTitle;
  final String? url;

  const NotificationQuotePayload({
    required this.quote,
    required this.category,
    this.signature,
    this.bookTitle,
    this.url,
  });

  factory NotificationQuotePayload.fromJson(String raw) {
    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
    return NotificationQuotePayload(
      quote: json['quote'] as String? ?? '',
      category: json['category'] as String? ?? '',
      signature: json['signature'] as String?,
      bookTitle: json['bookTitle'] as String?,
      url: json['url'] as String?,
    );
  }

  String toJson() {
    return jsonEncode({
      'quote': quote,
      'category': category,
      'signature': signature,
      'bookTitle': bookTitle,
      'url': url,
    });
  }
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static const String _dailyQuoteChannelId = 'daily_quote_channel_v2';
  static const String _trialReminderChannelId = 'trial_reminder_channel_v2';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final StreamController<NotificationQuotePayload> _tapController = StreamController.broadcast();
  bool _initialized = false;
  NotificationQuotePayload? _initialPayload;
  final Queue<NotificationQuotePayload> _foregroundTapQueue = Queue<NotificationQuotePayload>();
  DateTime? _lastAutomaticSchedule;
  static const Duration _kAutoScheduleMinInterval = Duration(hours: 6);
  tz.Location? _localLocation;
  Future<bool>? _pendingPermissionRequest;

  Stream<NotificationQuotePayload> get onNotificationTap => _tapController.stream;

  NotificationQuotePayload? consumePendingTapPayload() {
    if (_foregroundTapQueue.isEmpty) return null;
    return _foregroundTapQueue.removeFirst();
  }

  NotificationQuotePayload? consumeInitialPayload() {
    final payload = _initialPayload;
    _initialPayload = null;
    return payload;
  }

  Future<void> init() async {
    if (_initialized) return;

    await _configureLocalTimeZone();

    // Use a dedicated monochrome notification icon.
    // Adaptive launcher icons can be rejected on some OEM ROMs.
    const androidSettings = AndroidInitializationSettings('ic_stat_notify');
    const darwinSettings = DarwinInitializationSettings(
      // Important: do not trigger the system popup at startup.
      // The permission request is made explicitly from onboarding (e.g. OnBoarding9).
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: darwinSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationResponse(response);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackgroundHandler,
    );

    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _dailyQuoteChannelId,
        'Daily Quote Reminders',
        description: 'Entrepreneurs Quotes quote reminders',
        importance: Importance.max,
      ),
    );
    // Pre-create the trial reminder channel as well so the very first
    // call to scheduleTrialReminderNotification doesn't have to.
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _trialReminderChannelId,
        'Trial Reminder',
        description: 'Reminder for trial ending',
        importance: Importance.max,
      ),
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails!.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        _initialPayload = NotificationQuotePayload.fromJson(payload);
      }
    }

    _initialized = true;
  }

  /// Explicitly request notification permissions.
  /// To call from onboarding (not at startup).
  Future<bool> requestUserNotificationPermissions() async {
    final inFlightRequest = _pendingPermissionRequest;
    if (inFlightRequest != null) {
      return inFlightRequest;
    }
    _pendingPermissionRequest = _requestUserNotificationPermissionsInternal();
    try {
      return await _pendingPermissionRequest!;
    } finally {
      _pendingPermissionRequest = null;
    }
  }

  Future<bool> _requestUserNotificationPermissionsInternal() async {
    if (!_initialized) {
      await init();
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      if (kDebugMode) {
        debugPrint("🔔 [NotificationService] iOS permissions requested (onboarding): $granted");
      }
      return granted;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      // On Android 13+, a runtime permission may be required.
      final granted = await androidPlugin?.requestNotificationsPermission();
      if (kDebugMode) {
        debugPrint("🔔 [NotificationService] Android permissions requested (onboarding): $granted");
      }
      // On versions < 13, the API may return null; in that case treat as "ok" and let
      // the system/settings handle activation.
      return granted ?? true;
    }

    return true;
  }

  void handleBackgroundNotificationResponse(NotificationResponse response) {
    _handleNotificationResponse(response);
  }

  Future<void> scheduleFromHabits({
    required SharedPreferences prefs,
    required HabitsState habits,
    required String languageCode,
    bool triggeredAutomatically = false,
    bool ignoreForcedQuotes = false,
  }) {
    if (triggeredAutomatically) {
      final now = DateTime.now();
      if (_lastAutomaticSchedule != null) {
        final elapsed = now.difference(_lastAutomaticSchedule!);
        if (elapsed < _kAutoScheduleMinInterval) {
          if (kDebugMode) {
            debugPrint('[NotificationService] Auto schedule skipped (elapsed ${elapsed.inMinutes} min)');
          }
          return Future.value();
        }
      }
      _lastAutomaticSchedule = now;
      if (kDebugMode) {
        debugPrint('[NotificationService] Auto scheduling notifications at $now');
      }
    } else {
      _lastAutomaticSchedule = DateTime.now();
      if (kDebugMode) {
        debugPrint('[NotificationService] Manual scheduling triggered');
      }
    }

  // Use the user's preferences directly (habits),
  // without specific limitation for non-premium accounts.
  final finalManyCount = habits.dayCount;
  final finalStartHour = habits.startHour;
  final finalStartMinute = habits.startMinute;
  final finalEndHour = habits.endHour;
  final finalEndMinute = habits.endMinute;
  final finalDaySelected = habits.daySelectedMoToSu.toList();

    return scheduleNotifications(
      prefs: prefs,
      languageCode: languageCode,
      manyCount: finalManyCount,
      startHour: finalStartHour,
      startMinute: finalStartMinute,
      endHour: finalEndHour,
      endMinute: finalEndMinute,
      weekdaySelectionMoToSu: finalDaySelected,
      ignoreForcedQuotes: ignoreForcedQuotes,
    );
  }

  Future<void> scheduleNotifications({
    required SharedPreferences prefs,
    required String languageCode,
    required int manyCount,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    required List<bool> weekdaySelectionMoToSu,
    bool ignoreForcedQuotes = false,
  }) async {
    if (!_initialized) {
      await init();
    }

    if (manyCount <= 0) {
      await cancelAll();
      return;
    }

    await cancelAll();

    final location = _localLocation ?? tz.local;
    final now = tz.TZDateTime.now(location);
    final slots = _computeDailySlots(
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
      count: manyCount,
    );
    if (slots.isEmpty) return;

    final allScheduledDates = _nextOccurrences(now, weekdaySelectionMoToSu, slots).toList();

    // iOS hard caps the system queue at 64 pending notifications. Android
    // accepts up to 500 per app, so honour that on each platform separately.
    final int maxNotifications =
        defaultTargetPlatform == TargetPlatform.iOS ? 64 : 500;
    final scheduledDates = allScheduledDates.length > maxNotifications
        ? allScheduledDates.take(maxNotifications).toList()
        : allScheduledDates;
    
    // Retrieve the user name to replace %NAME%
    final userName = prefs.getString("userName") ?? "Nobody";
    
    final usedQuotes = <String>{};
    final totalNotifications = scheduledDates.length;
    final originalCount = allScheduledDates.length;
    
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📅 [NotificationService] Scheduling notifications");
      debugPrint("   - Heure actuelle: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}");
      debugPrint("   - Computed slots: ${slots.length}");
      for (var i = 0; i < slots.length; i++) {
        debugPrint("     ${i + 1}. ${slots[i].hour.toString().padLeft(2, '0')}:${slots[i].minute.toString().padLeft(2, '0')}");
      }
      debugPrint("   - Computed notifications: $originalCount");
      if (originalCount > maxNotifications) {
        debugPrint("   ⚠️  Platform cap ($maxNotifications): ${originalCount - maxNotifications} notifications skipped");
      }
      debugPrint("   - Scheduled notifications: $totalNotifications");
      for (var i = 0; i < scheduledDates.length && i < 20; i++) {
        final date = scheduledDates[i];
        debugPrint("     ${i + 1}. ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}");
      }
      if (scheduledDates.length > 20) {
        debugPrint("     ... and ${scheduledDates.length - 20} more");
      }
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
    
    final reminderPositions = <int>{50, 55, 60};
    if (totalNotifications > 0) {
      reminderPositions.add(totalNotifications - 1); // Dernière position
    }

    var notificationIndex = 0;
    
    // Check whether there's a forced quote for the first notifications
    // Reload preferences to ensure we have the latest values
    await prefs.reload();
    
    NotificationQuotePayload? forcedPayload;
    int forcedQuoteCount = 0;
    
    // If ignoreForcedQuotes is true, clear forced quotes and don't use them
    if (ignoreForcedQuotes) {
      await prefs.remove("forcedQuoteForNotifications");
      await prefs.remove("forcedQuoteCategory");
      await prefs.remove("forcedQuoteSignature");
      await prefs.remove("forcedQuoteBookTitle");
      await prefs.remove("forcedQuoteUrl");
      await prefs.remove("forcedQuoteCount");
      await prefs.reload();
      
      if (kDebugMode) {
        debugPrint("🔍 [NotificationService] Forced quotes skipped (ignoreForcedQuotes=true)");
      }
    } else {
      final forcedQuoteText = prefs.getString("forcedQuoteForNotifications");
      final forcedQuoteCategory = prefs.getString("forcedQuoteCategory") ?? "";
      final forcedQuoteSignature = prefs.getString("forcedQuoteSignature");
      final forcedQuoteBookTitle = prefs.getString("forcedQuoteBookTitle");
      final forcedQuoteUrl = prefs.getString("forcedQuoteUrl");
      forcedQuoteCount = prefs.getInt("forcedQuoteCount") ?? 0;
      
      if (kDebugMode) {
        debugPrint("🔍 [NotificationService] Checking forced quotes:");
        debugPrint("   - forcedQuoteForNotifications: ${forcedQuoteText != null && forcedQuoteText.isNotEmpty ? 'PRÉSENTE (${forcedQuoteText.substring(0, forcedQuoteText.length > 50 ? 50 : forcedQuoteText.length)}...)' : 'null'}");
        debugPrint("   - forcedQuoteCount: $forcedQuoteCount");
      }
      
      // Create the forced quote payload if it exists
      if (forcedQuoteText != null && forcedQuoteText.isNotEmpty && forcedQuoteCount > 0) {
        forcedPayload = NotificationQuotePayload(
          quote: forcedQuoteText,
          category: forcedQuoteCategory,
          signature: forcedQuoteSignature,
          bookTitle: forcedQuoteBookTitle,
          url: forcedQuoteUrl,
        );
        // Reset flags after use (we'll clean them up after scheduling notifications)
        if (kDebugMode) {
          debugPrint("📋 [NotificationService] Forced quote detected for the first $forcedQuoteCount notifications");
          debugPrint("   - Citation: $forcedQuoteText");
        }
      }
    }
    
    for (final occurrence in scheduledDates) {
      final isReminderPosition = reminderPositions.contains(notificationIndex);
      final isLongQuotePosition = (notificationIndex % 7 == 6); // Toutes les 7 citations (0-indexed, donc 6, 13, 20...)
      final shouldUseForcedQuote = forcedPayload != null && notificationIndex < forcedQuoteCount && !isReminderPosition;
      
      NotificationQuotePayload payload;
      String displayText;
      
      if (isReminderPosition) {
        // Message de rappel
        final reminderMessage = translate("notification_reminder", languageCode);
        payload = NotificationQuotePayload(
          quote: reminderMessage,
          category: 'reminder',
        );
        displayText = reminderMessage;
      } else if (shouldUseForcedQuote) {
        // Use the forced quote for the first N notifications
        // Replace %NAME% with the user name
        final quoteWithName = forcedPayload.quote.replaceAll("%NAME%", userName);
        payload = NotificationQuotePayload(
          quote: quoteWithName,
          category: forcedPayload.category,
          signature: forcedPayload.signature,
          bookTitle: forcedPayload.bookTitle,
          url: forcedPayload.url,
        );
        // For dup tracking, use the "raw" text (with %NAME%)
        // so that priority quotes are properly recognized
        // in _randomQuotePayload.
        usedQuotes.add(_quoteUniqKey(forcedPayload));
        displayText = _truncate(quoteWithName);
      } else {
        // Citation normale
        final tempPayload = await _randomQuotePayload(
          prefs,
          languageCode,
          usedQuotes,
          forceLong: isLongQuotePosition,
          ignorePriorityQuotes: ignoreForcedQuotes,
        );
        // Replace %NAME% with the user name
        final quoteWithName = tempPayload.quote.replaceAll("%NAME%", userName);
        payload = NotificationQuotePayload(
          quote: quoteWithName,
          category: tempPayload.category,
          signature: tempPayload.signature,
          bookTitle: tempPayload.bookTitle,
          url: tempPayload.url,
        );
        // Same logic: store the key on the "raw" quote (with %NAME%)
        // so that uniqueness checks and priority quote checks
        // fonctionnent correctement.
        usedQuotes.add(_quoteUniqKey(tempPayload));
        displayText = _truncate(quoteWithName);
      }

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyQuoteChannelId,
          'Daily Quote Reminders',
          channelDescription: 'Entrepreneurs Quotes quote reminders',
          icon: 'ic_stat_notify',
          largeIcon: const DrawableResourceAndroidBitmap('ic_notif_large'),
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(
            displayText,
            summaryText: payload.signature,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

      try {
        await _plugin.zonedSchedule(
          _notificationIdFor(occurrence, notificationIndex),
          'Entrepreneurs Quotes',
          displayText,
          occurrence,
          details,
          payload: payload.toJson(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        if (kDebugMode && notificationIndex < 3) {
          debugPrint("✅ [NotificationService] Notification ${notificationIndex + 1} programmée: ${occurrence.year}-${occurrence.month.toString().padLeft(2, '0')}-${occurrence.day.toString().padLeft(2, '0')} ${occurrence.hour.toString().padLeft(2, '0')}:${occurrence.minute.toString().padLeft(2, '0')}");
        }
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint("❌ [NotificationService] Error while scheduling notification ${notificationIndex + 1}: $e");
          debugPrint("   Stack: $stack");
        }
      }
      notificationIndex++;
    }
    
    // Clear forced quote flags after scheduling all notifications
    if (forcedPayload != null) {
      await prefs.remove("forcedQuoteForNotifications");
      await prefs.remove("forcedQuoteCategory");
      await prefs.remove("forcedQuoteSignature");
      await prefs.remove("forcedQuoteBookTitle");
      await prefs.remove("forcedQuoteUrl");
      await prefs.remove("forcedQuoteCount");
      
      if (kDebugMode) {
        debugPrint("📋 [NotificationService] Forced quote flags cleared after scheduling");
      }
    }
    
    // Final check: on iOS, verify that notifications are properly registered
    if (defaultTargetPlatform == TargetPlatform.iOS && kDebugMode) {
      final pendingAfter = await _plugin.pendingNotificationRequests();
      final now = tz.TZDateTime.now(_localLocation ?? tz.local);
      
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("🔍 [NotificationService] Post-scheduling iOS check");
      debugPrint("   - Registered notifications: ${pendingAfter.length}");
      debugPrint("   - Heure actuelle: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}");
      debugPrint("   - ⚠️  On iOS, notifications may be removed by the system");
      debugPrint("   - ⚠️  Check Settings > Entrepreneurs Quotes > Notifications");
      debugPrint("   - ⚠️  Test with a notification in 1-2 minutes to confirm");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// List all pending notifications (for debug)
  Future<void> debugPendingNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();
    
    // Check permissions
    bool? androidPermission;
    bool? iosPermission;
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      androidPermission = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        // Do not call requestPermissions here (otherwise it may show the popup).
        // Keep an "unknown" status and guide to iOS Settings in debug.
        iosPermission = null;

        if (kDebugMode) {
          debugPrint("🔍 [NotificationService] Checking iOS permissions:");
          debugPrint("   - Permissions granted: unknown (avoids triggering the popup)");
          debugPrint("   - ⚠️  Check Settings > Entrepreneurs Quotes > Notifications");
          debugPrint("   - ⚠️  Vérifiez aussi que le mode Focus n'est pas activé");
        }
      }
    }
    
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("🔔 [NotificationService] Notification status");
      if (androidPermission != null) {
        debugPrint("   - Permissions Android: ${androidPermission ? '✅ Activées' : '❌ Désactivées'}");
      }
      if (iosPermission != null) {
        debugPrint("   - Permissions iOS: ${iosPermission ? '✅ Activées' : '❌ Désactivées'}");
        if (!iosPermission) {
          debugPrint("   ⚠️  ACTION REQUIRED: Enable notifications in iOS Settings");
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint("   - iOS permissions: ❓ Unknown (not checked to avoid the popup)");
      }
      debugPrint("   - Notifications en attente: ${pending.length}");
      if (pending.isNotEmpty) {
        debugPrint("   - Prochaines notifications:");
        for (var i = 0; i < pending.length && i < 15; i++) {
          final notif = pending[i];
          debugPrint("     ${i + 1}. ID: ${notif.id}, Body: ${notif.body?.substring(0, notif.body!.length > 50 ? 50 : notif.body!.length) ?? 'null'}...");
        }
        if (pending.length > 5) {
          debugPrint("     ... and ${pending.length - 5} more");
        }
      } else {
        debugPrint("   ⚠️  NO notification scheduled!");
      }
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }

  /// Schedule a reminder notification for the end of the trial
  /// [reminderDate]: date when the notification should be shown (D-2 from trial end)
  /// [languageCode]: language code for the message translation
  Future<void> scheduleTrialReminderNotification({
    required DateTime reminderDate,
    required String languageCode,
  }) async {
    if (!_initialized) {
      await init();
    }
    
    final location = _localLocation ?? tz.local;
    final reminderDateTime = tz.TZDateTime.from(reminderDate, location);
    final now = tz.TZDateTime.now(location);
    
    // Do not schedule if the date is in the past
    if (reminderDateTime.isBefore(now)) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Trial reminder date is in the past, skipping');
      }
      return;
    }
    
    // Annuler l'ancienne notification de rappel si elle existe (ID fixe)
    const reminderNotificationId = 99999; // ID unique pour le rappel du trial
    await _plugin.cancel(reminderNotificationId);
    
    final title = translate("trial_ending_reminder_title", languageCode);
    final body = translate("trial_ending_reminder_body", languageCode);
    
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _trialReminderChannelId,
        'Trial Reminder',
        channelDescription: 'Reminder for trial ending',
        icon: 'ic_stat_notify',
        largeIcon: const DrawableResourceAndroidBitmap('ic_notif_large'),
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          body,
          summaryText: title,
        ),
      ),
      iOS: const DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
    
    // Empty payload since it's just a reminder, not a quote
    final payload = NotificationQuotePayload(
      quote: body,
      category: 'trial_reminder',
    );
    
    await _plugin.zonedSchedule(
      reminderNotificationId,
      title,
      body,
      reminderDateTime,
      details,
      payload: payload.toJson(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    if (kDebugMode) {
      debugPrint('[NotificationService] Trial reminder scheduled for: $reminderDateTime');
    }
  }
  
  /// Cancel the trial reminder notification
  Future<void> cancelTrialReminderNotification() async {
    const reminderNotificationId = 99999;
    await _plugin.cancel(reminderNotificationId);
    if (kDebugMode) {
      debugPrint('[NotificationService] Trial reminder notification cancelled');
    }
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      tz.initializeTimeZones();
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      _localLocation = tz.getLocation(timezoneName);
      tz.setLocalLocation(_localLocation!);
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Failed to set local timezone: $error');
        debugPrint('$stack');
      }
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
      _localLocation = tz.local;
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    debugPrint('[NotificationService] _handleNotificationResponse called (type: ${response.notificationResponseType})');
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final parsed = NotificationQuotePayload.fromJson(payload);
      debugPrint('[NotificationService] Notification tap payload: ${parsed.quote}');
      _foregroundTapQueue.addLast(parsed);
      _tapController.add(parsed);
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Invalid notification payload: $error');
        debugPrint('$stack');
      }
    }
  }

  NotificationQuotePayload _buildOpenToUpdateFallback(String languageCode) {
    final text = translate('open_to_update', languageCode);
    return NotificationQuotePayload(
      quote: text,
      category: 'Mindset',
    );
  }

  List<String> _loadSelectedTopicsForNotifications(
    SharedPreferences prefs,
    bool premium,
  ) {
    final savedTopics = prefs.getStringList('selectedTopics') ?? [];
    
    // If no saved topic, use default values
    if (savedTopics.isEmpty) {
      return premium ? <String>[personalizedFeedTopicId] : <String>['general'];
    }
    
    // Validate topics based on premium status
    // Topics accessibles en free : favoritesquotes, general, resilience, vispurp
    const freeTopics = {'favoritesquotes', 'general', 'resilience', 'vispurp'};
    
    if (!premium) {
      // Check whether locked topics are selected
      final hasLockedTopics = savedTopics.any((topicId) => !freeTopics.contains(topicId));
      
      if (hasLockedTopics) {
        // Fix: use "general" if locked topics are selected
        // Save the correction so home_page and the widget also use it
        final correctedTopics = <String>['general'];
        prefs.setStringList('selectedTopics', correctedTopics);
        
        if (kDebugMode) {
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('⚠️ [NotificationService] Locked topics detected - Auto-correcting');
          debugPrint('   - premium: $premium');
          debugPrint('   - topics avant: $savedTopics');
          debugPrint('   - topics after: $correctedTopics');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }
        
        return correctedTopics;
      }
    }
    
    // Valid topics, use them
    return List<String>.from(savedTopics);
  }

  Future<List<Map<String, dynamic>>> _getAvailableQuotesForNotifications({
    required List<String> selectedTopics,
    required String lang,
    required bool premium,
  }) async {
    final List<Map<String, dynamic>> availableQuotes = [];
    final prefs = await SharedPreferences.getInstance();

    // Retrieve gender to filter womenemp
    final gender = prefs.getString('gender');
    final isFemale = gender == 'Female';

    // Lazy loading of favorites
    List<DayQuote>? favoriteQuotes;
    var favoritesLoaded = false;

    for (final topicId in selectedTopics) {
      if (topicId == personalizedFeedTopicId) {
        // My personalized feed :
        // 1. Randomly draw a personalized_plan according to the percentages
        // 2. Randomly draw a topic from those of the chosen plan
        // 3. Iterate over the quotes of this topic for this plan
        final random = Random();
        final planCategories = ['growth', 'discipline', 'confidence', 'strategy'];
        final planPercentages = <String, double>{};
        var totalPercentage = 0.0;

        for (final cat in planCategories) {
          final percentage = prefs.getDouble('plan_${cat}_percentage') ?? 0.0;
          if (percentage > 0.0) {
            planPercentages[cat] = percentage;
            totalPercentage += percentage;
          }
        }

        String selectedPlanCategory;
        if (planPercentages.isEmpty || totalPercentage == 0.0) {
          selectedPlanCategory = planCategories[random.nextInt(planCategories.length)];
        } else {
          final randomValue = random.nextDouble() * totalPercentage;
          var cumulative = 0.0;
          selectedPlanCategory = planCategories.first;
          for (final entry in planPercentages.entries) {
            cumulative += entry.value;
            if (randomValue <= cumulative) {
              selectedPlanCategory = entry.key;
              break;
            }
          }
        }

        final Map<String, List<String>> planToTopics = {
          'growth': ['growsucces', 'leadership', 'entrepreneurship'],
          'discipline': ['focdic', 'vispurp'],
          'confidence': ['confmind', 'resilience', 'womenemp'],
          'strategy': ['salebranding', 'wealthmoney'],
        };

        final topicsForPlan = planToTopics[selectedPlanCategory] ?? <String>[];

        final availableTopics = topicsForPlan.where((topic) {
          if (topic == 'womenemp' && !isFemale) {
            return false;
          }
          return true;
        }).toList();

        if (availableTopics.isEmpty) {
          if (kDebugMode) {
            debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            debugPrint("⚠️ [NotificationService] personalized_feed - NO topic available for the selected plan");
            debugPrint("   - lang: $lang");
            debugPrint("   - premium: $premium");
            debugPrint("   - gender: $gender, isFemale: $isFemale");
            debugPrint("   - selectedPlanCategory: $selectedPlanCategory");
            debugPrint("   - topicsForPlan: $topicsForPlan");
            debugPrint("   - topicsForPlan (count): ${topicsForPlan.length}");
            debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          }
          continue;
        }

        final selectedTopic = availableTopics[random.nextInt(availableTopics.length)];

        if (quotesTot.containsKey(selectedTopic)) {
          final quotes = quotesTot[selectedTopic]!;
          var quotesAddedForThisTopic = 0;
          for (final raw in quotes) {
            if (raw is! Map) continue;
            final Map<String, dynamic> q = Map<String, dynamic>.from(raw);

            // For notifications, once the topic is chosen (per plan),
            // we accept all quotes from this topic, without re-filtering by personalized_plan.
            final planCategory = q['personalized_plan'] as String?;

            if (!premium && (q['isFree'] != true)) {
              continue;
            }

            final text = q[lang] ?? q['en'];
            if (text != null && text.isNotEmpty) {
              availableQuotes.add({
                'category': selectedTopic,
                'text': text,
                'signature': q['signature'] as String?,
                'bookTitle': q['bookTitle']?[lang] ?? q['bookTitle']?['en'],
                'url': q['url'],
                'topicSource': 'personalized_feed',
                'planCategory': planCategory,
                'tone': q['tone'],
              });
              quotesAddedForThisTopic++;
            }
          }

          if (kDebugMode) {
            debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            debugPrint("📋 [NotificationService] personalized_feed - Notification details");
            debugPrint("   - lang: $lang");
            debugPrint("   - premium: $premium");
            debugPrint("   - gender: $gender, isFemale: $isFemale");
            debugPrint("   - selectedPlanCategory: $selectedPlanCategory");
            debugPrint("   - topicsForPlan: $topicsForPlan");
            debugPrint("   - topicsForPlan (count): ${topicsForPlan.length}");
            debugPrint("   - availableTopics (after gender filter): $availableTopics");
            debugPrint("   - availableTopics (count): ${availableTopics.length}");
            debugPrint("   - selectedTopic: $selectedTopic");
            debugPrint("   - quotes in this topic: ${quotes.length}");
            debugPrint("   - quotes added for this topic: $quotesAddedForThisTopic");
            debugPrint("   - availableQuotes (total actuel): ${availableQuotes.length}");
            debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          }
        }
      } else if (topicId == 'favoritesquotes') {
        if (!favoritesLoaded) {
          favoriteQuotes = await loadAllFavorite();
          favoritesLoaded = true;
        }
        final favs = favoriteQuotes ?? const <DayQuote>[];
        for (final fav in favs) {
          availableQuotes.add({
            'category': fav.category ?? '',
            'text': fav.quote,
            'signature': fav.signature,
            'bookTitle': fav.bookTitle,
            'url': fav.url,
            'topicSource': 'favoritesquotes',
            'tone': null,
          });
        }
      } else if (topicId == 'general') {
        for (final entry in quotesTot.entries) {
          final category = entry.key;

          if (category == 'womenemp' && !isFemale) {
            continue;
          }

          final quotes = entry.value;
          if (quotes is! Iterable) continue;
          for (final raw in quotes) {
            if (raw is! Map) continue;
            final Map<String, dynamic> q = Map<String, dynamic>.from(raw);
            if (!premium && (q['isFree'] != true)) {
              continue;
            }
            final text = q[lang] ?? q['en'];
            if (text != null && text.isNotEmpty) {
              availableQuotes.add({
                'category': category,
                'text': text,
                'signature': q['signature'] as String?,
                'bookTitle': q['bookTitle']?[lang] ?? q['bookTitle']?['en'],
                'url': q['url'],
                'topicSource': 'general',
                'tone': q['tone'],
              });
            }
          }
        }
      } else if (topicId == 'businessic') {
        for (final entry in quotesTot.entries) {
          final category = entry.key;
          final quotes = entry.value;
          if (quotes is! Iterable) continue;
          for (final raw in quotes) {
            if (raw is! Map) continue;
            final Map<String, dynamic> q = Map<String, dynamic>.from(raw);

            if (q['businessic'] != true) {
              continue;
            }

            if (!premium && (q['isFree'] != true)) {
              continue;
            }

            final text = q[lang] ?? q['en'];
            if (text != null && text.isNotEmpty) {
              availableQuotes.add({
                'category': category,
                'text': text,
                'signature': q['signature'] as String?,
                'bookTitle': q['bookTitle']?[lang] ?? q['bookTitle']?['en'],
                'url': q['url'],
                'topicSource': 'businessic',
                'tone': q['tone'],
              });
            }
          }
        }
      } else if (topicId == 'frombook') {
        for (final entry in quotesTot.entries) {
          final category = entry.key;
          final quotes = entry.value;
          if (quotes is! Iterable) continue;
          for (final raw in quotes) {
            if (raw is! Map) continue;
            final Map<String, dynamic> q = Map<String, dynamic>.from(raw);

            if (q['frombook'] != true) {
              continue;
            }

            if (!premium && (q['isFree'] != true)) {
              continue;
            }

            final text = q[lang] ?? q['en'];
            if (text != null && text.isNotEmpty) {
              availableQuotes.add({
                'category': category,
                'text': text,
                'signature': q['signature'] as String?,
                'bookTitle': q['bookTitle']?[lang] ?? q['bookTitle']?['en'],
                'url': q['url'],
                'topicSource': 'frombook',
                'tone': q['tone'],
              });
            }
          }
        }
      } else if (topicId == 'no_mercy') {
        for (final entry in quotesTot.entries) {
          final category = entry.key;

          if (category == 'womenemp' && !isFemale) {
            continue;
          }

          final quotes = entry.value;
          if (quotes is! Iterable) continue;
          for (final raw in quotes) {
            if (raw is! Map) continue;
            final Map<String, dynamic> q = Map<String, dynamic>.from(raw);

            if (q['tone'] != 'no mercy') {
              continue;
            }

            if (!premium && (q['isFree'] != true)) {
              continue;
            }

            final text = q[lang] ?? q['en'];
            if (text != null && text.isNotEmpty) {
              availableQuotes.add({
                'category': category,
                'text': text,
                'signature': q['signature'] as String?,
                'bookTitle': q['bookTitle']?[lang] ?? q['bookTitle']?['en'],
                'url': q['url'],
                'topicSource': 'no_mercy',
                'tone': q['tone'],
              });
            }
          }
        }
      } else if (topicId == 'affirmative') {
        for (final entry in quotesTot.entries) {
          final category = entry.key;

          if (category == 'womenemp' && !isFemale) {
            continue;
          }

          final quotes = entry.value;
          if (quotes is! Iterable) continue;
          for (final raw in quotes) {
            if (raw is! Map) continue;
            final Map<String, dynamic> q = Map<String, dynamic>.from(raw);

            if (q['tone'] != 'affirmative') {
              continue;
            }

            if (!premium && (q['isFree'] != true)) {
              continue;
            }

            final text = q[lang] ?? q['en'];
            if (text != null && text.isNotEmpty) {
              availableQuotes.add({
                'category': category,
                'text': text,
                'signature': q['signature'] as String?,
                'bookTitle': q['bookTitle']?[lang] ?? q['bookTitle']?['en'],
                'url': q['url'],
                'topicSource': 'affirmative',
                'tone': q['tone'],
              });
            }
          }
        }
      } else {
        if (quotesTot.containsKey(topicId)) {
          final quotes = quotesTot[topicId]!;
          for (final raw in quotes) {
            if (raw is! Map) continue;
            final Map<String, dynamic> q = Map<String, dynamic>.from(raw);

            if (!premium && (q['isFree'] != true)) {
              continue;
            }

            final text = q[lang] ?? q['en'];
            if (text != null && text.isNotEmpty) {
              availableQuotes.add({
                'category': topicId,
                'text': text,
                'signature': q['signature'] as String?,
                'bookTitle': q['bookTitle']?[lang] ?? q['bookTitle']?['en'],
                'url': q['url'],
                'topicSource': topicId,
                'tone': q['tone'],
              });
            }
          }
        }
      }
    }

    return availableQuotes;
  }

  Future<NotificationQuotePayload> _randomQuotePayload(
    SharedPreferences prefs,
    String languageCode,
    Set<String> usedQuotes, {
    bool forceLong = false,
    bool ignorePriorityQuotes = false,
  }) async {
    final premium = prefs.getBool('premiumState') ?? false;
    
    // Check whether priority quotes are selected
    // Skip priority quotes if ignorePriorityQuotes is true
    final priorityQuotes = ignorePriorityQuotes 
        ? <String>[] 
        : (prefs.getStringList('notificationsPriorityQuotes') ?? []);
    
    // If priority quotes exist and haven't all been used yet
    if (priorityQuotes.isNotEmpty) {
      for (final priorityText in priorityQuotes) {
        // If this priority quote hasn't been used yet
        if (!usedQuotes.any((key) => key.contains(priorityText))) {
          // Find this quote's metadata in quotesTot
          for (final entry in quotesTot.entries) {
            final category = entry.key;
            final quotes = entry.value;
            if (quotes is! Iterable) continue;
            
            for (final raw in quotes) {
              if (raw is! Map) continue;
              final Map<String, dynamic> q = Map<String, dynamic>.from(raw);
              final text = q[languageCode] ?? q['en'];
              
              if (text == priorityText) {
                // Priority quote found, return it
                return NotificationQuotePayload(
                  quote: text,
                  category: category,
                  signature: q['signature'] as String?,
                  bookTitle: q['bookTitle']?[languageCode] ?? q['bookTitle']?['en'],
                  url: q['url'],
                );
              }
            }
          }
        }
      }
    }
    
    final selectedTopics = _loadSelectedTopicsForNotifications(prefs, premium);

    final availableQuotes = await _getAvailableQuotesForNotifications(
      selectedTopics: selectedTopics,
      lang: languageCode,
      premium: premium,
    );

    if (availableQuotes.isEmpty) {
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("⚠️ [NotificationService] availableQuotes EMPTY -> fallback open_to_update");
        debugPrint("   - premium: $premium");
        debugPrint("   - languageCode: $languageCode");
        debugPrint("   - selectedTopics: $selectedTopics");
        debugPrint("   - ignorePriorityQuotes: $ignorePriorityQuotes");
        debugPrint("   - usedQuotes (count): ${usedQuotes.length}");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
      return _buildOpenToUpdateFallback(languageCode);
    }

    // Avoid reusing the same quotes within a single scheduling
    final filtered = <Map<String, dynamic>>[];
    for (final q in availableQuotes) {
      final text = (q['text'] as String?)?.trim() ?? '';
      if (text.isEmpty) continue;
      final category = (q['category'] as String?) ?? '';
      final tempPayload = NotificationQuotePayload(
        quote: text,
        category: category,
        signature: q['signature'] as String?,
        bookTitle: q['bookTitle'] as String?,
        url: q['url'] as String?,
      );
      final key = _quoteUniqKey(tempPayload);
      if (!usedQuotes.contains(key)) {
        filtered.add(q);
      }
    }

    final pool = filtered.isNotEmpty ? filtered : availableQuotes;
    if (pool.isEmpty) {
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("⚠️ [NotificationService] pool EMPTY after de-duplication -> fallback open_to_update");
        debugPrint("   - premium: $premium");
        debugPrint("   - languageCode: $languageCode");
        debugPrint("   - selectedTopics: $selectedTopics");
        debugPrint("   - availableQuotes (count): ${availableQuotes.length}");
        debugPrint("   - filtered (count): ${filtered.length}");
        debugPrint("   - usedQuotes (count): ${usedQuotes.length}");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
      return _buildOpenToUpdateFallback(languageCode);
    }

    const minLongLength = 141;
    final allIndices = List<int>.generate(pool.length, (i) => i);
    List<int> candidateIndices;
    if (forceLong) {
      candidateIndices = [];
      for (var i = 0; i < pool.length; i++) {
        final text = (pool[i]['text'] as String?)?.trim() ?? '';
        if (text.length >= minLongLength) {
          candidateIndices.add(i);
        }
      }
      if (candidateIndices.isEmpty) {
        candidateIndices = allIndices;
      }
    } else {
      candidateIndices = allIndices;
    }

    final random = Random();
    final weights = List<double>.filled(pool.length, 1.0);
    if (premium) {
      final affirmationPercentage =
          prefs.getInt('tone_value_AFFIRMATION') ?? 0;
      final noMercyPercentage =
          prefs.getInt('tone_value_NO MERCY') ?? 0;

      for (var i = 0; i < pool.length; i++) {
        final tone = pool[i]['tone'] as String?;
        var weight = 1.0;
        if (tone == 'affirmative') {
          weight =
              (1.0 + (affirmationPercentage / 100.0)).clamp(0.01, double.infinity);
        } else if (tone == 'no mercy') {
          weight =
              (1.0 + (noMercyPercentage / 100.0)).clamp(0.01, double.infinity);
        }
        weights[i] = weight;
      }
    }

    var totalWeight = 0.0;
    for (final idx in candidateIndices) {
      totalWeight += weights[idx];
    }

    int selectedIndex;
    if (totalWeight <= 0) {
      selectedIndex = candidateIndices[random.nextInt(candidateIndices.length)];
    } else {
      final target = random.nextDouble() * totalWeight;
      var cumulative = 0.0;
      selectedIndex = candidateIndices.first;
      for (final idx in candidateIndices) {
        cumulative += weights[idx];
        if (target <= cumulative) {
          selectedIndex = idx;
          break;
        }
      }
    }

    final chosen = pool[selectedIndex];
    final chosenText = (chosen['text'] as String?)?.trim() ?? '';
    final chosenCategory = (chosen['category'] as String?) ?? '';

    if (chosenText.isEmpty) {
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("⚠️ [NotificationService] chosenText EMPTY -> fallback open_to_update");
        debugPrint("   - premium: $premium");
        debugPrint("   - languageCode: $languageCode");
        debugPrint("   - selectedTopics: $selectedTopics");
        debugPrint("   - pool (count): ${pool.length}");
        debugPrint("   - chosenCategory: $chosenCategory");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
      return _buildOpenToUpdateFallback(languageCode);
    }

    return NotificationQuotePayload(
      quote: chosenText,
      category: chosenCategory,
      signature: chosen['signature'] as String?,
      bookTitle: chosen['bookTitle'] as String?,
      url: chosen['url'] as String?,
        );
  }


  Iterable<tz.TZDateTime> _nextOccurrences(
    tz.TZDateTime now,
    List<bool> weekdaySelection,
    List<_DailySlot> slots,
  ) sync* {
    final location = _localLocation ?? tz.local;
    final selectedWeekdays = <int>[];
    for (var i = 0; i < weekdaySelection.length && i < 7; i++) {
      if (weekdaySelection[i]) {
        // Dart weekday: Monday=1 -> index 0 => Monday.
        selectedWeekdays.add(i + 1);
      }
    }
    if (selectedWeekdays.isEmpty) return;

    // Schedule within the next 7 days window.
    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final candidate = now.add(Duration(days: dayOffset));
      if (!selectedWeekdays.contains(candidate.weekday)) continue;
      for (final slot in slots) {
        final scheduled = tz.TZDateTime(
          location,
          candidate.year,
          candidate.month,
          candidate.day,
          slot.hour,
          slot.minute,
        );
        if (scheduled.isBefore(now)) {
          if (kDebugMode) {
            debugPrint("⏭️  [NotificationService] Notification passée ignorée: ${scheduled.year}-${scheduled.month.toString().padLeft(2, '0')}-${scheduled.day.toString().padLeft(2, '0')} ${scheduled.hour.toString().padLeft(2, '0')}:${scheduled.minute.toString().padLeft(2, '0')}");
          }
          continue;
        }
        yield scheduled;
      }
    }
  }

  List<_DailySlot> _computeDailySlots({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    required int count,
  }) {
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    if (count <= 0) return const [];

    if (count == 1) {
      return [ _DailySlot(startHour, startMinute) ];
    }

    final totalSpan = endMinutes - startMinutes;
    if (totalSpan <= 0) {
      // Invalid span → all at start time.
      return List<_DailySlot>.filled(count, _DailySlot(startHour, startMinute));
    }

    final interval = totalSpan / (count - 1);
    final slots = <_DailySlot>[];
    for (var i = 0; i < count; i++) {
      final minutesFromStart = (startMinutes + (interval * i)).round();
      final hour = (minutesFromStart ~/ 60).clamp(0, 23);
      final minute = (minutesFromStart % 60).clamp(0, 59);
      slots.add(_DailySlot(hour, minute));
    }
    // Ensure final slot ends exactly at end time.
    slots[slots.length - 1] = _DailySlot(endHour, endMinute);
    return slots;
  }

  int _notificationIdFor(tz.TZDateTime when, int index) {
    final base = (when.millisecondsSinceEpoch ~/ 1000) & 0x7fffffff;
    return base ^ (index + 1);
  }

  String _quoteUniqKey(NotificationQuotePayload payload) {
    final buffer = StringBuffer()
      ..write(payload.category)
      ..write('::')
      ..write(payload.quote);
    return buffer.toString();
  }

  String _truncate(String quote, {int maxLength = 140}) {
    final trimmed = quote.trim();
    if (trimmed.length <= maxLength) return trimmed;
    return '${trimmed.substring(0, maxLength - 1).trim()}…';
  }
}

class _DailySlot {
  final int hour;
  final int minute;

  const _DailySlot(this.hour, this.minute);
}

