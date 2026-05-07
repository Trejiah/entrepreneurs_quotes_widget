import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/config/revenuecat_keys.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/services/revenuecat_service.dart';
import 'package:businessmindset/services/tiktok_service.dart';
import 'package:businessmindset/widgets/app_button.dart';

class PaywallPromo extends ConsumerStatefulWidget {
  const PaywallPromo({super.key});

  @override
  ConsumerState<PaywallPromo> createState() => _PaywallPromoState();
}

class _PaywallPromoState extends ConsumerState<PaywallPromo> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  StoreProduct? _promoProduct;
  bool _isLoadingPackage = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => MixpanelService.instance.track('[Paywall] Promo affiché'),
    );
    _initializeRevenueCat();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }
  
  Future<void> _initializeRevenueCat() async {
    if (kIsWeb) return;
    
    setState(() {
      _isLoadingPackage = true;
    });
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await RevenueCatService.instance.ensureConfigured(appUserId: userId);
      
      // Retrieve the promo Product ID
      final productId = getSubscriptionProductIdPromo();
      
      if (kDebugMode) {
        debugPrint('Fetching promo product with ID: $productId');
      }
      
      // Retrieve products directly without Offerings
      final products = await RevenueCatService.instance.getProducts([productId]);
      
      if (!mounted) return;
      
      if (products.isEmpty) {
        setState(() {
          _isLoadingPackage = false;
        });
        if (kDebugMode) {
          debugPrint('No promo product available');
        }
        return;
      }
      
      final product = products.first;
      setState(() {
        _promoProduct = product;
        _isLoadingPackage = false;
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to initialize RevenueCat promo: $error');
      }
      setState(() {
        _isLoadingPackage = false;
      });
    }
  }
  
  Future<void> _purchaseSubscription() async {
    if (_promoProduct == null) {
      if (kDebugMode) {
        debugPrint('No promo product available for purchase');
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
      
      final info = await RevenueCatService.instance.purchaseProduct(_promoProduct!);
      
      if (RevenueCatService.instance.hasActiveEntitlement(info)) {
        // Purchase successful
        if (kDebugMode) {
          debugPrint('Promo purchase successful!');
        }
        setState(() {
          _isLoadingPackage = false;
        });
        // Save the premium status
        await _markPremiumUnlocked(info);
        // Go to page 2 (welcome)
        if (mounted) {
          _pageController.animateToPage(
            2,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } else {
        if (kDebugMode) {
          debugPrint('Promo purchase completed but no active entitlement found');
        }
        setState(() {
          _isLoadingPackage = false;
        });
      }
    } on PlatformException catch (error) {
      setState(() {
        _isLoadingPackage = false;
      });
      
      final errorCode = PurchasesErrorHelper.getErrorCode(error);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        if (kDebugMode) {
          debugPrint('Promo purchase cancelled by user');
        }
      } else {
        if (kDebugMode) {
          debugPrint('Promo purchase failed: $error');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Promo purchase failed: $error');
      }
      setState(() {
        _isLoadingPackage = false;
      });
    }
  }
  
  Future<void> _markPremiumUnlocked(CustomerInfo? info) async {
    // Update the provider
    ref.read(premiumProvider.notifier).state = true;
    
    // Sauvegarder localement
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("premiumState", true);
    
    // Save the expiration date locally and log the subscription info
    if (info != null) {
      final expirationDate = RevenueCatService.instance.getExpirationDate(info);
      final trialEndDate = RevenueCatService.instance.getTrialEndDate(info);
      final renewalDate = RevenueCatService.instance.getRenewalDate(info);
      
      if (expirationDate != null) {
        await prefs.setInt("premiumExpirationDate", expirationDate.millisecondsSinceEpoch);
      }
      
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("✅ [PaywallPromo] Premium activé - Détails de l'abonnement");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        
        if (trialEndDate != null) {
          debugPrint("🎁 End of TRIAL period (UTC+4): ${RevenueCatService.instance.formatDateTimeLocal(trialEndDate)}");
        }
        
        if (renewalDate != null) {
          debugPrint("🔄 Prochain RENEWAL (UTC+4): ${RevenueCatService.instance.formatDateTimeLocal(renewalDate)}");
        } else {
          final entitlement = info.entitlements.active[revenueCatEntitlementId];
          if (entitlement != null && !entitlement.willRenew) {
            debugPrint("⚠️ No renewal scheduled (opt-out)");
          }
        }
        
        if (expirationDate != null) {
          debugPrint("📅 Date d'expiration (UTC+4): ${RevenueCatService.instance.formatDateTimeLocal(expirationDate)}");
        }
        
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
    }
    
    // Track Mixpanel event with subscription and profile info (promo = annual, no trial)
    final age = prefs.getString("age") ?? "unknown";
    final gender = prefs.getString("gender") ?? "unknown";
    final workSituation = prefs.getString("situation") ?? "unknown";
    MixpanelService.instance.track('[Subscription] Premium Enabled', {
      'trial_type': 'promo',
      'subscription_origin': 'no_trial',
      'subscription_period': 'year',
      'gender': gender,
      'age': age,
      'work_situation': workSituation,
      'source': 'paywall_promo',
    });
    // TikTok: CompletePayment — direct purchase without trial (promo)
    final entitlement = info?.entitlements.active[revenueCatEntitlementId];
    if (entitlement != null) {
      TikTokService.instance.trackCompletePayment(
        contentId: entitlement.productIdentifier,
        contentName: 'premium_annual_promo',
        quantity: 1,
      );
    }
    
    if (kDebugMode) {
      debugPrint('✅ Premium unlocked and saved');
    }
  }
  
  String _getFormattedPriceText(String lang) {
    if (_promoProduct == null) {
      return translate("only_month_billed", lang).replaceAll("%PRICE%", "2.49");
    }
    
    final yearPrice = _promoProduct!.priceString;
    final yearPriceValue = _promoProduct!.price;
    final monthPriceValue = (yearPriceValue / 12);
    
    // Extract the currency symbol
    final currencySymbol = yearPrice.replaceAll(RegExp(r'[\d\s,.]'), '').trim();
    
    // Format the monthly price
    final monthPrice = currencySymbol.isEmpty
        ? monthPriceValue.toStringAsFixed(2)
        : '$currencySymbol${monthPriceValue.toStringAsFixed(2)}';
    
    return translate("only_month_billed", lang).replaceAll("%PRICE%", monthPrice);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Page 0 : Exclusive offer
  Widget _buildPage0() {
    final lang = ref.watch(languageProvider);
    final userName = ref.watch(userNameStateProvider);
    
    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      color: appTheme.background,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              top: 15 * yFact,
              left: 20 * xFact,
              child: GestureDetector(
                onTap: () {
                  // Close fait pop vers HomePage
                  Navigator.of(context).pop();
                },
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
                    size: 24 * xFact,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20 * yFact, left: 20 * xFact, right: 20 * xFact, bottom: 25 * yFact),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      // Titre "Exclusive offer for %NAME%"
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40 * xFact),
                        child: Text(
                          translate("exclusive_offer_for", lang).replaceAll("%NAME%", userName),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "YesevaOne",
                            fontSize: 20 * xFact,
                            color: appTheme.onBackground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 50 * yFact),
                      // Flamy image with glasses and gift
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            width: 330 * xFact,
                            child: Image.asset(
                              'assets/images/flamy/flamy_gift.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.image,
                                    size: 200 * xFact,
                                    color: appTheme.onBackground);
                              },
                            ),
                          ),
                          // "33% OFF!" text positioned top-right with rotation and blur
                          Positioned(
                            top: 0 * yFact,
                            right: 30* xFact,
                            child: Transform.rotate(
                              angle: -0.30, // Rotation à gauche (environ -8.6 degrés)
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8 * xFact, vertical: 4 * yFact),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Ligne 1: "33%"
                                    Text(
                                      "33%",
                                      style: TextStyle(
                                        height: 1,
                                        fontFamily: "BebasNeue",
                                        fontSize: 60 * xFact,
                                        color: appTheme.onBackground,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: appTheme.onPrimButtonGold,
                                            blurRadius: 50,
                                            offset: Offset(2, 2),
                                          ),
                                        ],
                                      ),

                                    ),
                                    // Ligne 2: "OFF!"
                                    Text(
                                      "OFF!  ",
                                      style: TextStyle(
                                        height: 1,
                                        fontFamily: "BebasNeue",
                                        fontSize: 40 * xFact,
                                        color: appTheme.onBackground,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: appTheme.onPrimButtonGold,
                                            blurRadius: 50,
                                            offset: Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30 * yFact),
                      // Texte "Unlock your personalized feed..."
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30 * xFact),
                        child: Text(
                          translate("unlock_personalized_feed", lang),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "InterTight",
                            fontSize: 16 * xFact,
                            color: appTheme.onBackground,
                          ),
                        ),
                      ),
                      SizedBox(height: 30 * yFact),
                      // Prix
                      if (_promoProduct != null)
                        Column(
                          children: [
                            Text(
                              translate("get_premium_for_only", lang),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: "InterTight",
                                fontSize: 27 * xFact,
                                color: appTheme.onBackground,
                              ),
                            ),
                            SizedBox(height: 10 * yFact),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Strikethrough price (original)
                                Text(
                                  "\$44.99",
                                  style: TextStyle(
                                    fontFamily: "InterTight",
                                    fontSize: 27 * xFact,
                                    color: appTheme.onBackground.withOpacity(0.5),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                SizedBox(width: 10 * xFact),
                                // Nouveau prix
                                Text(
                                  "${_promoProduct!.priceString}/${translate("year", lang)} 🎉",
                                  style: TextStyle(
                                    fontFamily: "YesevaOne",
                                    fontSize: 27 * xFact,
                                    color: appTheme.onPrimButtonGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          text: translate("unlock_premium", lang),
                          icon: Icons.arrow_right_alt,
                          iconSize: 40 * xFact,
                          onTap: _isLoadingPackage ? null : () {
                            // Show the confirmation popup
                            _showCancelConfirmationDialog();
                          },
                        ),
                      ),
                      SizedBox(height: 15 * yFact),
                      // Text under the button
                      Text(
                        _getFormattedPriceText(lang),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "InterTight",
                          fontSize: 12 * xFact,
                          color: appTheme.onBackground.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showCancelConfirmationDialog() {
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
          padding: EdgeInsets.only(left: 20 * xFact, right: 20 * xFact, top: 10 * xFact, bottom: 10 * xFact),
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
                translate("are_you_sure", ref.watch(languageProvider)),
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
                translate("special_price_wont_come_back", ref.watch(languageProvider)),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "InterTight",
                  fontSize: 14 * xFact,
                  color: appTheme.onBackground,
                ),
              ),
              SizedBox(height: 35 * yFact),
              // Bouton "Continue Anyway"
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                  text: translate("continue_anyway", ref.watch(languageProvider)),
                  onTap: () {
                    Navigator.pop(context); // Pop le popup
                    // Lancer l'achat
                    _purchaseSubscription();
                  },
                ),
              ),
              SizedBox(height: 10 * yFact),
              // Bouton "Go Back"
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Pop le popup seulement
                },
                child: Text(
                  translate("go_back", ref.watch(languageProvider)),
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
  
  // Page 1: Popup (handled by _showCancelConfirmationDialog)
  
  // Page 2 : Welcome
  Widget _buildPage2() {
    final lang = ref.watch(languageProvider);
    final userName = ref.watch(userNameStateProvider);
    
    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      color: appTheme.background,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Contenu principal
            Padding(
              padding: EdgeInsets.only(top: 5 * yFact, left: 20 * xFact, right: 20 * xFact),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image Flamy superheros
                  Center(
                    child: Stack(
                      children: [
                        SizedBox(
                          width: 270 * xFact,
                          child: Image.asset(
                            'assets/images/flamy/flamy_superheros.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.image,
                                size: 200 * xFact,
                                color: appTheme.onBackground,
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 21 * yFact,
                          right: 18 * xFact,
                          child: SizedBox(
                            height: 56 * xFact,
                            width: 86 * yFact,
                            child: Text(
                              "You're on fire!",
                              style: TextStyle(
                                fontFamily: "InterTight",
                                fontSize: 18 * xFact,
                                fontWeight: FontWeight.w700,
                                color: Colors.black
                              ),
                              textAlign: TextAlign.center,
                            )
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 20 * yFact),
                  // Texte "Welcome aboard, %NAME%!"
                  Text(
                    translate("welcome_aboard", lang).replaceAll("%NAME%", userName),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "YesevaOne",
                      fontSize: 30 * xFact,
                      color: appTheme.onBackground,
                    ),
                  ),
                  SizedBox(height: 30 * yFact),
                  // Feature list
                  Container(
                    padding: EdgeInsets.all(20 * xFact),
                    decoration: BoxDecoration(
                      color: Color(0xFF333333),
                      borderRadius: BorderRadius.circular(15 * xFact),
                      border: Border.all(color: appTheme.onPrimButtonGold)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFeatureItem(
                          translate("personalized_quote_feed", lang),
                          lang,
                        ),
                        SizedBox(height: 15 * yFact),
                        _buildFeatureItem(
                          translate("custom_notifications_widgets", lang),
                          lang,
                        ),
                        SizedBox(height: 15 * yFact),
                        _buildFeatureItem(
                          translate("all_premium_categories", lang),
                          lang,
                        ),
                        SizedBox(height: 15 * yFact),
                        _buildFeatureItem(
                          translate("and_more", lang),
                          lang,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bouton en bas
            Padding(
              padding: EdgeInsets.only(
                top: 40 * yFact,
                left: 20 * xFact,
                right: 20 * xFact,
                bottom: 25 * yFact,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: translate("lets_go", lang),
                      icon: Icons.arrow_right_alt,
                      iconSize: 40 * xFact,
                      onTap: () {
                        // Pop directement vers HomePage
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(String text, String lang) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check,
          color: appTheme.onPrimButtonGold,
          size: 24 * xFact,
        ),
        SizedBox(width: 10 * xFact),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: "InterTight",
              fontSize: 16 * xFact,
              color: appTheme.onBackground,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(), // Désactiver le swipe manuel
        children: [
          _buildPage0(), // Exclusive offer
          _buildPage2(), // Welcome (page 2 car le popup est un dialog)
        ],
      ),
    );
  }
}

