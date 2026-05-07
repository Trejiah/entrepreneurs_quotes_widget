import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/services/revenuecat_service.dart';
import 'package:businessmindset/config/revenuecat_keys.dart';
import 'package:businessmindset/services/trial_duration_ab_service.dart';
import 'package:businessmindset/services/notification_service.dart';

class OnBoarding38 extends ConsumerStatefulWidget {
  const OnBoarding38({
    super.key,
    this.forward,
  });
  final Function(int)? forward;

  @override
  ConsumerState<OnBoarding38> createState() => _OnBoarding38State();
}

class _OnBoarding38State extends ConsumerState<OnBoarding38> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  
  bool _reminderEnabled = false;
  bool _isLoading = false;
  int _trialDays = 7; // Par défaut 7 jours
  bool _isInTrial = false; // Par défaut, on suppose qu'il est en trial (pour le cas Web)
  bool _isCheckingTrialStatus = true; // Indique si on est en train de vérifier le statut
  
  @override
  void initState() {
    super.initState();
    _determineTrialDays();
    _checkTrialStatus();
  }
  
  /// Check the REAL STATUS of the ongoing trial (not eligibility)
  /// 
  /// IMPORTANT NOTE: This method is different from the eligibility check
  /// performed in onboarding33 and paywall.
  /// 
  /// - Eligibility (onboarding33/paywall): CAN the user start a trial?
  ///   Logique : !hasActive && !hasHistory
  /// 
  /// - Trial status (here): Is the user CURRENTLY on trial?
  ///   Logic: Check if active entitlement with periodType = trial/intro
  /// 
  /// This detection uses the REAL RevenueCat data after purchase,
  /// so it's reliable and does NOT need the !hasActive && !hasHistory logic.
  Future<void> _checkTrialStatus() async {
    debugPrint("checktrial");
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await RevenueCatService.instance.ensureConfigured(appUserId: userId);
      final info = await RevenueCatService.instance.getCustomerInfo(forceRefresh: true);
      
      final entitlement = info.entitlements.active[revenueCatEntitlementId];
      if (entitlement != null) {
        debugPrint("checktrial != null");
        // Check whether the user is on trial (periodType = trial or intro)
        final periodType = entitlement.periodType;
        final isInTrial = RevenueCatService.instance.isTrialPeriod(periodType);
        
        setState(() {
          _isInTrial = isInTrial;
          _isCheckingTrialStatus = false;
        });
      } else {
        debugPrint("checktrial == null");
        // No active entitlement, consider the user not on trial
        setState(() {
          _isInTrial = false;///TODO true ??
          _isCheckingTrialStatus = false;
        });
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to check trial status: $error');
      }
      setState(() {
        _isInTrial = false;
        _isCheckingTrialStatus = false;
      });
    }
  }
  
  Future<void> _determineTrialDays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (kIsWeb) {
        final d = await TrialDurationAbService.getAssignedTrialDays(prefs);
        setState(() => _trialDays = d);
        return;
      }
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await RevenueCatService.instance.ensureConfigured(appUserId: userId);
      final info = await RevenueCatService.instance.getCustomerInfo(forceRefresh: true);
      final days = await TrialDurationAbService.resolveTrialDaysFromCustomerInfo(info, prefs);
      setState(() => _trialDays = days);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to determine trial days: $error');
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        final d = await TrialDurationAbService.getAssignedTrialDays(prefs);
        setState(() => _trialDays = d);
      } catch (_) {
        setState(() => _trialDays = 7);
      }
    }
  }
  
  /// Save the trial-end reminder
  /// 
  /// This function uses the REAL data of the ongoing trial (via periodType)
  /// to compute the end date and schedule a notification 2 days before.
  /// No need for the !hasActive && !hasHistory eligibility logic because we
  /// works with an already active trial.
  Future<void> _saveTrialReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = ref.read(languageProvider);
    
    // Store the bool
    await prefs.setBool('trial_reminder', _reminderEnabled);
    
    if (_reminderEnabled) {
      // Compute the reminder date (2 days before trial end)
      final now = DateTime.now();
      final trialEndDate = now.add(Duration(days: _trialDays));
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
      // Use forward so _nextPage handles navigation and hasOnboard
      if (widget.forward != null) {
        widget.forward!(1);
      }
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
                      // Use forward so _nextPage handles navigation and hasOnboard
                      if (widget.forward != null) {
                        widget.forward!(1);
                      }
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final userName = ref.watch(userNameStateProvider);
    debugPrint("isTrial : $_isInTrial");
    
    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      color: appTheme.background,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Contenu principal
            Builder(
              builder: (context) {
                // Enable scroll only if text scale > 1.0
                final textScale = MediaQuery.of(context).textScaler.scale(1.0);
                final shouldEnableScroll = textScale > 1.0;
                
                final content = Padding(
                  padding: EdgeInsets.only(top: 5 * yFact, left: 20 * xFact, right: 20 * xFact),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
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
                                  child: MediaQuery(
                                    data: MediaQuery.of(context).copyWith(
                                      textScaler: const TextScaler.linear(1.0),
                                    ),
                                    child: Text(
                                      translate("youre_on_fire", lang),
                                      style: TextStyle(
                                          fontFamily: "InterTight",
                                          fontSize: 18*xFact,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
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
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: 20 * xFact,
                          right: 20 * xFact,
                          bottom: 30 * yFact,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if(_isInTrial) Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Builder(
                                  builder: (context) {
                                    final currentScale = MediaQuery.of(context).textScaler.scale(1.0);
                                    // Clamp the scale to 1.0 if >= 1.2
                                    return MediaQuery(
                                      data: MediaQuery.of(context).copyWith(
                                        textScaler: currentScale >= 1.2
                                            ? const TextScaler.linear(1.1)
                                            : MediaQuery.of(context).textScaler,
                                      ),
                                      child: Text(
                                        translate("remind_me_before_trial_ends", lang),
                                        style: TextStyle(
                                          fontFamily: "InterTight",
                                          fontSize: 16 * xFact,
                                          color: appTheme.onBackground,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  },
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
                                    onChanged: _isInTrial && !_isCheckingTrialStatus ? (value) {
                                      setState(() {
                                        _reminderEnabled = value;
                                      });
                                      if (value) {
                                        MixpanelService.instance.track('[Trial Reminder] Activé dans onboarding');
                                      }
                                    } : null, // Désactiver si l'utilisateur n'est pas en trial
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
                                text: translate("lets_get_started", lang),
                                icon: Icons.arrow_right_alt,
                                iconSize: 40 * xFact,
                                onTap: _isLoading ? null : _handleGetStarted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )

                  ],
                ),
              );
              
              // Return with or without scroll depending on textScale
              if (shouldEnableScroll) {
                return SingleChildScrollView(
                  child: content,
                );
              } else {
                return content;
              }
            },
          ),
            // Button at the bottom in a separate column

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
}

