import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/features/paywall/model/paywall_models.dart';
import 'package:businessmindset/features/paywall/view_model/paywallb_provider.dart';
import 'package:businessmindset/features/home/view/home_page.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:businessmindset/providers/cross_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/services/hard_paywall_service.dart';
import 'package:businessmindset/services/revenuecat_service.dart';
import 'package:businessmindset/services/trial_duration_ab_service.dart';
import 'package:businessmindset/config/revenuecat_keys.dart';
import 'onboarding_restore_flow.dart';

class OnBoarding33b extends ConsumerStatefulWidget {
  const OnBoarding33b({
    super.key,
    this.forward,
  });
  final Function(int)? forward;

  @override
  ConsumerState<OnBoarding33b> createState() => _OnBoarding33State();
}

class _OnBoarding33State extends ConsumerState<OnBoarding33b> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  final PageController _pageController = PageController();
  final PageController _whatsIncludedController = PageController();
  int _currentWhatsIncludedPage = 0;

  final Map<String, double> _percentages = {};

  StoreProduct? _annualProduct;
  StoreProduct? _monthlyProduct;
  bool _isYearlySelected = true;
  bool _isLoadingPackage = false;
  bool _isEligibleForTrial = true; // Éligibilité au trial (vérifiée avant paiement)
  bool _isCheckingTrialEligibility = true; // Indique si on est en train de vérifier l'éligibilité
  int _trialDays = 7;

  Future<void> _goHomeFromRestoreFlow({required bool skipRevenueCatCheck}) async {
    await OnboardingRestoreFlow.prepareGoHome(skipRevenueCatCheck: skipRevenueCatCheck);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  final List<String> _categoryKeys = ['growth', 'discipline', 'confidence', 'strategy'];
  // The 3 "What's included" screens (same structure as paywallb)
  List<List<Map<String, String>>> _getWhatsIncludedScreens(String lang) {
    return [
      [
        {
          'image': 'mockup-paywall-yourplan.png',
          'textKey': 'personalized_quote_feed_tail',
        },
      ],
      [
        {
          'image': 'paywall-categories.png',
          'textKey': 'categories_exclu',
        },
      ],
      [
        {
          'image': 'mockup-paywall-theme.png',
          'textKey': 'customized_app',
        },
      ],
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeRevenueCat();
    _checkTrialEligibility();
    _determineTrialDays();
    _whatsIncludedController.addListener(() {
      setState(() {
        _currentWhatsIncludedPage = _whatsIncludedController.page?.round() ?? 0;
      });
    });
  }

  /// Check whether the user is eligible for a trial before payment
  ///
  /// IMPORTANT: This method works even if the user is not signed in to Firebase!
  ///
  /// How it works:
  /// - RevenueCat automatically uses the store account identifier (Apple ID or Google Play)
  ///   even if no Firebase account is signed in
  /// - We call restorePurchases() to force store sync and retrieve
  ///   the complete purchase history
  /// - If a user downloads the app with a store account that previously subscribed
  ///   (even on another device or another install), RevenueCat can detect
  ///   this subscription history via the store account
  ///
  /// A user is eligible for a trial if they've never had an active or expired subscription.
  ///
  /// NOTE: We use getCustomerInfo(forceRefresh: true) instead of restorePurchases()
  /// to avoid prompting a store account login if the user isn't signed in.
  /// getCustomerInfo retrieves available information without forcing a connection.
  Future<void> _checkTrialEligibility() async {
    debugPrint('🔍 [OnBoarding33] ===== STARTING TRIAL ELIGIBILITY CHECK =====');

    if (kIsWeb) {
      debugPrint('🌐 [OnBoarding33] Running on Web - defaulting to eligible');
      setState(() {
        _isEligibleForTrial = true; // Par défaut sur Web
        _isCheckingTrialEligibility = false;
      });
      return;
    }

    setState(() {
      _isCheckingTrialEligibility = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      debugPrint('👤 [OnBoarding33] Firebase userId: $userId');
      // Even if userId is null, RevenueCat will automatically use the store account
      await RevenueCatService.instance.ensureConfigured(appUserId: userId);
      debugPrint('✅ [OnBoarding33] RevenueCat configured');

      // Use getCustomerInfo with forceRefresh instead of restorePurchases()
      // to avoid prompting a store account login if the user isn't signed in
      // getCustomerInfo retrieves store information without forcing a connection
      debugPrint('📡 [OnBoarding33] Fetching customerInfo with forceRefresh...');
      final info = await RevenueCatService.instance.getCustomerInfo(forceRefresh: true);

      debugPrint('📋 [OnBoarding33] CustomerInfo received:');
      debugPrint('  - originalAppUserId: ${info.originalAppUserId}');
      debugPrint('  - activeSubscriptions: ${info.activeSubscriptions}');
      debugPrint('  - allPurchasedProductIdentifiers: ${info.allPurchasedProductIdentifiers}');
      debugPrint('  - entitlements.active keys: ${info.entitlements.active.keys.toList()}');
      debugPrint('  - entitlements.all keys: ${info.entitlements.all.keys.toList()}');

      // Log each entitlement in detail
      info.entitlements.all.forEach((key, entitlement) {
        debugPrint('  📦 Entitlement "$key":');
        debugPrint('      isActive: ${entitlement.isActive}');
        debugPrint('      willRenew: ${entitlement.willRenew}');
        debugPrint('      periodType: ${entitlement.periodType}');
        debugPrint('      expirationDate: ${entitlement.expirationDate}');
        debugPrint('      productIdentifier: ${entitlement.productIdentifier}');
      });

      // Trial eligibility detection: !hasActive && !hasHistory logic
      //
      // This logic determines whether to show "Try for free" or "Let's go" to the user.
      // It is based on RevenueCat data, but Apple/Google ultimately decides
      // at payment time whether the trial is actually available.
      //
      // IMPORTANT: This detection CANNOT know if eligibility was reset
      // in App Store Connect. It's a technical limitation; only Apple/Google
      // knows this information at purchase time.

      final hasActiveEntitlement = RevenueCatService.instance.hasActiveEntitlement(info);
      final allEntitlements = info.entitlements.all;
      final activeEntitlement = info.entitlements.active[revenueCatEntitlementId];

      // Check whether the user has a subscription history
      // History exists if an inactive entitlement (isActive = false) is present
      bool hasSubscriptionHistory = false;
      if (allEntitlements.isNotEmpty) {
        for (final entitlement in allEntitlements.values) {
          if (!entitlement.isActive) {
            hasSubscriptionHistory = true;
            break;
          }
        }
      }

      // For logs only
      final nonSubscriptionTransactions = info.nonSubscriptionTransactions;
      final hasNonSubscriptionPurchases = nonSubscriptionTransactions.isNotEmpty;

      // Final eligibility logic: !hasActive && !hasHistory
      // - If no active subscription AND no history → eligible (shows "Try for free")
      // - Otherwise → not eligible (shows "Let's go")
      final isEligible = !hasActiveEntitlement && !hasSubscriptionHistory;

      debugPrint('🧮 [OnBoarding33] ELIGIBILITY CALCULATION (Logic: !hasActive && !hasHistory):');
      debugPrint('  - hasActiveEntitlement: $hasActiveEntitlement');
      debugPrint('  - hasSubscriptionHistory: $hasSubscriptionHistory');
      debugPrint('  - hasNonSubscriptionPurchases: $hasNonSubscriptionPurchases (not used in logic)');
      debugPrint('  - RESULT isEligible: $isEligible');
      if (isEligible) {
        debugPrint('  ✅ Will display: "Try for free"');
      } else {
        debugPrint('  ❌ Will display: "Let\'s go"');
      }
      debugPrint('  ⚠️ Note: Apple/Google decides final eligibility at purchase time');
      debugPrint('🔍 [OnBoarding33] ===== END TRIAL ELIGIBILITY CHECK =====');

      if (mounted) {
        setState(() {
          _isEligibleForTrial = isEligible;
          _isCheckingTrialEligibility = false;
        });
      }

      if (kDebugMode) {
        final isConnected = userId != null;
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('[OnBoarding33] Trial eligibility summary:');
        debugPrint('  - Logic used: !hasActive && !hasHistory');
        debugPrint('  - Firebase account connected: $isConnected');
        debugPrint('  - Has active entitlement: $hasActiveEntitlement');
        debugPrint('  - Has subscription history: $hasSubscriptionHistory');
        debugPrint('  - Has non-subscription purchases: $hasNonSubscriptionPurchases');
        debugPrint('  - Total entitlements: ${allEntitlements.length}');
        debugPrint('  - Non-subscription transactions: ${nonSubscriptionTransactions.length}');
        if (activeEntitlement != null) {
          debugPrint('  - Active entitlement periodType: ${activeEntitlement.periodType}');
          debugPrint('  - Active entitlement willRenew: ${activeEntitlement.willRenew}');
        }
        debugPrint('  - ✨ Eligible for trial: $_isEligibleForTrial');
        debugPrint('  - Button text: ${_isEligibleForTrial ? "Try for free" : "Let\'s go"}');
        if (!isConnected) {
          debugPrint('  - ℹ️ Note: Without Firebase, RevenueCat uses store account (Apple ID/Google Play)');
        }
        if (hasSubscriptionHistory && !hasActiveEntitlement) {
          debugPrint('  - ⚠️ Has expired subscription history → NOT eligible');
        }
        debugPrint('  - ⚠️ Cannot detect if Apple eligibility was reset (App Store Connect)');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
    } catch (error, stackTrace) {
      debugPrint('❌ [OnBoarding33] Failed to check trial eligibility: $error');
      debugPrint('❌ [OnBoarding33] StackTrace: $stackTrace');
      // On error, assume the user is eligible (default)
      // The store will ultimately decide at payment time
      if (mounted) {
        setState(() {
          _isEligibleForTrial = true;
          _isCheckingTrialEligibility = false;
        });
      }
    }
  }

  Future<void> _initializeRevenueCat() async {
    if (kIsWeb) return;

    setState(() {
      _isLoadingPackage = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await RevenueCatService.instance.ensureConfigured(appUserId: userId);

      final prefs = await SharedPreferences.getInstance();
      final trialDays = await TrialDurationAbService.getAssignedTrialDays(prefs);
      final annualId = getAnnualSubscriptionProductIdForTrialDays(trialDays);
      final monthlyId = getSubscriptionProductIdMonthly();

      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint('Fetching products: $annualId, $monthlyId');
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }

      final products = await RevenueCatService.instance.getProducts([annualId, monthlyId]);

      if (!mounted) return;

      StoreProduct? annual;
      StoreProduct? monthly;
      for (final p in products) {
        final base = baseProductId(p.identifier);
        if (base == annualId) annual = p;
        if (base == monthlyId) monthly = p;
      }

      setState(() {
        _annualProduct = annual;
        _monthlyProduct = monthly;
        _isLoadingPackage = false;
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to initialize RevenueCat: $error');
      }
      setState(() {
        _isLoadingPackage = false;
      });
    }
  }

  Future<void> _determineTrialDays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (kIsWeb) {
        final d = await TrialDurationAbService.getAssignedTrialDays(prefs);
        if (mounted) setState(() => _trialDays = d);
        return;
      }
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await RevenueCatService.instance.ensureConfigured(appUserId: userId);
      final info = await RevenueCatService.instance.getCustomerInfo(forceRefresh: true);
      final days = await TrialDurationAbService.resolveTrialDaysFromCustomerInfo(info, prefs);
      if (mounted) setState(() => _trialDays = days);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to determine trial days: $error');
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        final d = await TrialDurationAbService.getAssignedTrialDays(prefs);
        if (mounted) setState(() => _trialDays = d);
      } catch (_) {
        if (mounted) setState(() => _trialDays = 7);
      }
    }
  }

  Future<void> _purchaseSubscription() async {
    final product = _isYearlySelected ? _annualProduct : _monthlyProduct;
    if (product == null) {
      if (kDebugMode) {
        debugPrint('No product available for purchase');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              translate("no_subscription_available", ref.watch(languageProvider)),
              style: TextStyle(fontFamily: "InterTight"),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      setState(() {
        _isLoadingPackage = true;
      });

      final info = await RevenueCatService.instance.purchaseProduct(product);

      if (RevenueCatService.instance.hasActiveEntitlement(info)) {
        // Purchase successful
        if (kDebugMode) {
          debugPrint('Purchase successful!');
        }
        setState(() {
          _isLoadingPackage = false;
        });
        // Save premium status using the shared paywall VM logic.
        final paywallVm = ref.read(
          paywallbViewModelProvider(
            const PaywallbInput(
              pageStyle: 'onboarding33b',
              title: '',
              subTitle: '',
              choiceList: <String>[],
              backIcon: true,
              skipLink: false,
            ),
          ).notifier,
        );
        await paywallVm.markPremiumUnlocked(info);
        final prefs = await SharedPreferences.getInstance();
        final entitlement = info.entitlements.active[revenueCatEntitlementId];
        final isInTrial =
            entitlement != null && RevenueCatService.instance.isTrialPeriod(entitlement.periodType);
        // Snapshot `show_item` on every validated subscription (trial or direct purchase without trial).
        await HardPaywallService.saveRcSnapshotAtTrial(
          prefs,
          ref.read(crossShowItemProvider),
        );
        // Keep onboarding-specific trial snapshot behavior.
        if (kDebugMode) {
          debugPrint('[Onboarding33b] Premium unlocked, trial: $isInTrial');
        }
        // Navigation after successful purchase - call forward(2)
        if (widget.forward != null) {
          widget.forward!(2);
        }
      } else {
        if (kDebugMode) {
          debugPrint('Purchase completed but no active entitlement found');
        }
        setState(() {
          _isLoadingPackage = false;
        });
      }
    } on PlatformException catch (error) {
      setState(() {
        _isLoadingPackage = false;
      });

      // Handle cancel or error
      final errorCode = PurchasesErrorHelper.getErrorCode(error);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        if (kDebugMode) {
          debugPrint('Purchase cancelled by user');
        }
        // Cancel = open the popup
        if (mounted) {
          _showCancelDialog();
        }
      } else {
        if (kDebugMode) {
          debugPrint('Purchase failed: $error');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Purchase failed: $error');
      }
      setState(() {
        _isLoadingPackage = false;
      });
    }
  }

  String _getFormattedPriceText(String lang,bool isYearlySelected) {
    if(isYearlySelected){
      if (_annualProduct == null) {
        return translate("free_trial_text", lang)
            .replaceAll("%TRIAL_DAYS%", '${_trialDays}')
            .replaceAll("%PRICE_YEAR%", "...")
            .replaceAll("%PRICE_MONTH%", "...");
      }

      final yearPrice = _annualProduct!.priceString;
      final yearPriceValue = _annualProduct!.price;
      final monthPriceValue = (yearPriceValue / 12);

      // Extract the currency symbol
      final currencySymbol = yearPrice.replaceAll(RegExp(r'[\d\s,.]'), '').trim();

      // Format the monthly price
      final monthPrice = currencySymbol.isEmpty
          ? monthPriceValue.toStringAsFixed(2)
          : '$currencySymbol${monthPriceValue.toStringAsFixed(2)}';

      if(_isEligibleForTrial){
        return translate("free_trial_text", lang)
            .replaceAll("%TRIAL_DAYS%", '${_trialDays}')
            .replaceAll("%PRICE_YEAR%", yearPrice)
            .replaceAll("%PRICE_MONTH%", monthPrice);
      }else{
        return translate("free_trial_text2", lang)
            .replaceAll("%PRICE_YEAR%", yearPrice)
            .replaceAll("%PRICE_MONTH%", monthPrice);
      }
    }else{
      if (_monthlyProduct == null) {
        return translate("free_trial_text", lang)
            .replaceAll("%TRIAL_DAYS%", '${_trialDays}')
            .replaceAll("%PRICE_YEAR%", "...")
            .replaceAll("%PRICE_MONTH%", "...");
      }

      final monthPrice = _monthlyProduct!.priceString;
      return translate("free_trial_text3", lang)
          .replaceAll("%PRICE_MONTH%", monthPrice);
    }
  }

  /// Build a list of TextSpan with different sizes
  /// The ($price/year) part is shown in w600
  List<TextSpan> _buildPriceTextSpans(String text, double xFact) {
    final List<TextSpan> spans = [];

    // Regular expression to find parts containing the price and year/month
    // Format: $price/year (without parentheses) or ($price/month) (with parentheses)
    // Look for either "price/year" or "(price/month)" or "(price/year)"
    final RegExp pricePattern = RegExp(r'(\([^)]+/(?:year)\)|[^\s(]+/year)');

    int lastIndex = 0;

    for (final match in pricePattern.allMatches(text)) {
      // Add the text before the match
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
        ));
      }

      // Add the price part in 15pt
      spans.add(TextSpan(
        text: match.group(0)!,
        style: TextStyle(
            fontSize: 16 * xFact,
        ),
      ));

      lastIndex = match.end;
    }

    // Add the remaining text after the last match
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
      ));
    }

    // If no match was found, return the whole text
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }

    return spans;
  }

  Future<void> _openPrivacyPage() async {
    const url = "https://landing-business-mindset.web.app/privacy.html";

    if (!await launchUrlString(url, mode: LaunchMode.externalApplication)) {
      if (kDebugMode) {
        debugPrint("Impossible d'ouvrir la page de confidentialité : $url");
      }
    }
  }

  Future<void> _openTermsPage() async {
    const url = "https://landing-business-mindset.web.app/terms.html";

    if (!await launchUrlString(url, mode: LaunchMode.externalApplication)) {
      if (kDebugMode) {
        debugPrint("Impossible d'ouvrir les conditions d'utilisation : $url");
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _whatsIncludedController.dispose();
    super.dispose();
  }

  /// Container for the Yearly or Monthly plan (same logic as paywallb).
  Widget _buildPlanContainer({
    required BuildContext context,
    required String lang,
    required bool isYearly,
    required bool isSelected,
    required String priceLabel,
    String? badgePercent,
    String? badgeFree,
  }) {
    final containerHeight = 65.0 * yFact;
    final badgeHeight = 24.0 * yFact;

    Widget content = Container(
      height: containerHeight,
      decoration: BoxDecoration(
        color: appTheme.background,
        borderRadius: BorderRadius.circular(16 * xFact),
        border: Border.all(
          color: isSelected ? appTheme.onPrimButtonGold : appTheme.onBackgroundSub,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16 * xFact, vertical: 0 * yFact),
      child: Row(
        children: [
          Container(
            width: 24 * xFact,
            height: 24 * xFact,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? appTheme.onPrimButtonGold : appTheme.background,
              border: Border.all(
                color: isSelected ? appTheme.onPrimButtonGold : appTheme.onBackground,
                width: 2,
              ),
            ),
            child: isSelected
                ? Icon(Icons.check, size: 20 * xFact, color: appTheme.onBackground)
                : null,
          ),
          SizedBox(width: 12 * xFact),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isYearly ? 'Yearly' : 'Monthly',
                  style: TextStyle(
                    fontFamily: 'InterTight',
                    fontSize: 20 * xFact,
                    fontWeight: FontWeight.w700,
                    color: appTheme.onBackground,
                  ),
                ),
                Text(
                  priceLabel,
                  style: TextStyle(
                    fontFamily: 'InterTight',
                    fontSize: 16 * xFact,
                    color: appTheme.onBackground,
                  ),
                ),
              ],
            ),
          ),
          if (badgeFree != null && _isEligibleForTrial)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8 * xFact, vertical: 4 * yFact),
              child: Text(
                badgeFree,
                style: TextStyle(
                  fontFamily: 'InterTight',
                  fontSize: 21 * xFact,
                  fontWeight: FontWeight.w600,
                  color: appTheme.onPrimButtonGold,
                ),
              ),
            ),
        ],
      ),
    );

    if (badgePercent != null && _isEligibleForTrial) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            top: -badgeHeight / 2,
            right: 30 * xFact,
            child: Container(
              height: 25 * yFact,
              width: 95 * xFact,
              padding: EdgeInsets.symmetric(horizontal: 10 * xFact, vertical: 0 * yFact),
              decoration: BoxDecoration(
                color: appTheme.onPrimButtonGold,
                borderRadius: BorderRadius.circular(8 * xFact),
              ),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: MediaQuery.textScalerOf(context).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.1),
                ),
                child: Center(
                  child: Text(
                    badgePercent,
                    style: TextStyle(
                      fontFamily: 'InterTight',
                      fontSize: 16 * xFact,
                      fontWeight: FontWeight.w700,
                      color: appTheme.background,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isYearlySelected = isYearly;
        });
      },
      child: content,
    );
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load percentages
    for (var key in _categoryKeys) {
      final percentage = prefs.getDouble("plan_${key}_percentage");
      if (percentage != null) {
        _percentages[key] = percentage;
      } else {
        _percentages[key] = 25.0; // Valeur par défaut
      }
    }

    if (kDebugMode) {
      debugPrint("📊 [OnBoarding33] Data loaded:");
      debugPrint("  Pourcentages: $_percentages");
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> saveRefusalDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("subscriptionRefusedDate", DateTime.now().millisecondsSinceEpoch);
    if (kDebugMode) {
      debugPrint('Subscription refused date saved');
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF575757),
            borderRadius: BorderRadius.circular(15 * xFact),
          ),
          padding: EdgeInsets.only(left : 20 * xFact,right: 20 * xFact,top: 10 * xFact,bottom: 10 * xFact),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Flamy sad
              SizedBox(
                width: 120 * xFact,
                child: Image.asset(
                  'assets/images/flamy/flamy_sad.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.sentiment_very_dissatisfied,
                        size: 120 * xFact,
                        color: appTheme.onBackground);
                  },
                ),
              ),
              SizedBox(height: 20 * yFact),
              // Texte "Are you sure?"
              Text(
                translate("aresure", ref.watch(languageProvider)),
                style: TextStyle(
                  fontFamily: "YesevaOne",
                  fontSize: 24 * xFact,
                  color: appTheme.onBackground,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15 * yFact),
              // Message
              Text(
                translate("cancel_trial_message", ref.watch(languageProvider)),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "InterTight",
                  fontSize: 14 * xFact,
                  color: appTheme.onBackground,
                ),
              ),
              SizedBox(height: 35 * yFact),
              // Bouton "Keep my plan"
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                  text: translate("keep_my_plan", ref.watch(languageProvider)),
                  onTap: () {
                    Navigator.pop(context);
                    //_purchaseSubscription();
                  },
                ),
              ),
              SizedBox(height: 10 * yFact),
              // Bouton "Cancel my free trial"
              TextButton(
                onPressed: () async {
                  final nav = Navigator.of(this.context);
                  await saveRefusalDate();
                  if (!mounted) return;
                  nav.pop();
                  if (widget.forward != null) {
                      widget.forward!(3);
                  }
                },
                child: Text(
                  translate("cancel_free_trial", ref.watch(languageProvider)),
                  style: TextStyle(
                    fontFamily: "InterTight",
                    fontSize: 16 * xFact,
                    color: appTheme.onBackground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final showCloseCross = ref.watch(crossShowItemProvider);
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    final blodText = MediaQuery.of(context).boldText;

    if (_isLoadingPackage) {
      return Container(
        height: double.maxFinite,
        width: double.maxFinite,
        color: appTheme.background,
      );
    }

    final textScaler = MediaQuery.textScalerOf(context);
    final cappedScale = textScaler.scale(1.0).clamp(1.0, 1.20);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(cappedScale),
      ),
      child: Container(
        height: double.maxFinite,
        width: double.maxFinite,
        color: appTheme.background,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              if (showCloseCross)
                Positioned(
                  top: 15 * yFact,
                  left: 20 * xFact,
                  child: GestureDetector(
                    onTap: _showCancelDialog,
                    child: Container(
                      width: 40 * xFact,
                      height: 40 * xFact,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: Icon(
                        Icons.close,
                        color: appTheme.onBackground,
                        size: 22 * xFact,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(top: 25 * yFact, left: 20 * xFact, right: 20 * xFact),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.0),
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: const TextScaler.linear(1.0),
                        ),
                        child: Text(
                          translate("get_full_acces", lang),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "YesevaOne",
                            fontSize: 32 * xFact,
                            color: appTheme.onBackground,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 5 * yFact),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25.0),
                      child: SizedBox(
                        height: textScale > 1.1 ? 85 * yFact : blodText ? 80 * yFact : 60 * yFact,
                        child: Builder(
                          builder: (context) {
                            final String textKey = (_getWhatsIncludedScreens(lang)[_currentWhatsIncludedPage][0])["textKey"] ?? "";
                            return Text(
                              translate(textKey, lang),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: "InterTight",
                                fontSize: 18 * xFact,
                                color: appTheme.onBackground,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 0 * yFact),
                    Container(
                      height: textScale > 1.2 ? 200 * yFact : textScale > 1.1 ? 230 * yFact : blodText ? 245 * yFact : 280 * yFact,
                      child: PageView.builder(
                        controller: _whatsIncludedController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentWhatsIncludedPage = index;
                          });
                        },
                        itemCount: _getWhatsIncludedScreens(lang).length,
                        itemBuilder: (context, index) {
                          final screen = _getWhatsIncludedScreens(lang)[index];
                          return Stack(
                            children: [
                              for (var item in screen)
                                Stack(
                                  children: [
                                    Center(
                                      child: SizedBox(
                                        width: 250,
                                        height: double.maxFinite,
                                        child: Image.asset(
                                          'assets/images/${item['image']}',
                                          fit: BoxFit.fitWidth,
                                          alignment: Alignment.topCenter,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.image,
                                              size: 30 * xFact,
                                              color: appTheme.onBackground,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            appTheme.background.withValues(alpha: 0),
                                            appTheme.background,
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          stops: [0.2, 0.95],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(height: textScale > 1.3 ? 0 * yFact : 10 * yFact),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < _getWhatsIncludedScreens(lang).length; i++)
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 8 * xFact),
                            width: 10 * xFact,
                            height: 10 * xFact,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _currentWhatsIncludedPage
                                  ? appTheme.onBackground
                                  : appTheme.background,
                              border: Border.all(color: appTheme.onBackgroundSub),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: textScale > 1.3 ? 20 * yFact : 20 * yFact),
                  ],
                ),
              ),
              if (!_isCheckingTrialEligibility)
                MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(
                      MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.2),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: 40 * yFact, left: 20 * xFact, right: 20 * xFact, bottom: 30 * yFact),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildPlanContainer(
                          context: context,
                          lang: lang,
                          isYearly: true,
                          isSelected: _isYearlySelected,
                          priceLabel: _annualProduct != null
                              ? '${_annualProduct!.priceString}/year'
                              : '.../year',
                          badgePercent: _annualProduct != null && _monthlyProduct != null
                              ? '${((_monthlyProduct!.price * 12 - _annualProduct!.price) / (_monthlyProduct!.price * 12) * 100).round()}% OFF'
                              : null,
                          badgeFree: _trialDays == 7 ? '1 WEEK FREE' : '$_trialDays DAYS FREE',
                        ),
                        SizedBox(height: 12 * yFact),
                        _buildPlanContainer(
                          context: context,
                          lang: lang,
                          isYearly: false,
                          isSelected: !_isYearlySelected,
                          priceLabel: _monthlyProduct != null
                              ? '${_monthlyProduct!.priceString}/month'
                              : '.../month',
                        ),
                        SizedBox(height: 10 * yFact),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: translate("continue", lang),
                            onTap: _isLoadingPackage ||
                                    (_isYearlySelected ? _annualProduct == null : _monthlyProduct == null)
                                ? null
                                : _purchaseSubscription,
                          ),
                        ),
                        SizedBox(height: 15 * yFact),
                        SizedBox(
                          height: textScale > 1.3 ? 60 * yFact : 50 * yFact,
                          child: RichText(
                            textScaler: MediaQuery.textScalerOf(context).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.25),
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: "InterTight",
                                fontSize: 16 * xFact,
                                color: appTheme.onBackground,
                                height: 1.4,
                              ),
                              children: _buildPriceTextSpans(_getFormattedPriceText(lang,_isYearlySelected), xFact),
                            ),
                          ),
                        ),
                        SizedBox(height: 15 * yFact),
                        MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(
                              MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.25),
                            ),
                            boldText: false,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(horizontal: 0 * xFact),
                                  child: GestureDetector(
                                    onTap: _openPrivacyPage,
                                    child: Text(
                                      'Privacy policy',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: "InterTight",
                                        fontSize: 15 * xFact,
                                        color: appTheme.onTextField,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 0 * xFact),
                              Flexible(
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(horizontal: 0 * xFact),
                                  child: GestureDetector(
                                    onTap: () async {
                                      await OnboardingRestoreFlow.runFullFlow(
                                        context: context,
                                        ref: ref,
                                        lang: lang,
                                        goHome: ({required bool skipRevenueCatCheck}) async {
                                          await _goHomeFromRestoreFlow(
                                              skipRevenueCatCheck: skipRevenueCatCheck);
                                        },
                                      );
                                    },
                                    child: Text(
                                      "Restore purchase",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: "InterTight",
                                        fontSize: 15 * xFact,
                                        color: appTheme.onTextField,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 0 * xFact),
                              Flexible(
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(horizontal: 0 * xFact),
                                  child: GestureDetector(
                                    onTap: _openTermsPage,
                                    child: Text(
                                      'Terms of use',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: "InterTight",
                                        fontSize: 15 * xFact,
                                        color: appTheme.onTextField,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

