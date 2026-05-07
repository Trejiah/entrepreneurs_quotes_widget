import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/features/paywall/model/paywall_models.dart';
import 'package:businessmindset/features/paywall/view_model/paywallb_provider.dart';
import 'package:businessmindset/features/paywall/view_model/paywallb_ui_state.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding_restore_flow.dart';
import 'package:businessmindset/providers/habits_provider.dart' show userNameStateProvider;
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/services/hard_paywall_service.dart';
import 'package:businessmindset/services/notification_service.dart';
import 'package:businessmindset/services/tiktok_service.dart';
import 'package:businessmindset/widgets/app_button.dart';

class Paywallb extends ConsumerStatefulWidget {
  const Paywallb({
    super.key,
    required this.paywallInput,
    required this.pageStyle,
    required this.backIcon,
    required this.skipLink,
    required this.title,
    required this.subTitle,
    required this.choiceList,
    this.backward,
    this.buttonText,
    this.forward1,
    this.forward2,
    this.variable,
    this.hardPaywallMode = false,
    this.onHardPaywallUnlocked,
  });

  /// Clés stable pour le provider MVVM (produits, trial, achats).
  final PaywallbInput paywallInput;
  final String pageStyle;
  final bool backIcon;
  final bool skipLink;
  final String title;
  final String subTitle;
  final String? variable;
  final String? buttonText;
  final VoidCallback? backward;
  final VoidCallback? forward1;
  final VoidCallback? forward2;
  final List<String> choiceList;
  /// Full-screen paywall with no close or back button; unlock via [onHardPaywallUnlocked].
  final bool hardPaywallMode;
  final VoidCallback? onHardPaywallUnlocked;

  @override
  ConsumerState<Paywallb> createState() => _PaywallState();
}

