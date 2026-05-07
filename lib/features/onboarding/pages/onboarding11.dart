import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/theme/themedatas.dart';
import 'package:businessmindset/widgets/app_button.dart';

class OnBoarding11 extends ConsumerStatefulWidget {
  const OnBoarding11({
    super.key,
    required this.backIcon,
    required this.skipLink,
    required this.title,
    this.backward,
    this.buttonText,
    this.forward,
  });
  final bool backIcon;
  final bool skipLink;
  final String title;
  final String? buttonText;
  final VoidCallback? backward;
  final VoidCallback? forward;

  @override
  ConsumerState<OnBoarding11> createState() => _OnBoarding11State();
}

class _OnBoarding11State extends ConsumerState<OnBoarding11> {
  String pageStyle = "";
  List<String> choiceList=[];
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  int selectedIndex =0;
  Map<String,dynamic> currentTheme = allAppThemes[0];

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    selectedIndex = prefs.getInt("theme") ?? 0;
    currentTheme = allAppThemes[selectedIndex];
    setState(() {});
  }

  Widget _buildBackgroundWidget(Map<String, dynamic> theme, bool isCustom) {
    final isImage = theme["isImage"] == true;
    final imageName = theme["imageName"] as String?;

    if (!isImage) {
      final color1 = Color(theme["color1"] as int);
      final color2 = theme["color2"] != null ? Color(theme["color2"] as int) : null;
      final color3 = theme["color3"] != null ? Color(theme["color3"] as int) : null;
      final nbrcolor = theme["nbrcolor"] as int? ?? 1;
      final p1 = (theme["p1"] as num?)?.toDouble() ?? 0.0;
      final p2 = (theme["p2"] as num?)?.toDouble() ?? 0.0;
      final p3 = (theme["p3"] as num?)?.toDouble() ?? 0.0;

      if (nbrcolor == 1) {
        return Container(color: color1);
      } else if (nbrcolor == 2 && color2 != null) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color1, color2],
              stops: [p1, p2],
            ),
          ),
        );
      } else if (nbrcolor == 3 && color2 != null && color3 != null) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color1, color2, color3],
              stops: [p1, p2, p3],
            ),
          ),
        );
      } else {
        return Container(color: color1);
      }
    } else {
      if (imageName == null || imageName.isEmpty) {
        return Container(color: Color(theme["color1"] as int));
      }

      if (isCustom) {
        final file = File(imageName);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: Color(theme["color1"] as int));
            },
          );
        } else {
          return Container(color: Color(theme["color1"] as int));
        }
      } else {
        return Image.asset(
          "assets/images/backgrounds/$imageName",
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: Color(theme["color1"] as int));
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final Map<String,dynamic> themeMap = ref.watch(currentThemeProvider);
    final isCustomTheme = ref.watch(isCustomThemeProvider);
    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      color: appTheme.background,
      child: Stack(
        children: [
          // Background that spans the full screen (including under the system bar)
          Positioned.fill(child: _buildBackgroundWidget(themeMap, isCustomTheme)),
          // Content with SafeArea to respect the top system bar
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: 15*yFact,
                    ),
                    (widget.backIcon || widget.skipLink) ? Padding(
                      padding: EdgeInsetsGeometry.only(left: 20*xFact,right: 20*xFact),
                      child: SizedBox(
                        height: 26*yFact,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            widget.backIcon ? GestureDetector(
                              onTap: widget.backward,
                              child: Icon(
                                Icons.arrow_back_ios,
                                color: Color(themeMap["fontcolor"]),
                              ),
                            ) : SizedBox(
                              width: 25*xFact,
                            ),
                            widget.skipLink ? GestureDetector(
                              onTap: widget.forward,
                              child: Text(
                                translate("skip",lang),
                                style: TextStyle(
                                  fontFamily: "InterTight",
                                  fontSize: 18*xFact,
                                  color: appTheme.onBackgroundSub,
                                ),
                              ),
                            ) : SizedBox(
                              width: 25*xFact,
                            ),
                          ],
                        ),
                      ),
                    ) : SizedBox(
                      height: 26*yFact,
                    ),
                  ],
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsetsGeometry.only(left: 40*xFact,right: 40*xFact),
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontFamily: themeMap["fontfamily"],
                            fontSize: 24*xFact,
                            color: Color(themeMap["fontcolor"]),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsGeometry.only(right: 20*xFact,left: 20*xFact,bottom: 30*yFact),
                  child: Align(
                    alignment: AlignmentGeometry.bottomCenter,
                    child: SecondaryButton(
                      text: translate(widget.buttonText!,lang),
                      onTap: () {
                        widget.forward!();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}