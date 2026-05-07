import 'package:flutter/foundation.dart';

import 'revenuecat_service.dart';

/// Returns the true premium expiration timestamp (epoch ms) from RevenueCat.
///
/// We force-refresh CustomerInfo so every widget sync uses the latest store state.
/// If unavailable or on error, returns null and widget should enter fail-safe mode.
Future<int?> fetchWidgetPremiumExpirationEpochMs() async {
  try {
    final info = await RevenueCatService.instance.getCustomerInfo(forceRefresh: true);
    final expiration = RevenueCatService.instance.getExpirationDate(info);
    if (expiration == null) return null;
    return expiration.millisecondsSinceEpoch;
  } catch (error, stack) {
    if (kDebugMode) {
      debugPrint('[WidgetSync] Unable to fetch RevenueCat expiration date: $error');
      debugPrint('$stack');
    }
    return null;
  }
}
