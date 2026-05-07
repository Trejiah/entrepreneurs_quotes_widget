import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';

class OnBoarding19 extends ConsumerStatefulWidget {
  const OnBoarding19({
    super.key,
    this.forward,
  });
  final VoidCallback? forward;

  @override
  ConsumerState<OnBoarding19> createState() => _OnBoarding19State();
}

class _OnBoarding19State extends ConsumerState<OnBoarding19> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  void initState() {
    super.initState();
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
              Padding(
                padding: EdgeInsets.only(left: 20*xFact,right: 20*xFact,bottom: 30*yFact),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 300*yFact,
                      child: Image.asset(
                        'assets/images/flamy/flamy_glasses.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(
                      height: 15 * yFact,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40 * xFact),
                      child: Text(
                        translate("onboardingflame", lang),
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
            ],
          ),
        ),
      ),
    );
  }
}