class _PaywallState extends ConsumerState<Paywallb> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  final PageController _pageController = PageController(); // Pour naviguer entre les 3 pages principales
  final PageController _whatsIncludedController = PageController(); // Pour le PageView "What's included"

  // Page 0 (onboarding33) state
  final Map<String, double> _percentages = {};
  List<String> _tones = [];

  // Page 2 (onboarding38) state
  bool _reminderEnabled = false;
  bool _isLoading = false;

  final List<String> _categoryKeys = ['growth', 'discipline', 'confidence', 'strategy'];
  final Map<String, String> _categoryNameKeys = {
    'growth': 'plan_category_growth',
    'discipline': 'plan_category_discipline',
    'confidence': 'plan_category_confidence',
    'strategy': 'plan_category_strategy',
  };

  // Function to get the first word of a translation
  String _getFirstWord(String translationKey, String lang) {
    final fullText = translate(translationKey, lang);
    return fullText.split(' ')[0];
  }

  // The 3 "What's included" screens - translation keys
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
    TikTokService.instance.trackOpenPaywall();
    _loadData();
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

    // Load tones
    final savedTones = prefs.getStringList("tones") ?? [];
    _tones = savedTones.map((tone) => tone.toLowerCase()).toList();

    if (kDebugMode) {
      debugPrint("📊 [Paywall] Data loaded:");
      debugPrint("  Pourcentages: $_percentages");
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _purchaseSubscription() async {
    final vm = ref.read(paywallbViewModelProvider(widget.paywallInput).notifier);
    final lang = ref.read(languageProvider);
    final outcome = await vm.purchasePrimaryPlans();

    if (!mounted) return;

    switch (outcome) {
      case PaywallbPurchaseOutcome.noProductAvailable:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              translate("no_subscription_available", lang),
              style: TextStyle(fontFamily: "InterTight"),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        break;
      case PaywallbPurchaseOutcome.success:
        final cb = widget.onHardPaywallUnlocked;
        if (widget.hardPaywallMode && cb != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) cb();
          });
          return;
        }
        await _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;
      case PaywallbPurchaseOutcome.cancelled:
      case PaywallbPurchaseOutcome.completedWithoutActiveEntitlement:
      case PaywallbPurchaseOutcome.failed:
        break;
    }
  }

  String _getFormattedPriceText(String lang, PaywallbUiState rc, bool isYearlySelected) {
    if (isYearlySelected) {
      if (rc.annualProduct == null) {
        return translate("free_trial_text", lang)
            .replaceAll("%TRIAL_DAYS%", '${rc.trialDays}')
            .replaceAll("%PRICE_YEAR%", "...")
            .replaceAll("%PRICE_MONTH%", "...");
      }

      final yearPrice = rc.annualProduct!.priceString;
      final yearPriceValue = rc.annualProduct!.price;
      final monthPriceValue = (yearPriceValue / 12);

      // Extract the currency symbol
      final currencySymbol = yearPrice.replaceAll(RegExp(r'[\d\s,.]'), '').trim();

      // Format the monthly price
      final monthPrice = currencySymbol.isEmpty
          ? monthPriceValue.toStringAsFixed(2)
          : '$currencySymbol${monthPriceValue.toStringAsFixed(2)}';

      if (rc.isEligibleForTrial) {
        return translate("free_trial_text", lang)
            .replaceAll("%TRIAL_DAYS%", '${rc.trialDays}')
            .replaceAll("%PRICE_YEAR%", yearPrice)
            .replaceAll("%PRICE_MONTH%", monthPrice);
      } else {
        return translate("free_trial_text2", lang)
            .replaceAll("%PRICE_YEAR%", yearPrice)
            .replaceAll("%PRICE_MONTH%", monthPrice);
      }
    } else {
      if (rc.monthlyProduct == null) {
        return translate("free_trial_text", lang)
            .replaceAll("%TRIAL_DAYS%", '${rc.trialDays}')
            .replaceAll("%PRICE_YEAR%", "...")
            .replaceAll("%PRICE_MONTH%", "...");
      }

      final monthPrice = rc.monthlyProduct!.priceString;
      return translate("free_trial_text3", lang)
          .replaceAll("%PRICE_MONTH%", monthPrice);
    }
  }

  /// Build a list of TextSpan with different sizes
  /// The ($price/year) part is shown in 15pt instead of 13pt
  List<TextSpan> _buildPriceTextSpans(String text, double xFact) {
    ///TODO $9.99/month. Cancel anytime.
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

  /// A container for the Yearly or Monthly plan with checkbox and optional badges.
  Widget _buildPlanContainer({
    required BuildContext context,
    required String lang,
    required bool isYearly,
    required bool isSelected,
    required String priceLabel,
    required bool isEligibleForTrial,
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
          // Checkbox circulaire
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
          // Titre + prix
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
          if (badgeFree != null && isEligibleForTrial)
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

    if (badgePercent != null && isEligibleForTrial) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            top: -badgeHeight / 2,
            right: 30 * xFact,
            child: Container(
              height: 25*yFact,
              width: 95*xFact,
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
        ref
            .read(paywallbViewModelProvider(widget.paywallInput).notifier)
            .setYearlySelected(isYearly);
      },
      child: content,
    );
  }

  /// Save the trial-end reminder
  ///
  /// This function uses the REAL data of the ongoing trial (via [PaywallbUiState.trialDays])
  /// to compute the end date and schedule a notification 2 days before.
  /// No need for the !hasActive && !hasHistory eligibility logic because we
  /// works with an already active trial.
  Future<void> _saveTrialReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = ref.read(languageProvider);
    final trialDays =
        ref.read(paywallbViewModelProvider(widget.paywallInput)).trialDays;

    // Store the bool
    await prefs.setBool('trial_reminder', _reminderEnabled);

    if (_reminderEnabled) {
      // Compute the reminder date (2 days before trial end)
      final now = DateTime.now();
      final trialEndDate = now.add(Duration(days: trialDays));
      final reminderDate = trialEndDate.subtract(const Duration(days: 2));

      // Force the time to noon (12:00) regardless of the activation hour
      final reminderDateAtNoon = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        12, // heure
        0,  // minute
        0,  // seconde
        0,  // milliseconde
      );

      // Store the reminder date (timestamp in milliseconds)
      await prefs.setInt('trial_reminder_date', reminderDateAtNoon.millisecondsSinceEpoch);

      // Schedule the notification
      await NotificationService.instance.scheduleTrialReminderNotification(
        reminderDate: reminderDateAtNoon,
        languageCode: lang,
      );

      if (kDebugMode) {
        debugPrint('Trial reminder saved: ${reminderDateAtNoon.toString()}');
        debugPrint('Trial reminder notification scheduled');
      }
    } else {
      // Remove the date if the reminder is disabled
      await prefs.remove('trial_reminder_date');

      // Cancel the notification
      await NotificationService.instance.cancelTrialReminderNotification();

      if (kDebugMode) {
        debugPrint('Trial reminder disabled and notification cancelled');
      }
    }
  }

  Future<void> _handleGetStarted() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    await _saveTrialReminder();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (_reminderEnabled) {
      // Show the popup
      _showReminderDialog();
    } else {
      // Pop vers settings
      Navigator.of(context).pop();
    }
  }

  void _showReminderDialog() {
    final lang = ref.read(languageProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20 * xFact),
            decoration: BoxDecoration(
              color: Color(0xFF575757),
              borderRadius: BorderRadius.circular(20 * xFact),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Flamy image with glasses
                Padding(
                  padding: EdgeInsets.only(left: 20.0*xFact),
                  child: SizedBox(
                    width: 100 * xFact,
                    child: Image.asset(
                      'assets/images/flamy/flamy_glasses_ok.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image,
                          size: 80 * xFact,
                          color: appTheme.onBackground,
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20 * yFact),
                // Texte
                Text(
                  translate("reminder_confirmation_text", lang),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "InterTight",
                    fontSize: 18 * xFact,
                    color: appTheme.onBackground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 30 * yFact),
                // Bouton "Got it"
                SizedBox(
                  width: double.infinity,
                  child: SecondaryButton(
                    text: translate("got_it", lang),
                    onTap: () {
                      Navigator.of(context).pop();
                      // Pop vers settings
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveRefusalDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("subscriptionRefusedDate", DateTime.now().millisecondsSinceEpoch);
    if (kDebugMode) {
      debugPrint('Subscription refused date saved');
    }
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

  // Page 0: onboarding33 (no popup)
  Widget _buildPage0() {
    final rc = ref.watch(paywallbViewModelProvider(widget.paywallInput));
    final lang = ref.watch(languageProvider);
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    final blodText = MediaQuery.of(context).boldText;

    // Show the page only when loading is complete
    if (rc.isLoadingPackage) {
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
              if (!widget.hardPaywallMode)
                Positioned(
                  top: 15*yFact,
                  left: 20* xFact,
                  child: GestureDetector(
                    onTap: () async {
                      // Outside onboarding, close the paywall directly without "Are you sure?" popup
                      //await _saveRefusalDate();
                      if (mounted) {
                        Navigator.of(context).pop();
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
                        color: appTheme.onBackground,
                        size: 22 * xFact,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(top: 25 * yFact,left: 20*xFact,right: 20*xFact),
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
                    SizedBox(height:  5 * yFact),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25.0),
                      child: SizedBox(
                        height: textScale > 1.1 ? 85*yFact : blodText ? 80*yFact : 60*yFact,
                        child: Builder(
                          builder: (context) {
                            final String textKey = (_getWhatsIncludedScreens(lang)[rc.currentWhatsIncludedPage][0])["textKey"] ?? "";
                            return Text(
                              translate(textKey, lang),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: "InterTight",
                                fontSize: 18 * xFact,
                                color: appTheme.onBackground,
                              ),
                            );
                          }
                        ),
                      ),
                    ),
                    SizedBox(height: 5 * yFact),
                    // PageView for swiping
                    Container(
                      height:  textScale > 1.2 ? 200*yFact : textScale > 1.1 ? 230*yFact : blodText ? 245 * yFact : 280 * yFact,
                      child: PageView.builder(
                        controller: _whatsIncludedController,
                        onPageChanged: (index) {
                          ref
                              .read(paywallbViewModelProvider(widget.paywallInput).notifier)
                              .onWhatsIncludedPageChanged(index);
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
                                          stops: [
                                            0.2,
                                            0.95
                                          ]
                                        )
                                      ),
                                    )
                                  ],
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(height: textScale > 1.3 ? 0*yFact : 10 * yFact),
                    // Navigation dots
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
                                color: i == rc.currentWhatsIncludedPage
                                    ? appTheme.onBackground
                                    : appTheme.background,
                                border: Border.all(color: appTheme.onBackgroundSub)
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: textScale > 1.3 ? 20*yFact : 20 * yFact,),

                  ],
                ),
              ),
              // Show the bottom column only when verification is complete
              if (!rc.isCheckingTrialEligibility)
                MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(
                      MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.2),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(top: 40 * yFact,left: 20*xFact,right: 20*xFact,bottom: 30*yFact),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Containers Yearly / Monthly
                        _buildPlanContainer(
                          context: context,
                          lang: lang,
                          isYearly: true,
                          isSelected: rc.isYearlySelected,
                          isEligibleForTrial: rc.isEligibleForTrial,
                          priceLabel: rc.annualProduct != null
                              ? '${rc.annualProduct!.priceString}/year'
                              : '.../year',
                          badgePercent: rc.annualProduct != null && rc.monthlyProduct != null
                              ? '${((rc.monthlyProduct!.price * 12 - rc.annualProduct!.price) / (rc.monthlyProduct!.price * 12) * 100).round()}% OFF'
                              : null,
                          badgeFree: rc.trialDays == 7 ? '1 WEEK FREE' : '${rc.trialDays} DAYS FREE',
                        ),
                        SizedBox(height: 12 * yFact),
                        _buildPlanContainer(
                          context: context,
                          lang: lang,
                          isYearly: false,
                          isSelected: !rc.isYearlySelected,
                          isEligibleForTrial: rc.isEligibleForTrial,
                          priceLabel: rc.monthlyProduct != null
                              ? '${rc.monthlyProduct!.priceString}/month'
                              : '.../month',
                        ),
                        SizedBox(
                          height: 10*yFact,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                          text: translate("continue", lang),
                          onTap: rc.isLoadingPackage || (rc.isYearlySelected ? rc.annualProduct == null : rc.monthlyProduct == null)
                              ? null
                              : _purchaseSubscription,
                        ),
                      ),
                      SizedBox(height: 15 * yFact),
                      SizedBox(
                        height: textScale > 1.3 ? 60*yFact : 50*yFact,
                        child: RichText(
                          textScaler: MediaQuery.textScalerOf(context).clamp(minScaleFactor : 1.0, maxScaleFactor: 1.25),
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: "InterTight",
                              fontSize: 16 * xFact,
                              color: appTheme.onBackground,
                              height: 1.4,
                            ),
                            children: _buildPriceTextSpans(_getFormattedPriceText(lang, rc, rc.isYearlySelected), xFact),
                          ),
                        ),
                      ),
                      SizedBox(height: 15 * yFact),
                      MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: TextScaler.linear(
                            MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.25),
                          ),
                          boldText: false
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
                                    if (widget.hardPaywallMode) {
                                      await OnboardingRestoreFlow.runFullFlow(
                                        context: context,
                                        ref: ref,
                                        lang: lang,
                                        goHome: ({required bool skipRevenueCatCheck}) async {
                                          if (!mounted) return;
                                          await HardPaywallService.clearBlockingLayer();
                                          HardPaywallService.resetPresentScheduleFlag();
                                          widget.onHardPaywallUnlocked?.call();
                                        },
                                      );
                                      return;
                                    }
                                    await OnboardingRestoreFlow.runFullFlow(
                                      context: context,
                                      ref: ref,
                                      lang: lang,
                                      goHome: ({required bool skipRevenueCatCheck}) async {
                                        if (!mounted) return;
                                        final nav = Navigator.of(context, rootNavigator: true);
                                        int pops = 0;
                                        while (pops < 2 && nav.canPop()) {
                                          nav.pop();
                                          pops++;
                                        }
                                      },
                                    );
                                  },
                                  child: Text(
                                    "Restore purchase",
                                 //   textScaler: MediaQuery.textScalerOf(context),
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

  // Page 2 : onboarding38
  Widget _buildPage2() {
    final rc = ref.watch(paywallbViewModelProvider(widget.paywallInput));
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
                          top: 21*yFact,
                          right: 18* xFact,
                          child: SizedBox(
                              height: 56*xFact,
                              width: 86*yFact,
                              child: Text(
                                "You're on fire!",
                                style: TextStyle(
                                    fontFamily: "InterTight",
                                    fontSize: 18*xFact,
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
                  SizedBox(height: 15 * yFact),
                  // "Welcome aboard, %NAME%!" text - Dedicated area for up to 2 lines
                  Text(
                    translate("welcome_aboard", lang).replaceAll("%NAME%", userName),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: "YesevaOne",
                      fontSize: 30 * xFact,
                      color: appTheme.onBackground,
                    ),
                  ),
                  SizedBox(height: 25 * yFact),
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
                        Text(
                          translate("you_now_access", lang),
                          style: TextStyle(
                            fontFamily: "InterTight",
                            fontSize: 18 * xFact,
                            color: appTheme.onBackground,
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
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
                  // Switch "Remind me before my trial ends"

                ],
              ),
            ),
            // Button at the bottom in a separate column
            Padding(
              padding: EdgeInsets.only(
                top: 40 * yFact,
                left: 20 * xFact,
                right: 20 * xFact,
                bottom: 45 * yFact,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (rc.isInTrial) Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        translate("remind_me_before_trial_ends", lang),
                        style: TextStyle(
                          fontFamily: "InterTight",
                          fontSize: 16 * xFact,
                          color: appTheme.onBackground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(
                        width: 10*xFact,
                      ),
                      SwitchTheme(
                        data: SwitchThemeData(
                          trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return appTheme.onPrimButtonGold;
                            }
                            return appTheme.textField;
                          }),
                          overlayColor: WidgetStateProperty.all(Colors.transparent),
                          splashRadius: 0,
                        ),
                        child: Switch(
                          value: _reminderEnabled,
                          onChanged: rc.isInTrial ? (value) {
                            setState(() {
                              _reminderEnabled = value;
                            });
                          } : null, // Désactiver le switch si l'utilisateur n'est pas en trial
                          inactiveThumbColor: appTheme.onBackground,
                          inactiveTrackColor: appTheme.textField,
                          activeTrackColor: appTheme.onPrimButtonGold,
                          activeThumbColor: appTheme.onBackground,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20 * yFact),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: translate("lets_go", lang),
                      icon: Icons.arrow_right_alt,
                      iconSize: 40 * xFact,
                      onTap: _isLoading ? null : _handleGetStarted,
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
    final textScaler = MediaQuery.textScalerOf(context);
    final cappedScale = textScaler.scale(1.0).clamp(1.0, 1.20);
    Widget content = Material(
      child: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(), // Désactiver le swipe manuel
        children: [
          _buildPage0(), // onboarding33
          _buildPage2(), // onboarding38
        ],
      ),
    );
    if (widget.hardPaywallMode) {
      content = PopScope(
        canPop: false,
        child: content,
      );
    }
    return content;
  }
}
