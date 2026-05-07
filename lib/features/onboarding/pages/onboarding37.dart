import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/features/paywall/model/paywall_models.dart';
import 'package:businessmindset/features/paywall/view_model/paywallb_provider.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/services/revenuecat_service.dart';
import 'package:businessmindset/config/revenuecat_keys.dart';
import 'package:businessmindset/services/trial_duration_ab_service.dart';

class OnBoarding37 extends ConsumerStatefulWidget {
  const OnBoarding37({
    super.key,
    this.forward,
  });
  final Function(int)? forward;

  @override
  ConsumerState<OnBoarding37> createState() => _OnBoarding37State();
}

class _OnBoarding37State extends ConsumerState<OnBoarding37> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  
  StoreProduct? _annualProduct14;
  bool _isLoadingPackage = false;
  /// A/B branch (3 or 7 days) — struck through next to the 14-day offer.
  int _abBaselineTrialDays = 7;

  // NOTE: This page is a PROMOTIONAL OFFER (14 days instead of 7)
  // It does NOT need an eligibility check because it's a special offer
  // offered to all users who land on this page.
  // Apple/Google will handle the actual eligibility at payment time.
  
  @override
  void initState() {
    super.initState();
    _initializeRevenueCat();
    _loadAbTrialDays();
  }

  Future<void> _loadAbTrialDays() async {
    final prefs = await SharedPreferences.getInstance();
    final d = await TrialDurationAbService.getAssignedTrialDays(prefs);
    if (mounted) setState(() => _abBaselineTrialDays = d);
  }
  
  Future<void> _initializeRevenueCat() async {
    if (kIsWeb) return;
    
    setState(() {
      _isLoadingPackage = true;
    });
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await RevenueCatService.instance.ensureConfigured(appUserId: userId);
      
      // Retrieve the Product ID for premium_annual_14
      final productId = getSubscriptionProductId14();
      
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint('Fetching product with ID: $productId');
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
      
      // Retrieve products directly without Offerings
      final products = await RevenueCatService.instance.getProducts([productId]);
      
      if (!mounted) return;
      
      if (products.isEmpty) {
        setState(() {
          _isLoadingPackage = false;
        });
        if (kDebugMode) {
          debugPrint('No product available');
        }
        return;
      }
      
      final product = products.first;
      setState(() {
        _annualProduct14 = product;
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
  
  Future<void> _purchaseSubscription() async {
    if (_annualProduct14 == null) {
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
      
      final info = await RevenueCatService.instance.purchaseProduct(_annualProduct14!);
      
      if (RevenueCatService.instance.hasActiveEntitlement(info)) {
        // Purchase successful
        if (kDebugMode) {
          debugPrint('Purchase successful!');
        }
        setState(() {
          _isLoadingPackage = false;
        });
        final paywallVm = ref.read(
          paywallbViewModelProvider(
            const PaywallbInput(
              pageStyle: 'onboarding37',
              title: '',
              subTitle: '',
              choiceList: <String>[],
              backIcon: true,
              skipLink: false,
            ),
          ).notifier,
        );
        await paywallVm.markPremiumUnlocked(info);
        // Navigation after successful purchase - call forward(2)
        if (widget.forward != null) {
          widget.forward!(1);
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
      
      // Do not show an error if the user cancelled
      final errorCode = PurchasesErrorHelper.getErrorCode(error);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        if (kDebugMode) {
          debugPrint('Purchase cancelled by user');
        }
        // No need to show an error for a cancellation
      } else {
        if (kDebugMode) {
          debugPrint('Purchase failed: $error');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                translate("purchase_failed_try_again", ref.watch(languageProvider)),
                style: TextStyle(fontFamily: "InterTight"),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Purchase failed: $error');
      }
      setState(() {
        _isLoadingPackage = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              translate("purchase_failed_try_again", ref.watch(languageProvider)),
              style: TextStyle(fontFamily: "InterTight"),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  String _getFormattedPriceText(String lang) {
    if (_annualProduct14 == null) {
      return translate("free_trial_text_14", lang)
          .replaceAll("%PRICE_YEAR%", "...")
          .replaceAll("%PRICE_MONTH%", "...");
    }
    
    final yearPrice = _annualProduct14!.priceString;
    final yearPriceValue = _annualProduct14!.price;
    final monthPriceValue = (yearPriceValue / 12);
    
    // Extract the currency symbol
    final currencySymbol = yearPrice.replaceAll(RegExp(r'[\d\s,.]'), '').trim();
    
    // Format the monthly price
    final monthPrice = currencySymbol.isEmpty
        ? monthPriceValue.toStringAsFixed(2)
        : '$currencySymbol${monthPriceValue.toStringAsFixed(2)}';
    
    return translate("free_trial_text_14", lang)
        .replaceAll("%PRICE_YEAR%", yearPrice)
        .replaceAll("%PRICE_MONTH%", monthPrice);
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
      
      // Add the price part in w600
      spans.add(TextSpan(
        text: match.group(0)!,
        style: TextStyle(
          fontSize: 12 * xFact,
          fontWeight: FontWeight.w600
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
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final userName = ref.watch(userNameStateProvider);

    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    // Show the page only when loading is complete
    if (_isLoadingPackage) {
      return Container(
        height: double.maxFinite,
        width: double.maxFinite,
        color: appTheme.background,
      );
    }
    
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
                  if (widget.forward != null) {
                    widget.forward!(3);
                  }
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
                    color: appTheme.onBackground.withValues(alpha: 0.4),
                    size: 24 * xFact,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 40 * yFact, left: 20 * xFact, right: 20 * xFact,bottom: 25 * yFact),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Titre "Need a boost, %NAME%?"
                  SizedBox(),
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30*xFact),
                        child: MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: const TextScaler.linear(1.0),
                          ),
                          child: Text(
                            translate("need_a_boost", lang).replaceAll("%NAME%", userName),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: "YesevaOne",
                              fontSize: 30 * xFact,
                              color: appTheme.onBackground,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 0 * yFact),
                      // Image Flamy gift
                      Center(
                        child: SizedBox(
                          width: textScale > 1.3 ? 300 * xFact : 330 * xFact,
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
                      ),
                      SizedBox(height: textScale > 1.1 ? 0 * yFact : 20*yFact),
                      // Texte "Keep your personalized plan..."
                      Text(
                        translate("keep_plan_grow_mindset", lang),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "InterTight",
                          fontSize: 20 * xFact,
                          fontWeight: FontWeight.w600,
                          color: appTheme.onBackground,
                        ),
                      ),
                      SizedBox(height: textScale > 1.1 ? 0 * yFact : 20*yFact),
                      // "Get a X-day 14-day free trial!" text (X = A/B branch 3 or 7)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: "YesevaOne",
                              fontSize: 24 * xFact,
                              color: appTheme.onBackground,
                            ),
                            children: [
                              TextSpan(text: translate("get_a", lang)),
                              TextSpan(
                                text: '$_abBaselineTrialDays-day ',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: appTheme.onBackground.withValues(alpha: 0.5),
                                ),
                              ),
                              TextSpan(
                                text: "14-day ",
                                style: TextStyle(
                                  color: appTheme.onPrimButtonGold,
                                ),
                              ),
                              TextSpan(text: translate("free_trial_exclamation", lang)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 15*yFact,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          text: translate("start_14_day_trial", lang),
                          icon: textScale < 1.2 ? Icons.arrow_right_alt : null,
                          iconSize: 40 * xFact,
                          onTap: _isLoadingPackage ? null : _purchaseSubscription,
                        ),
                      ),
                      SizedBox(height: 10 * yFact),
                      // Text under the button with links
                      RichText(
                        textScaler: MediaQuery.textScalerOf(context),
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: "InterTight",
                            fontSize: 12 * xFact,
                            color: appTheme.onBackground,
                            height: 1.4,
                          ),
                          children: [
                            ..._buildPriceTextSpans(_getFormattedPriceText(lang), xFact),
                          ],
                        ),
                      ),
                      SizedBox(height: 15 * yFact),
                      RichText(
                        textScaler: MediaQuery.textScalerOf(context),
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: "InterTight",
                            fontSize: 12 * xFact,
                            color: appTheme.onBackground,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: 'Privacy policy',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = _openPrivacyPage,
                            ),
                            TextSpan(text: '          '),
                            TextSpan(
                              text: 'Terms of use',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = _openTermsPage,
                            ),
                          ],
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
}

