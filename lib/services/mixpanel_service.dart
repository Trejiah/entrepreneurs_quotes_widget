import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

import '../config/env.dart';

/// Mixpanel analytics service.
class MixpanelService {
  MixpanelService._();

  static final MixpanelService instance = MixpanelService._();

  Mixpanel? _mixpanel;
  bool _isInitialized = false;

  /// Mixpanel project token (loaded from `.env` / `--dart-define`).
  String get _mixpanelToken => Env.mixpanelToken;

  /// Initialize Mixpanel with the project token
  Future<void> init() async {
    if (_isInitialized) return;

    final token = _mixpanelToken;
    if (token.isEmpty) {
      if (kDebugMode) {
        debugPrint('[MixpanelService] ⚠️ MIXPANEL_TOKEN missing — analytics disabled.');
      }
      return;
    }

    try {
      // Wait a bit to make sure native plugins are fully registered
      await Future.delayed(const Duration(milliseconds: 100));
      
      _mixpanel = await Mixpanel.init(
        token,
        trackAutomaticEvents: true,
      );
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('[MixpanelService] ✅ Mixpanel initialized successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[MixpanelService] ❌ Initialization error: $e');
        debugPrint('[MixpanelService] Stack trace: $stackTrace');
      }
      // Do not initialize on error to avoid crashes
      _isInitialized = false;
      _mixpanel = null;
    }
  }

  /// Check whether Mixpanel is initialized
  bool get isInitialized => _isInitialized;

  /// Force immediate flush of queued events (useful before navigation/close).
  /// Await before navigating to give time for network send.
  Future<void> flush() async {
    if (!_isInitialized || _mixpanel == null) return;
    _mixpanel!.flush();
    await Future.delayed(const Duration(milliseconds: 250));
  }

  /// Send an event
  void track(String eventName, [Map<String, dynamic>? properties]) {
    if (!_isInitialized || _mixpanel == null) {
      if (kDebugMode) {
        debugPrint('[MixpanelService] ⚠️ track() called before init()');
      }
      return;
    }
    
    _mixpanel!.track(eventName, properties: properties);
    
    if (kDebugMode) {
      debugPrint('[MixpanelService] 📊 track("$eventName", $properties)');
    }
  }

  /// Identify a user
  void identify(String userId) {
    if (!_isInitialized || _mixpanel == null) {
      if (kDebugMode) {
        debugPrint('[MixpanelService] ⚠️ identify() called before init()');
      }
      return;
    }
    
    _mixpanel!.identify(userId);
    
    if (kDebugMode) {
      debugPrint('[MixpanelService] 👤 identify("$userId")');
    }
  }

  /// Set user profile properties
  void setUserProperties(Map<String, dynamic> properties) {
    if (!_isInitialized || _mixpanel == null) {
      if (kDebugMode) {
        debugPrint('[MixpanelService] ⚠️ setUserProperties() called before init()');
      }
      return;
    }
    
    final people = _mixpanel!.getPeople();
    properties.forEach((key, value) {
      people.set(key, value);
    });
    
    if (kDebugMode) {
      debugPrint('[MixpanelService] 📝 setUserProperties($properties)');
    }
  }

  /// Reset the user (call on sign-out)
  void reset() {
    if (!_isInitialized || _mixpanel == null) {
      if (kDebugMode) {
        debugPrint('[MixpanelService] ⚠️ reset() called before init()');
      }
      return;
    }
    
    _mixpanel!.reset();
    
    if (kDebugMode) {
      debugPrint('[MixpanelService] 🔄 reset()');
    }
  }

  /// Enables/disables tracking
  void optOutTracking() {
    if (!_isInitialized || _mixpanel == null) {
      if (kDebugMode) {
        debugPrint('[MixpanelService] ⚠️ optOutTracking() called before init()');
      }
      return;
    }
    
    _mixpanel!.optOutTracking();
    
    if (kDebugMode) {
      debugPrint('[MixpanelService] 🚫 optOutTracking()');
    }
  }

  void optInTracking() {
    if (!_isInitialized || _mixpanel == null) {
      if (kDebugMode) {
        debugPrint('[MixpanelService] ⚠️ optInTracking() called before init()');
      }
      return;
    }
    
    _mixpanel!.optInTracking();
    
    if (kDebugMode) {
      debugPrint('[MixpanelService] ✅ optInTracking()');
    }
  }
}

