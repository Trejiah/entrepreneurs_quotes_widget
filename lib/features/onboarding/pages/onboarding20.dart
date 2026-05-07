import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';

class OnBoarding20 extends ConsumerStatefulWidget {
  const OnBoarding20({
    super.key,
    this.forward,
  });
  final VoidCallback? forward;

  @override
  ConsumerState<OnBoarding20> createState() => _OnBoarding20State();
}

class _OnBoarding20State extends ConsumerState<OnBoarding20> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  int selectedBinome = 2; // Par défaut binôme 2

  @override
  void initState() {
    super.initState();
    _loadChallengeAndSelectBinome();
  }

  void _loadChallengeAndSelectBinome() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final challengeList = prefs.getStringList("challenge") ?? [];

      if (kDebugMode) {
        debugPrint("challenge list: $challengeList");
      }

      // Pair selection logic
      if (challengeList.contains("keepfoc")) {
        selectedBinome = 2;
      } else if (challengeList.contains("staycons")) {
        selectedBinome = 0;
      } else if (challengeList.contains("presdeal")) {
        selectedBinome = 1;
      } else if (challengeList.contains("mantim")) {
        selectedBinome = 3;
      } else {
        selectedBinome = 3; // Par défaut en cas d'erreur
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  void handleTap() {
    if (widget.forward != null) {
      widget.forward!();
    }
  }

  void _handleSwipeLeft(BuildContext context, DragEndDetails details) {
    if (widget.forward == null) return;
    
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

    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
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
          child: Stack(
            children: [
              // Centered content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Titre "Did you know?"
                    Padding(
                      padding: EdgeInsets.only(left: 30 * xFact,right: 30*xFact,top: 50*yFact),
                      child: Text(
                        translate("onboardingtitle22", lang),
                        style: TextStyle(
                          fontFamily: "YesevaOne",
                          fontSize: 34 * xFact,
                          color: appTheme.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      height: 20 * yFact,
                    ),
                    // Image flamy_teach
                    SizedBox(
                      height: textScale > 1.4 ? 150 * yFact : 265 * yFact,
                      child: Image.asset(
                        'assets/images/flamy/flamy_teach.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(
                      height: 20 * yFact,
                    ),
                    // Main text under the image
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30 * xFact),
                      child: Text(
                        translate("onboarding20_text$selectedBinome", lang),
                        style: TextStyle(
                          fontFamily: "YesevaOne",
                          fontSize: 22 * xFact,
                          color: appTheme.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      height: 50 * yFact,
                    ),
                  ],
                ),
              ),
              // Text with asterisk at the bottom left
              Positioned(
                bottom: 30 * yFact,
                left: 20 * xFact,
                right: 20 * xFact,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 40 * xFact,
                  ),
                  child: Text(
                    translate("onboarding20_asterisk$selectedBinome", lang),
                    style: TextStyle(
                      fontFamily: "InterTight",
                      fontSize: 14 * xFact,
                      color: appTheme.onBackground,
                    ),
                    textAlign: TextAlign.left,
                    softWrap: true,
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

