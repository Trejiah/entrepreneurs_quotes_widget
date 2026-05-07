import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiktok_events_sdk/tiktok_events_sdk.dart';

import '../config/revenuecat_keys.dart';
import 'mixpanel_service.dart';

/// TikTok Events SDK service for attribution and conversions.
/// Lets TikTok optimize campaigns (which ad leads to a trial, then to a confirmed purchase).
class TikTokService {
  TikTokService._();

  static final TikTokService instance = TikTokService._();

  bool _isInitialized = false;

  /// TikTok attribution is disabled on Web and Android (no campaigns there).
  /// All public methods short-circuit when this returns true.
  bool get _isPlatformDisabled => kIsWeb || Platform.isAndroid;

  /// Events pending send before SDK init (current session).
  final List<Future<void> Function()> _pendingEvents = [];

  /// SharedPreferences key for critical events persisted across sessions.
  /// Only StartTrial and CompletePayment are persisted (essential attribution events).
  static const _kPersistedEventsKey = 'tiktok_pending_events';

  static const _storeChannel = MethodChannel('businessmindset/store');

  // ─────────────────────────────────────────────────────────
  // PERSISTENCE OF CRITICAL EVENTS
  // ─────────────────────────────────────────────────────────

  /// Save a critical event to SharedPreferences to survive restarts.
  Future<void> _persistEvent(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_kPersistedEventsKey) ?? [];
      existing.add(jsonEncode(data));
      await prefs.setStringList(_kPersistedEventsKey, existing);
      if (kDebugMode) debugPrint('[TikTokService] 💾 Event persisted: ${data['type']}');
    } catch (e) {
      if (kDebugMode) debugPrint('[TikTokService] ⚠️ _persistEvent error: $e');
    }
  }

  /// Remove all persisted events (after successful send).
  Future<void> _clearPersistedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPersistedEventsKey);
    } catch (e) {
      if (kDebugMode) debugPrint('[TikTokService] ⚠️ _clearPersistedEvents error: $e');
    }
  }

  /// Sends events persisted in SharedPreferences (app restart case).
  Future<void> _flushPersistedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kPersistedEventsKey) ?? [];
      if (list.isEmpty) return;

      if (kDebugMode) {
        debugPrint('[TikTokService] 📤 Flushing ${list.length} persisted event(s) (resume after restart)');
      }

      MixpanelService.instance.track('[TikTok] Flush reprise', {
        'count': list.length,
      });

      await prefs.remove(_kPersistedEventsKey);

      for (final raw in list) {
        try {
          final event = jsonDecode(raw) as Map<String, dynamic>;
          final type = event['type'] as String?;
          if (type == 'startTrial') {
            await trackStartTrial(
              contentId: event['contentId'] as String?,
              currencyCode: event['currencyCode'] as String?,
              value: (event['value'] as num?)?.toDouble(),
            );
          } else if (type == 'completePayment') {
            await trackCompletePayment(
              contentId: event['contentId'] as String?,
              contentName: event['contentName'] as String?,
              currencyCode: event['currencyCode'] as String?,
              value: (event['value'] as num?)?.toDouble(),
              quantity: event['quantity'] as int?,
            );
          }
        } catch (e) {
          if (kDebugMode) debugPrint('[TikTokService] ⚠️ Error flushing persisted event: $e');
          MixpanelService.instance.track('[TikTok] Erreur flush persisté', {
            'error': e.toString(),
            'raw': raw,
          });
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[TikTokService] ⚠️ _flushPersistedEvents error: $e');
      MixpanelService.instance.track('[TikTok] Erreur flush persisté', {'error': e.toString()});
    }
  }

  // ─────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────

  /// Return the App Store storefront country code (3 letters: "USA", "FRA"...).
  /// Fallback to [Platform.localeName] if the storefront is unavailable.
  Future<String> _resolveStorefrontCountryCode() async {
    if (kIsWeb) return 'ROW';
    if (Platform.isIOS) {
      try {
        final code = await _storeChannel.invokeMethod<String>('getStorefrontCountryCode');
        if (code != null && code.isNotEmpty) {
          if (kDebugMode) debugPrint('[TikTokService] 🏪 Storefront detected: $code');
          return code.toUpperCase();
        }
      } catch (_) {}
    }
    // Fallback : parser Platform.localeName ("en_US" → "US")
    final parts = Platform.localeName.split(RegExp(r'[_\-]'));
    final fallback = parts.length > 1 ? parts.last.toUpperCase() : '';
    if (kDebugMode) debugPrint('[TikTokService] 🌐 Fallback locale: ${Platform.localeName} → $fallback');
    return fallback.isEmpty ? 'ROW' : fallback;
  }

  /// Initialize the SDK on app launch.
  /// iOS identifiers are selected dynamically based on the App Store storefront:
  /// - Store US  → [tiktokIosAppIdUS] / [tiktokIosIdUS]
  /// - Rest of world → [tiktokIosAppIdROW] / [tiktokIosIdROW]
  /// If resolved IDs are empty, init is skipped (no crash).
  Future<void> init() async {
    if (_isInitialized) return;
    if (_isPlatformDisabled) {
      if (kDebugMode && !kIsWeb) {
        debugPrint('[TikTokService] ⏭️ Android: TikTok SDK init skipped (no attribution).');
      }
      return;
    }

    // StoreKit returns 3 letters ("USA"), the locale fallback 2 letters ("US").
    final String rawCode = await _resolveStorefrontCountryCode();
    final bool isUS = rawCode == 'USA' || rawCode == 'US';
    final String countryCode = rawCode;

    final aAppId = tiktokAndroidAppId.trim();
    final aId = tiktokAndroidId.trim();
    final iAppId = (isUS ? tiktokIosAppIdUS : tiktokIosAppIdROW).trim();
    final iId = (isUS ? tiktokIosIdUS : tiktokIosIdROW).trim();

    if (aAppId.isEmpty && aId.isEmpty && iAppId.isEmpty && iId.isEmpty) {
      if (kDebugMode) {
        debugPrint('[TikTokService] ⏭️ TikTok IDs not configured for region $countryCode — SDK not initialized.');
      }
      return;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final androidOptions = TikTokAndroidOptions(
        disableAutoStart: false,
        enableAutoIapTrack: false, // on envoie nous-mêmes StartTrial / CompletePayment
        disableAdvertiserIDCollection: false,
      );
      // disableTracking: false + disableAutomaticTracking: true
      // The SDK can work without IDFA (will be zeros if no ATT authorization)
      final iosOptions = TikTokIosOptions(
        disableTracking: false,
        disableAutomaticTracking: true,
        disableSKAdNetworkSupport: false,
      );

      await TikTokEventsSdk.initSdk(
        androidAppId: aAppId,
        tikTokAndroidId: aId,
        iosAppId: iAppId,
        tiktokIosId: iId,
        isDebugMode: kDebugMode,
        logLevel: kDebugMode ? TikTokLogLevel.debug : TikTokLogLevel.info,
        androidOptions: androidOptions,
        iosOptions: iosOptions,
      );

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('[TikTokService] ✅ TikTok initialisé — région: $countryCode (compte ${isUS ? "US" : "ROW"})');
      }

      if (_pendingEvents.isNotEmpty) {
        // Current session: flush memory + clear SharedPreferences (same events)
        if (kDebugMode) {
          debugPrint('[TikTokService] 📤 Flush de ${_pendingEvents.length} event(s) en attente (session courante)');
        }
        final toFlush = List<Future<void> Function()>.from(_pendingEvents);
        _pendingEvents.clear();
        for (final event in toFlush) {
          await event();
        }
        // Events were just sent via memory → purge disk
        await _clearPersistedEvents();
      } else {
        // App restart: memory empty, try to recover from SharedPreferences
        await _flushPersistedEvents();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[TikTokService] ❌ Init error: $e');
        debugPrint('[TikTokService] $stackTrace');
      }
      _isInitialized = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // ATT
  // ─────────────────────────────────────────────────────────

  /// Shows the ATT (App Tracking Transparency) popup on iOS and returns the response.
  /// Must be called BEFORE TikTok SDK initialization and any data collection.
  /// Retourne : "authorized", "denied", "restricted", "not_determined", "not_applicable", "error"
  Future<String> requestATT() async {
    if (kIsWeb) return 'not_applicable';
    if (!Platform.isIOS) return 'not_applicable';
    try {
      final status = await _storeChannel.invokeMethod<String>('requestATT');
      if (kDebugMode) debugPrint('[TikTokService] 📱 ATT request result: $status');
      return status ?? 'not_determined';
    } catch (e) {
      if (kDebugMode) debugPrint('[TikTokService] ⚠️ requestATT error: $e');
      return 'error';
    }
  }

  /// Read the ATT (App Tracking Transparency) status on iOS.
  /// Retourne : "authorized", "denied", "restricted", "not_determined", "not_applicable", "error"
  Future<String> getATTStatus() async {
    if (kIsWeb) return 'not_applicable';
    if (!Platform.isIOS) return 'not_applicable';
    try {
      final status = await _storeChannel.invokeMethod<String>('getATTStatus');
      return status ?? 'not_determined';
    } catch (e) {
      if (kDebugMode) debugPrint('[TikTokService] ⚠️ getATTStatus error: $e');
      return 'error';
    }
  }

  bool get isInitialized => _isInitialized;

  // ─────────────────────────────────────────────────────────
  // EVENTS
  // ─────────────────────────────────────────────────────────

  /// Sends the "LaunchAPP" event — app open (TikTok standard).
  Future<void> trackLaunchApp() async {
    if (_isPlatformDisabled) return;
    if (!_isInitialized) return;
    try {
      await TikTokEventsSdk.logEvent(
        event: TikTokEvent(eventName: BaseEventName.launchApp.value),
      );
      if (kDebugMode) {
        debugPrint('[TikTokService] 📤 LaunchAPP sent');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TikTokService] ⚠️ trackLaunchApp error: $e');
      }
    }
  }

  /// Sends the "OpenPaywall" event — paywall page opened (custom event).
  /// Not persisted across sessions (navigation event, not critical for attribution).
  Future<void> trackOpenPaywall() async {
    if (_isPlatformDisabled) return;
    if (!_isInitialized) {
      _pendingEvents.add(() => trackOpenPaywall());
      return;
    }
    try {
      await TikTokEventsSdk.logEvent(
        event: TikTokEvent(
          eventName: 'OpenPaywall',
          properties: const EventProperties(
            contentName: 'paywall',
            contentType: 'screen_view',
          ),
        ),
      );
      if (kDebugMode) {
        debugPrint('[TikTokService] 📤 OpenPaywall sent');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TikTokService] ⚠️ trackOpenPaywall error: $e');
      }
    }
  }

  /// Sends the "Start Trial" event — the user started a free trial.
  /// Persisted in SharedPreferences to survive a restart before SDK init.
  Future<void> trackStartTrial({
    String? contentId,
    String? currencyCode,
    double? value,
  }) async {
    if (_isPlatformDisabled) return;
    if (!_isInitialized) {
      _pendingEvents.add(() => trackStartTrial(contentId: contentId, currencyCode: currencyCode, value: value));
      // Persist to disk to survive a kill before TikTok init
      await _persistEvent({
        'type': 'startTrial',
        'contentId': contentId,
        'currencyCode': currencyCode,
        'value': value,
      });
      return;
    }

    try {
      final properties = EventProperties(
        contentId: contentId,
        currency: _currencyFromString(currencyCode),
        value: value,
        description: 'free_trial_start',
      );
      await TikTokEventsSdk.logEvent(
        event: TikTokEvent(
          eventName: BaseEventName.startTrial.value,
          properties: properties,
        ),
      );
      if (kDebugMode) {
        debugPrint('[TikTokService] 📤 StartTrial sent (contentId: $contentId, value: $value)');
      }
      MixpanelService.instance.track('[TikTok] StartTrial envoyé', {
        'contentId': contentId,
        'currencyCode': currencyCode,
        'value': value,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TikTokService] ⚠️ trackStartTrial error: $e');
      }
      MixpanelService.instance.track('[TikTok] Erreur StartTrial', {'error': e.toString()});
    }
  }

  /// Sends the "CompletePayment" event — subscription confirmed (trial ended, first real payment).
  /// Persisted in SharedPreferences to survive a restart before SDK init.
  Future<void> trackCompletePayment({
    String? contentId,
    String? contentName,
    String? currencyCode,
    double? value,
    int? quantity,
  }) async {
    if (_isPlatformDisabled) return;
    if (!_isInitialized) {
      _pendingEvents.add(() => trackCompletePayment(
        contentId: contentId, contentName: contentName,
        currencyCode: currencyCode, value: value, quantity: quantity,
      ));
      // Persist to disk to survive a kill before TikTok init
      await _persistEvent({
        'type': 'completePayment',
        'contentId': contentId,
        'contentName': contentName,
        'currencyCode': currencyCode,
        'value': value,
        'quantity': quantity,
      });
      return;
    }

    try {
      final properties = EventProperties(
        contentId: contentId,
        contentName: contentName,
        currency: _currencyFromString(currencyCode),
        value: value,
        quantity: quantity ?? 1,
        description: 'subscription_trial_converted',
      );
      await TikTokEventsSdk.logEvent(
        event: TikTokEvent(
          eventName: 'CompletePayment',
          properties: properties,
        ),
      );
      if (kDebugMode) {
        debugPrint('[TikTokService] 📤 CompletePayment sent (contentId: $contentId, value: $value)');
      }
      MixpanelService.instance.track('[TikTok] CompletePayment envoyé', {
        'contentId': contentId,
        'contentName': contentName,
        'currencyCode': currencyCode,
        'value': value,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TikTokService] ⚠️ trackCompletePayment error: $e');
      }
      MixpanelService.instance.track('[TikTok] Erreur CompletePayment', {'error': e.toString()});
    }
  }

  static CurrencyCode? _currencyFromString(String? code) {
    if (code == null || code.isEmpty) return null;
    return CurrencyCode.fromString(code.toUpperCase());
  }
}
