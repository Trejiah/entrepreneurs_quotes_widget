import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:businessmindset/providers/language_provider.dart';

class OnBoarding13bis extends ConsumerStatefulWidget {
  const OnBoarding13bis({
    super.key,
    this.forward
  });
  final VoidCallback? forward;

  @override
  ConsumerState<OnBoarding13bis> createState() => _OnBoarding13State();
}

class _OnBoarding13State extends ConsumerState<OnBoarding13bis> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  void initState() {
    super.initState();
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
            Padding(
              padding: EdgeInsets.only(left: 20*xFact,right: 20*xFact,bottom: 30*yFact),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 50*yFact,
                  ),
                  Stack(
                    children: [
                      SizedBox(
                        width: 320*xFact,
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                          top: 27*yFact,
                          right: 22*xFact,
                          child: SizedBox(
                            width: 130*xFact,
                            height: 65*yFact,
                            child: Center(
                              child: MediaQuery(
                                // Force text scale to 1.0 for this specific text
                                // so it always stays at 13pt actual, regardless of accessibility settings
                                data: MediaQuery.of(context).copyWith(
                                  textScaler: const TextScaler.linear(1.0),
                                ),
                                child: Text(
                                  translate("onboarding13_flamy_quote", lang),
                                  style: TextStyle(
                                    fontSize: 13*xFact,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: "InterTight",
                                    color: Colors.black,

                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          )
                      )
                    ],
                  ),
                  SizedBox(
                    height: 15*yFact,
                  ),
                  Column(
                    children: [
                      // Centered content
                      Text(
                        translate("onboarding13bis_title", lang),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "YesevaOne",
                          fontSize: 28*xFact,
                          color: appTheme.onBackground,
                        ),
                      ),
                      Text(
                        translate("onboarding13bis_subtitle", lang),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "InterTight",
                          fontWeight: FontWeight.w600,
                          fontSize: 18*xFact,
                          color: appTheme.onBackgroundSub,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: 30*yFact,
                  ),
                  PrimaryButton(
                    text: translate("letsgo", lang),
                    icon: Icons.arrow_right_alt,
                    iconSize: 40*xFact,
                    onTap: () => widget.forward!(),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

