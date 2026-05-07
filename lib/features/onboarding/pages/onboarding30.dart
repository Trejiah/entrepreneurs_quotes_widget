import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/habits_provider.dart';

class OnBoarding30 extends ConsumerStatefulWidget {
  const OnBoarding30({
    super.key,
    this.forward,
  });
  final VoidCallback? forward;

  @override
  ConsumerState<OnBoarding30> createState() => _OnBoarding30State();
}

class _OnBoarding30State extends ConsumerState<OnBoarding30> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  Timer? _autoForwardTimer;
  bool _hasForwarded = false;

  @override
  void initState() {
    super.initState();
    // 3-second timer for automatic forward
    _autoForwardTimer = Timer(Duration(seconds: 3), () {
      if (mounted && !_hasForwarded && widget.forward != null) {
        _hasForwarded = true;
        widget.forward!();
      }
    });
  }

  @override
  void dispose() {
    _autoForwardTimer?.cancel();
    super.dispose();
  }

  void _handleForward() {
    if (!_hasForwarded && widget.forward != null) {
      _hasForwarded = true;
      _autoForwardTimer?.cancel();
      widget.forward!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final userName = ref.watch(userNameStateProvider);
    final imagePath = 'assets/images/flamy/flamy_glasses.png';
    
    // Replace %NAME% in the texts
    String titleText = translate("onboardingtitle30", lang);
    titleText = titleText.replaceAll("%NAME%", userName);
    
    return GestureDetector(
      onTap: _handleForward,
      child: Container(
        height: double.maxFinite,
        width: double.maxFinite,
        color: appTheme.background,
        child: SafeArea(
          bottom: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(left: 20*xFact,right: 20*xFact),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 150*xFact,
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(
                    height: 35*yFact,
                  ),
                  // Centered content
                  Text(
                    titleText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "YesevaOne",
                      fontSize: 28*xFact,
                      color: appTheme.onBackground,
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

