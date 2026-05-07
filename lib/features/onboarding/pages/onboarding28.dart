import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/habits_provider.dart';

class OnBoarding28 extends ConsumerStatefulWidget {
  const OnBoarding28({
    super.key,
    required this.backIcon,
    required this.progress,
    this.backward,
    this.forward,
  });
  final bool backIcon;
  final double progress;
  final VoidCallback? backward;
  final VoidCallback? forward;

  @override
  ConsumerState<OnBoarding28> createState() => _OnBoarding28State();
}

class _OnBoarding28State extends ConsumerState<OnBoarding28> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final userName = ref.watch(userNameStateProvider);
    final imagePath = 'assets/images/flamy/flamy_glasses_punch.png';
    
    // Replace %NAME% in the texts
    String titleText = translate("onboardingtitle28", lang);
    titleText = titleText.replaceAll("%NAME%", userName);
    String subtitleText = translate("onboardingsubtitle28", lang);
    
    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      color: appTheme.background,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.of(context).textScaler.clamp(
            minScaleFactor: 1.0,
            maxScaleFactor: 1.4,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
          children: [
            // Back icon at the top left
            if (widget.backIcon)
              Positioned(
                top: 15 * yFact,
                left: 20 * xFact,
                child: GestureDetector(
                  onTap: widget.backward,
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: appTheme.onBackground,
                  ),
                ),
              ),
            // Progress bar at top center
            Positioned(
              top: 9,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 55 * xFact, vertical: 15 * yFact),
                child: Container(
                  height: 4 * yFact,
                  decoration: BoxDecoration(
                    color: Color(0xFFb4ac9c).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2 * yFact),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widget.progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: appTheme.onPrimButtonGold,
                        borderRadius: BorderRadius.circular(2 * yFact),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 20*xFact,right: 20*xFact,bottom: 30*yFact),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 50*yFact,
                  ),

                  // Centered content
                  Column(
                    children: [
                      SizedBox(
                        width: 290*xFact,
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(
                        height: 35*yFact,
                      ),
                      Text(
                        titleText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "YesevaOne",
                          fontSize: 28*xFact,
                          color: appTheme.onBackground,
                        ),
                      ),
                      SizedBox(
                        height: 10*yFact,
                      ),
                      Text(
                        subtitleText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "YesevaOne",
                          fontSize: 28*xFact,
                          color: appTheme.onBackground,
                        ),
                      ),
                    ],
                  ),

                  PrimaryButton(
                    text: translate("see_the_results", lang),
                    icon: Icons.arrow_right_alt,
                    iconSize: 40*xFact,
                    onTap: () => widget.forward!(),
                  ),
                ],
              ),
            ),
            // Bouton en bas

            ],
          ),
        ),
      ),
    );
  }
}

