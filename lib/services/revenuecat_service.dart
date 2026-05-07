import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/revenuecat_keys.dart';

/// Subscription events for the listener
enum SubscriptionEventType {
  converted,  // Trial converti en abonnement payant
  renewed,    // Abonnement renouvelé
  optedOut,   // Abonnement annulé (mais toujours actif jusqu'à expiration)
  expired,    // Abonnement expiré
}

class SubscriptionEvent {
  final SubscriptionEventType type;
  final CustomerInfo customerInfo;
  final DateTime? eventDate;
  final String? details;

  SubscriptionEvent({
    required this.type,
    required this.customerInfo,
    this.eventDate,
    this.details,
  });
}

class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  bool _isConfigured = false;
  DateTime? _lastCustomerInfoFetch;
  CustomerInfo? _cachedCustomerInfo;
  
  // Stream for subscription events
  final _subscriptionEventController = StreamController<SubscriptionEvent>.broadcast();
  Stream<SubscriptionEvent> get onSubscriptionEvent => _subscriptionEventController.stream;
  
  // Last known entitlement state to detect changes
  bool? _lastKnownEntitlementState;
  DateTime? _lastKnownExpirationDate;
  bool? _lastKnownWillRenew;
  PeriodType? _lastKnownPeriodType;

  Future<void> ensureConfigured({String? appUserId}) async {
    if (kIsWeb) return;

    final apiKey = resolveRevenueCatApiKey();
    if (apiKey.isEmpty) {
      throw StateError(
        'REVENUECAT_${Platform.isIOS ? "IOS" : "ANDROID"}_KEY est manquant. '
        'Ajoute --dart-define=REVENUECAT_${Platform.isIOS ? "IOS" : "ANDROID"}_KEY=... '
        'à ta commande flutter run.',
      );
    }

    if (!_isConfigured) {
      final configuration = PurchasesConfiguration(apiKey);
      if (appUserId != null && appUserId.isNotEmpty) {
        configuration.appUserID = appUserId;
      }
      await Purchases.configure(configuration);
      _isConfigured = true;
      
      // Set up the listener for subscription changes
      _setupSubscriptionListener();
    } else if (appUserId != null && appUserId.isNotEmpty) {
      await logIn(appUserId);
    }
  }

  Future<void> logIn(String appUserId) async {
    if (kIsWeb || !_isConfigured) return;
    if (appUserId.isEmpty) return;
    try {
      final result = await Purchases.logIn(appUserId);
      _cachedCustomerInfo = result.customerInfo;
      _lastCustomerInfoFetch = DateTime.now();
    } on PlatformException catch (error) {
      debugPrint('[RevenueCat] logIn failed: $error');
    }
  }

  Future<void> logOut() async {
    if (kIsWeb || !_isConfigured) return;
    try {
      await Purchases.logOut();
      _cachedCustomerInfo = null;
      _lastCustomerInfoFetch = null;
    } on PlatformException catch (error) {
      debugPrint('[RevenueCat] logOut failed: $error');
    }
  }

  /// Simplified method: fetch products by their IDs
  Future<List<StoreProduct>> getProducts(List<String> productIds) async {
    if (kIsWeb) throw UnsupportedError('RevenueCat non disponible sur Web.');
    _ensureConfiguredOrThrow();
    final products = await Purchases.getProducts(productIds);
    return products;
  }

  /// Simplified method: buy a product directly
  Future<CustomerInfo> purchaseProduct(StoreProduct product) async {
    if (kIsWeb) throw UnsupportedError('RevenueCat non disponible sur Web.');
    _ensureConfiguredOrThrow();
    final info = await Purchases.purchaseStoreProduct(product);
    _cachedCustomerInfo = info;
    _lastCustomerInfoFetch = DateTime.now();
    
    // Detailed logs in debug mode after successful purchase
    if (kDebugMode && hasActiveEntitlement(info)) {
      _logSubscriptionDetails(info, isNewPurchase: true);
    }
    
    // Check state changes
    _checkSubscriptionStateChanges(info);
    
    return info;
  }

  /// Legacy method using Offerings (kept for compatibility)
  @Deprecated('Utilisez getProducts() pour un abonnement simple')
  Future<Offerings> getOfferings() async {
    if (kIsWeb) throw UnsupportedError('RevenueCat non disponible sur Web.');
    _ensureConfiguredOrThrow();
    final offerings = await Purchases.getOfferings();
    return offerings;
  }

  /// Legacy method using Package (kept for compatibility)
  @Deprecated('Utilisez purchaseProduct() pour un abonnement simple')
  Future<CustomerInfo> purchasePackage(Package package) async {
    if (kIsWeb) throw UnsupportedError('RevenueCat non disponible sur Web.');
    _ensureConfiguredOrThrow();
    final info = await Purchases.purchasePackage(package);
    _cachedCustomerInfo = info;
    _lastCustomerInfoFetch = DateTime.now();
    return info;
  }

  Future<CustomerInfo> restorePurchases() async {
    if (kIsWeb) throw UnsupportedError('RevenueCat non disponible sur Web.');
    _ensureConfiguredOrThrow();
    final info = await Purchases.restorePurchases();
    _cachedCustomerInfo = info;
    _lastCustomerInfoFetch = DateTime.now();
    return info;
  }

  /// Open the system subscription management page (iOS/Android)
  /// The user can cancel their subscription there
  /// Open the platform's native subscription management
  /// 
  /// iOS 16+: Uses native StoreKit 2 - opens a native in-app modal (works in sandbox and production)
  /// Android : Utilise l'URL Google Play
  Future<void> showManageSubscriptions() async {
    if (kIsWeb) throw UnsupportedError('RevenueCat non disponible sur Web.');
    
    if (Platform.isIOS) {
      // iOS : Utilise StoreKit 2 natif via channel platform
      // Open an in-app native modal with Apple's subscription management
      const platform = MethodChannel('businessmindset/revenuecat');
      try {
        await platform.invokeMethod('showManageSubscriptions');
      } on PlatformException catch (e) {
        if (kDebugMode) {
          debugPrint('[REVENUECAT] Error opening manage subscriptions: ${e.code} - ${e.message}');
        }
        rethrow;
      }
    } else if (Platform.isAndroid) {
      // Android: Open the subscription management page in Google Play
      try {
        final uri = Uri.parse('https://play.google.com/store/account/subscriptions');
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          throw Exception('Unable to open the subscription management page.');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[REVENUECAT] Error opening subscription management: $e');
        }
        rethrow;
      }
    } else {
      throw UnsupportedError('Plateforme non supportée pour la gestion d\'abonnements.');
    }
  }

  Future<CustomerInfo> getCustomerInfo({bool forceRefresh = false}) async {
    if (kIsWeb) throw UnsupportedError('RevenueCat non disponible sur Web.');
    _ensureConfiguredOrThrow();

    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedCustomerInfo != null &&
        _lastCustomerInfoFetch != null &&
        now.difference(_lastCustomerInfoFetch!).inMinutes < 5) {
      return _cachedCustomerInfo!;
    }

    final info = await Purchases.getCustomerInfo();
    _cachedCustomerInfo = info;
    _lastCustomerInfoFetch = now;
    
    // Check state changes
    _checkSubscriptionStateChanges(info);
    
    return info;
  }

  bool hasActiveEntitlement(CustomerInfo info) {
    return info.entitlements.active[revenueCatEntitlementId] != null;
  }

  /// Retrieve the expiration date of the premium entitlement
  DateTime? getExpirationDate(CustomerInfo info) {
    final entitlement = info.entitlements.active[revenueCatEntitlementId];
    if (entitlement == null) return null;
    
    // expirationDate may be an ISO8601 String, we need to parse it
    final expirationDateStr = entitlement.expirationDate;
    if (expirationDateStr == null) return null;
    
    try {
      return DateTime.parse(expirationDateStr);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to parse expiration date: $expirationDateStr');
      }
      return null;
    }
  }
  
  /// Convert a UTC date to local time (UTC+4)
  DateTime toLocalTime(DateTime utcDate) {
    return utcDate.add(const Duration(hours: 4));
  }
  
  /// Format a date for logs with local time
  String formatDateTimeLocal(DateTime? date, {bool showUtc = true}) {
    if (date == null) return "N/A";
    final localDate = toLocalTime(date);
    final utcStr = showUtc ? " (UTC: ${date.toIso8601String()})" : "";
    return "${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}:${localDate.second.toString().padLeft(2, '0')} - ${localDate.day}/${localDate.month}/${localDate.year}$utcStr";
  }
  
  /// Check whether the subscription is in trial period
  /// RevenueCat uses PeriodType.trial for free trials
  /// and PeriodType.intro for intro periods (may include trials)
  bool isTrialPeriod(PeriodType? periodType) {
    return periodType == PeriodType.trial || periodType == PeriodType.intro;
  }
  
  /// Retrieve the trial end date (if in trial period)
  DateTime? getTrialEndDate(CustomerInfo info) {
    final entitlement = info.entitlements.active[revenueCatEntitlementId];
    if (entitlement == null) return null;
    
    // If periodType is trial or intro, expirationDate is the trial end
    if (isTrialPeriod(entitlement.periodType)) {
      return getExpirationDate(info);
    }
    return null;
  }
  
  /// Retrieve the renewal date (next billing date)
  DateTime? getRenewalDate(CustomerInfo info) {
    final entitlement = info.entitlements.active[revenueCatEntitlementId];
    if (entitlement == null) return null;
    
    // The renewal date is the expiration date
    // If willRenew is false, there will be no renewal
    if (entitlement.willRenew) {
      return getExpirationDate(info);
    }
    return null;
  }

  Future<bool> isPremium({bool forceRefresh = false}) async {
    if (kIsWeb) return false;
    final info = await getCustomerInfo(forceRefresh: forceRefresh);
    return hasActiveEntitlement(info);
  }

  /// Legacy method using Offerings (kept for compatibility)
  @Deprecated('Non nécessaire avec getProducts()')
  Package? selectDefaultPackage(Offerings offerings) {
    final current = offerings.current;
    if (current == null) return null;
    if (current.availablePackages.isEmpty) return null;

    final annual = current.availablePackages
        .firstWhere(
          (pack) => pack.packageType == PackageType.annual,
          orElse: () => current.availablePackages.first,
        );
    return annual;
  }

  void _ensureConfiguredOrThrow() {
    if (!_isConfigured) {
      throw StateError(
        'RevenueCatService.ensureConfigured doit être appelé avant toute opération.',
      );
    }
  }
  
  /// Set up the listener for RevenueCat subscription changes
  void _setupSubscriptionListener() {
    if (kIsWeb || !_isConfigured) return;
    
    try {
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _cachedCustomerInfo = customerInfo;
        _lastCustomerInfoFetch = DateTime.now();
        _checkSubscriptionStateChanges(customerInfo);
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RevenueCat] Error setting up subscription listener: $e');
      }
    }
  }
  
  /// Check subscription state changes and emit events
  void _checkSubscriptionStateChanges(CustomerInfo info) {
    final hasEntitlement = hasActiveEntitlement(info);
    final expirationDate = getExpirationDate(info);
    final entitlement = info.entitlements.active[revenueCatEntitlementId];
    final willRenew = entitlement?.willRenew ?? false;
    final currentPeriodType = entitlement?.periodType;
    
    // Detect changes
    if (_lastKnownEntitlementState == null) {
      // First check, initialize state
      _lastKnownEntitlementState = hasEntitlement;
      _lastKnownExpirationDate = expirationDate;
      _lastKnownWillRenew = willRenew;
      _lastKnownPeriodType = currentPeriodType;
      return;
    }
    
    // Check whether the subscription has expired
    if (_lastKnownEntitlementState == true && !hasEntitlement) {
      _emitSubscriptionEvent(SubscriptionEventType.expired, info);
      _lastKnownEntitlementState = false;
      _lastKnownExpirationDate = null;
      _lastKnownWillRenew = null;
      _lastKnownPeriodType = null;
      return;
    }
    
    // Check whether the subscription was renewed (new expiration date)
    if (hasEntitlement && expirationDate != null && _lastKnownExpirationDate != null) {
      if (expirationDate.isAfter(_lastKnownExpirationDate!)) {
        // Do not emit "renewed" if it's a trial conversion
        // (the conversion will be detected separately via the periodType change)
        if (!isTrialPeriod(_lastKnownPeriodType) || !isTrialPeriod(currentPeriodType)) {
          _emitSubscriptionEvent(SubscriptionEventType.renewed, info);
        }
      }
    }
    
    // Check whether it's a trial conversion (multiple scenarios)
    if (hasEntitlement && entitlement != null) {
      final periodType = entitlement.periodType;
      
      // Scenario 1: Switch from inactive to active with periodType intro (trial just started)
      // Not really a conversion, but we can log it if needed
      
      // Scenario 2: Subscription was on trial (trial or intro) and is now still active but no longer on trial
      // This is the trial-to-full-subscription conversion
      if (_lastKnownEntitlementState == true && 
          isTrialPeriod(_lastKnownPeriodType) && 
          !isTrialPeriod(periodType)) {
        if (kDebugMode) {
          debugPrint('[RevenueCat] 🔄 Conversion detected: trial → full subscription');
          debugPrint('   - Ancien periodType: $_lastKnownPeriodType');
          debugPrint('   - Nouveau periodType: $periodType');
        }
        _emitSubscriptionEvent(SubscriptionEventType.converted, info);
      }
      
      // Scenario 3: New active subscription with periodType trial or intro (just after purchase)
      // This is the start of the trial, not a conversion
      // We don't emit it as "converted"
    }
    
    // Check opt-out (willRenew goes from true to false while the subscription is still active)
    if (hasEntitlement && 
        entitlement != null && 
        _lastKnownWillRenew == true && 
        !willRenew && 
        expirationDate != null) {
      // Subscription was set to renew but no longer will = opt-out
      _emitSubscriptionEvent(SubscriptionEventType.optedOut, info);
    }
    
    // Update the known state
    _lastKnownEntitlementState = hasEntitlement;
    _lastKnownExpirationDate = expirationDate;
    _lastKnownWillRenew = willRenew;
    _lastKnownPeriodType = currentPeriodType;
  }
  
  /// Emit a subscription event
  void _emitSubscriptionEvent(SubscriptionEventType type, CustomerInfo info) {
    final event = SubscriptionEvent(
      type: type,
      customerInfo: info,
      eventDate: DateTime.now(),
    );
    _subscriptionEventController.add(event);
  }
  
  /// Extract and log subscription details (in debug mode)
  void _logSubscriptionDetails(CustomerInfo info, {bool isNewPurchase = false}) {
    if (!kDebugMode) return;
    
    final entitlement = info.entitlements.active[revenueCatEntitlementId];
    if (entitlement == null) return;
    
    final expirationDate = getExpirationDate(info);
    final periodType = entitlement.periodType;
    final isTrial = isTrialPeriod(periodType);
    final productIdentifier = entitlement.productIdentifier;
    
    // Compute important dates
    final trialEndDate = getTrialEndDate(info);
    final renewalDate = getRenewalDate(info);
    
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    if (isNewPurchase) {
      debugPrint("📋 [RevenueCat] Subscription validated");
    } else {
      debugPrint("📋 [RevenueCat] État de l'abonnement");
    }
    debugPrint("   - Product ID: $productIdentifier");
    debugPrint("   - Period Type: ${periodType.toString()}");
    debugPrint("   - Is Trial: $isTrial");
    
    // Show the original purchase date (start of trial/subscription)
    try {
      final originalPurchaseDateStr = entitlement.originalPurchaseDate;
      final originalPurchaseDate = DateTime.parse(originalPurchaseDateStr);
      debugPrint("   - 📆 Date d'achat originale (UTC+4): ${formatDateTimeLocal(originalPurchaseDate)}");
    } catch (e) {
      // Skip if the date cannot be parsed
    }
    
    if (isTrial && trialEndDate != null) {
      debugPrint("   - 🎁 End of TRIAL period (UTC+4): ${formatDateTimeLocal(trialEndDate)}");
    }
    
    if (renewalDate != null) {
      debugPrint("   - 🔄 Prochain RENEWAL (UTC+4): ${formatDateTimeLocal(renewalDate)}");
    } else if (!isTrial && entitlement.willRenew == false) {
      debugPrint("   - ⚠️ No renewal scheduled (opt-out)");
    }
    
    debugPrint("   - 📅 Date d'expiration (UTC+4): ${formatDateTimeLocal(expirationDate)}");
    debugPrint("   - Will Renew: ${entitlement.willRenew}");
    debugPrint("   - Is Active: ${entitlement.isActive}");
    debugPrint("   - Store: ${entitlement.store}");
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  }
  
  /// Dispose of resources
  void dispose() {
    _subscriptionEventController.close();
  }
}

