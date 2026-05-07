import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/widgets/app_button.dart';

class OnBoarding14 extends ConsumerStatefulWidget {
  const OnBoarding14({
    super.key,
    required this.pageStyle,
    required this.backIcon,
    required this.title,
    required this.subTitle,
    required this.choiceList,
    required this.progress,
    this.backward,
    this.forward,
    this.variable,
    this.toCheck = false,
  });
  final String pageStyle;
  final bool backIcon;
  final String title;
  final String subTitle;
  final double progress; // Valeur entre 0.0 et 1.0
  final String? variable;
  final VoidCallback? backward;
  final VoidCallback? forward;
  final List<String> choiceList;
  final bool toCheck;

  @override
  ConsumerState<OnBoarding14> createState() => _OnBoarding14State();
}

class _OnBoarding14State extends ConsumerState<OnBoarding14> {
  String pageStyle = "";
  List<String> choiceList = [];
  List<bool> isChecked = [];
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  void initState() {
    super.initState();
    pageStyle = widget.pageStyle;
    choiceList = widget.choiceList;
    if (widget.toCheck || pageStyle == "check2") {
      isChecked = List.filled(choiceList.length, false);
      _loadSavedSelections();
    }
  }

  void _loadSavedSelections() async {
    if (widget.variable == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getStringList("${widget.variable}");

      final selected = <String>[];

      if (savedData != null) {
        for (int i = 0; i < savedData.length; i++) {
          selected.add(savedData[i]);
        }
      }
      for (int j = 0; j < choiceList.length; j++) {
        isChecked[j] = selected.contains(choiceList[j]);
      }

      if (mounted) {
        setState(() {}); // pour rafraîchir l'affichage
      }
    });
  }

  @override
  void didUpdateWidget(covariant OnBoarding14 oldWidget) {
    super.didUpdateWidget(oldWidget);
    pageStyle = widget.pageStyle;
    choiceList = widget.choiceList;
    
    // Check whether the variable changed or the list length changed
    final variableChanged = widget.variable != oldWidget.variable;
    final listLengthChanged = isChecked.length != choiceList.length;
    
    if ((widget.toCheck || pageStyle == "check2") && (variableChanged || listLengthChanged)) {
      isChecked = List.filled(choiceList.length, false);
      _loadSavedSelections();
    }
  }

  handleTap(String choice) async {
    final prefs = await SharedPreferences.getInstance();
    if (widget.variable != null) await prefs.setString("${widget.variable}", choice);
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("handleTap save : ");
      debugPrint("${widget.variable} : $choice");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
    if (widget.forward != null) {
      widget.forward!();
    }
  }

  handleCheckTap() async {
    List<String> savedList = [];
    for (var i = 0; i < choiceList.length; i++) {
      if (isChecked[i]) {
        savedList.add(choiceList[i]);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    if (widget.variable != null) {
      await prefs.setStringList("${widget.variable}", savedList);
    }
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("handleCheckTap save : ");
      debugPrint("${widget.variable} : $savedList");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
    if (widget.forward != null) {
      widget.forward!();
    }
  }

  bool get hasSelection => isChecked.any((checked) => checked);

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      color: appTheme.background,
        child: SafeArea(
          bottom: false,
          child: Builder(
            builder: (context) {
              // Enable scroll only if text scale > 1.0
              final textScale = MediaQuery.of(context).textScaler.scale(1.0);
              final shouldEnableScroll = textScale > 1.0;
              
              final content = Stack(
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
                        color: Color(0xFFfff9ee),
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
                  padding: EdgeInsets.only(top: 40*yFact, bottom: 30*xFact),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // flamy_nerd.png image above the title
                      SizedBox(
                        height: 100 * yFact,
                        child: Image.asset(
                          'assets/images/flamy/flamy_nerd.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(
                        height: 0 * yFact,
                      ),
                      Padding(
                        padding: EdgeInsetsGeometry.only(left: 30 * xFact, right: 30 * xFact),
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontFamily: "YesevaOne",
                            fontSize: 24 * xFact,
                            color: Color(0xFFfff9ee),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        height: 10 * yFact,
                      ),
                      Padding(
                        padding: EdgeInsetsGeometry.only(left: 40 * xFact, right: 40 * xFact),
                        child: Text(
                          widget.subTitle,
                          style: TextStyle(
                            fontFamily: "InterTight",
                            fontSize: 16 * xFact,
                            color: Color(0xFFb4ac9c),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (pageStyle == "choices" || pageStyle == "check2") SizedBox(
                        height: 15 * yFact,
                      ),
                      if (pageStyle == "choices" && !widget.toCheck) Column(
                        children: List.generate(
                          choiceList.length, (index) {
                            return Column(
                              children: [
                                Padding(
                                  padding: EdgeInsetsGeometry.only(left: 20 * xFact, right: 20 * xFact),
                                  child: TertiaryButton(
                                    center: false,
                                    borderWidth: 1 * xFact,
                                    text: translate(choiceList[index], lang),
                                    onTap: () => {
                                      handleTap(choiceList[index])
                                    },
                                  ),
                                ),
                                if (index < choiceList.length - 1)
                                  SizedBox(
                                    height: 10 * yFact,
                                  )
                              ],
                            );
                          }
                        ),
                      ),
                      if (pageStyle == "choices" && widget.toCheck)
                        shouldEnableScroll
                          ? Container(
                              height: 350*yFact,
                              child: ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                shrinkWrap: true,
                                padding: EdgeInsets.only(bottom: 70 * yFact),
                                itemCount: choiceList.length,
                                itemBuilder: (context, index) {
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
                                        child: TertiaryCheckButton(
                                          text: translate(choiceList[index], lang),
                                          checked: isChecked[index],
                                          onChanged: (v) => setState(() => isChecked[index] = v),
                                        ),
                                      ),
                                      if (index < choiceList.length - 1)
                                        SizedBox(
                                          height: 10 * yFact,
                                        )
                                    ],
                                  );
                                },
                              ),
                            )
                          : Expanded(
                              child: ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.only(bottom: 70 * yFact),
                                itemCount: choiceList.length,
                                itemBuilder: (context, index) {
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
                                        child: TertiaryCheckButton(
                                          text: translate(choiceList[index], lang),
                                          checked: isChecked[index],
                                          onChanged: (v) => setState(() => isChecked[index] = v),
                                        ),
                                      ),
                                      if (index < choiceList.length - 1)
                                        SizedBox(
                                          height: 10 * yFact,
                                        )
                                    ],
                                  );
                                },
                              ),
                            ),
                      if (pageStyle == "check2")
                        shouldEnableScroll
                          ? Container(
                              height: textScale > 1.4 ? 540*yFact : textScale > 1.3 ? 505*yFact : textScale > 1.2 ? 470*yFact :430*yFact, // Hauteur fixe pour le scroll
                              child: ListView.separated(
                                physics: NeverScrollableScrollPhysics(), //const BouncingScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: choiceList.length,
                                separatorBuilder: (context, index) => Divider(
                                  color: appTheme.onBackground,
                                  thickness: 1 * yFact,
                                  height: 12 * yFact,
                                ),
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isChecked[index] = !isChecked[index];
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(color: Colors.transparent),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.circle_rounded,
                                                  size: 12 * xFact,
                                                  color: Color(0xFFfff9ee),
                                                ),
                                                SizedBox(width: 8 * xFact),
                                                Text(
                                                  translate(choiceList[index], lang),
                                                  style: TextStyle(
                                                    color: Color(0xFFfff9ee),
                                                    fontFamily: 'InterTight',
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16 * xFact,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Icon(
                                              isChecked[index] ? Icons.check : Icons.add,
                                              size: 20 * xFact,
                                              color: Color(0xFFfff9ee),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Expanded(
                            child: ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.only(bottom: 70 * yFact),
                                itemCount: choiceList.length,
                                separatorBuilder: (context, index) => Divider(
                                  color: appTheme.onBackground,
                                  thickness: 1 * yFact,
                                  height: 12 * yFact,
                                ),
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isChecked[index] = !isChecked[index];
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(color: Colors.transparent),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.circle_rounded,
                                                  size: 12 * xFact,
                                                  color: Color(0xFFfff9ee),
                                                ),
                                                SizedBox(width: 8 * xFact),
                                                Text(
                                                  translate(choiceList[index], lang),
                                                  style: TextStyle(
                                                    color: Color(0xFFfff9ee),
                                                    fontFamily: 'InterTight',
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16 * xFact,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Icon(
                                              isChecked[index] ? Icons.check : Icons.add,
                                              size: 23 * xFact,
                                              color: Color(0xFFfff9ee),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ),
                      SizedBox(
                        height: (pageStyle != "check2") ? textScale > 1.0 && textScale < 1.2 ? 138*yFact : textScale > 1.3 ? 100*yFact : 20*yFact : 20*yFact,
                      ),
                      if (pageStyle == "check2" && textScale > 1.0 )
                        Opacity(
                        opacity: hasSelection ? 1.0 : 0.5,
                        child: IgnorePointer(
                          ignoring: !hasSelection,
                          child: SecondaryButton(
                            text: translate("continue", lang),
                            onTap: () => handleCheckTap(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Continue button at the bottom (if toCheck is true or if check2)
              if ((pageStyle == "choices" && widget.toCheck) || (pageStyle == "check2" && textScale <= 1.0 ))
                Positioned(
                  bottom: 30 * yFact,
                  left: 20 * xFact,
                  right: 20 * xFact,
                  child: Opacity(
                    opacity: hasSelection ? 1.0 : 0.5,
                    child: IgnorePointer(
                      ignoring: !hasSelection,
                      child: SecondaryButton(
                        text: translate("continue", lang),
                        onTap: () => handleCheckTap(),
                      ),
                    ),
                  ),
                ),
                ],
              );
              
              // Return with or without scroll depending on textScale
              if (shouldEnableScroll) {
                return SingleChildScrollView(child: content);
              } else {
                return content;
              }
            },
          ),
      ),
    );
  }
}

