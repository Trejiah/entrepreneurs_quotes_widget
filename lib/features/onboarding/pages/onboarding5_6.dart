import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
class OnBoarding56 extends ConsumerStatefulWidget {
  const OnBoarding56({
    super.key,
    this.forward,
  });
  final VoidCallback? forward;

  @override
  ConsumerState<OnBoarding56> createState() => _OnBoarding56State();
}

class _OnBoarding56State extends ConsumerState<OnBoarding56> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  int currentScreen = 0; // 0 = première image, 1 = deuxième image

  @override
  void initState() {
    super.initState();
  }

  void handleTap() {
    if (currentScreen == 0) {
      // Move to the second image
      setState(() {
        currentScreen = 1;
      });
    } else {
      // Call forward after the second image
      widget.forward!();
    }
  }

  void _handleSwipeLeft(BuildContext context, DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double kMinDx = screenWidth * 0.2;
    final vx = details.velocity.pixelsPerSecond.dx;
    final bool flingLeft = vx <= -300;
    final bool farLeft = details.primaryVelocity != null && details.primaryVelocity! < -kMinDx;

    if (flingLeft || farLeft) {
      handleTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return GestureDetector(
      onTap: handleTap,
      onHorizontalDragEnd: (details) => _handleSwipeLeft(context, details),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: double.maxFinite,
        width: double.maxFinite,
        color: appTheme.background,
        child: SafeArea(
          bottom: false,
          child: Align(
            alignment: AlignmentGeometry.center,
            child: Padding(
              padding: EdgeInsets.only(bottom: 60*yFact),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image Flamy
                  SizedBox(
                    height: 300 * yFact,
                    child: Image.asset(
                      currentScreen == 0
                          ? 'assets/images/flamy/flamy_ok.png'
                          : 'assets/images/flamy/flamy_look.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(
                    height: 15 * yFact,
                  ),
                  // Texte
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40 * xFact),
                    child: Text(
                      currentScreen == 0
                          ? translate("onboarding56_text1", lang)
                          : translate("onboarding56_text2", lang),
                      style: TextStyle(
                        fontFamily: "YesevaOne",
                        fontSize: 28 * xFact,
                        color: appTheme.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

