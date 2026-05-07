import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/features/home/view/home_page.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'onboarding_restore_flow.dart';

class OnBoarding0 extends ConsumerStatefulWidget {
  const OnBoarding0({
    super.key,
    this.forward
  });
  final VoidCallback? forward;

  @override
  ConsumerState<OnBoarding0> createState() => _OnBoarding0State();
}

class _OnBoarding0State extends ConsumerState<OnBoarding0> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  Timer? _typingTimer;
  String _displayedText = "";
  final String _fullText = "Winners never quit and quitters never win...";
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTypingAnimation();
  }

  void _startTypingAnimation() {
    _typingTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (_currentIndex < _fullText.length) {
        setState(() {
          _displayedText = _fullText.substring(0, _currentIndex + 1);
          _currentIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }


  logIn(String lang, BuildContext ctx) async {
    await OnboardingRestoreFlow.runFullFlow(
      context: ctx,
      ref: ref,
      lang: lang,
      goHome: ({required bool skipRevenueCatCheck}) async {
        await goHome(skipRevenueCatCheck: skipRevenueCatCheck);
      },
    );
  }


  goHome({bool skipRevenueCatCheck = false}) async {
    await OnboardingRestoreFlow.prepareGoHome(skipRevenueCatCheck: skipRevenueCatCheck);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final imagePath = 'assets/images/flamy/flamy_onboard0.png';
    
    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      color: appTheme.background,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Image de fond
            Center(
              child: Stack(
                children: [
                  SizedBox(
                    width: 350*xFact,
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                      top: 29*yFact,
                      right: 25*xFact,
                      child: SizedBox(
                        width: 142*xFact,
                        height: 80*yFact,
                        child: Center(
                          child: MediaQuery(
                            // Force text scale to 1.0 for this specific text
                            // so it always stays at 14pt actual, regardless of accessibility settings
                            data: MediaQuery.of(context).copyWith(
                              textScaler: const TextScaler.linear(1.0),
                            ),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  // Visible characters
                                  TextSpan(
                                    text: _displayedText,
                                    style: TextStyle(
                                      fontSize: 14*xFact,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: "InterTight",
                                      color: Colors.black,
                                    ),
                                  ),
                                  // Invisible characters to keep the position
                                  TextSpan(
                                    text: _fullText.substring(_currentIndex),
                                    style: TextStyle(
                                      fontSize: 14*xFact,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: "InterTight",
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ),
                      )
                  )
                ],
              ),
            ),
            // Centered content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 10*xFact),
                        child: FittedBox(
                          child: Text(
                            translate("Business Mindset", lang),
                            style: TextStyle(
                              fontFamily: "YesevaOne",
                              fontSize: 38*xFact,
                              color: appTheme.onBackground,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 30*yFact,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40*xFact),
                        child: Text(
                          translate("onboarding0_subtitle", lang),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "InterTight",
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            fontSize: 20*xFact,
                            color: appTheme.onBackground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 20*xFact,left: 20*xFact),
                        child: Align(
                          alignment: AlignmentGeometry.bottomCenter,
                          child: PrimaryButton(
                            text: translate("letsbegin", lang),
                            icon: Icons.arrow_right_alt,
                            iconSize: 40*xFact,
                            onTap: () => widget.forward!(),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10*yFact,
                      ),
                      GestureDetector(//userSign ?
                        onTap: () {
                          logIn(lang,context);
                        },
                        child: SizedBox(
                          height: 50*yFact,
                          child: Center(
                            child: Text(
                              translate("Already registered?", lang),
                              style: TextStyle(
                                fontFamily: "InterTight",
                                fontSize: 18*xFact,
                                color: appTheme.onBackground,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 15*yFact,
                      )
                    ],
                  )
                ],
              ),
            ),
            // Button and "Already registered?" at the bottom

          ],
        ),
      ),
    );
  }
}

