import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/widgets/common/diagram_bar.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/widgets/app_button.dart';

class OnBoarding8 extends ConsumerStatefulWidget {
  const OnBoarding8({
    super.key,
    required this.backIcon,
    required this.skipLink,
    required this.title,
    required this.subTitle,
    required this.choiceList,
    this.backward,
    this.buttonText,
    this.forward,
    this.variable,
  });
  final bool backIcon;
  final bool skipLink;
  final String title;
  final String subTitle;
  final String? variable;
  final String? buttonText;
  final VoidCallback? backward;
  final VoidCallback? forward;
  final List<String> choiceList;

  @override
  ConsumerState<OnBoarding8> createState() => _OnBoarding8State();
}

class _OnBoarding8State extends ConsumerState<OnBoarding8> {
  List<String> choiceList=[];
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  final List<(String, String)> labels = [
    ("Open", "open.png"),
    ("Like", "like.png"),
    ("Share", "share.png"),
  ];

  @override
  void initState() {
    super.initState();
    choiceList = widget.choiceList;
  }

  @override
  void didUpdateWidget(covariant OnBoarding8 oldWidget) {
    super.didUpdateWidget(oldWidget);
    choiceList = widget.choiceList;
  }


  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      color: appTheme.background,
      child: SafeArea(
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
                            color: appTheme.onBackground,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: AlignmentGeometry.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top : 35*yFact),
                    child: SizedBox(
                        height: 210*yFact,
                        width: 210*xFact,
                        child: Image.asset("assets/images/flamme.png")
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsGeometry.only(left: 40*xFact,right: 40*xFact),
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: "YesevaOne",
                      fontSize: 28*xFact,
                      color: appTheme.onBackground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: 15*yFact,
                ),
                Padding(
                  padding: EdgeInsetsGeometry.only(left: 55*xFact,right: 55*xFact),
                  child: Text(
                    widget.subTitle,
                    style: TextStyle(
                      fontFamily: "InterTight",
                      fontSize: 18*xFact,
                      color: appTheme.onBackgroundSub,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: 30*yFact,
                ),
                Container(
                  height: 220*yFact,
                  width: 320*xFact,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: appTheme.containerTertButton,
                      width: 1*xFact
                    ),
                    borderRadius: BorderRadius.circular(20*xFact)
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 5*yFact,
                      ),
                      SizedBox(
                        height: 210*yFact,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AnimatedWeeklyStats(
                              values: const [9, 6, 3],
                              nbrLabels: labels.length,
                              onBoarding: true,
                            ),
                            SizedBox(
                              height: 2*yFact,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 21*xFact,
                                ),
                                SizedBox(
                                  width: 200 * xFact,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: List.generate(labels.length, (i) {
                                      final (label, imagePath) = labels[i];
                                      return Column(
                                        children: [
                                          Text(
                                            translate(label, lang),
                                            style: TextStyle(
                                              fontFamily: "InterTight",
                                              fontSize: 12 * xFact,
                                              color: appTheme.onBackgroundSub,
                                            ),
                                          ),
                                          SizedBox(height: 3 * yFact),
                                          SizedBox(
                                            width: 13 * xFact,
                                            height: 13 * yFact,
                                            child: Image.asset("assets/images/$imagePath"),
                                          ),
                                        ],
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            Padding(
              padding: EdgeInsetsGeometry.only(right: 20*xFact,left: 20*xFact,bottom: 30*yFact),
              child: Align(
                alignment: AlignmentGeometry.bottomCenter,
                child: PrimaryButton(
                  text: translate(widget.buttonText!,lang),
                  icon: Icons.arrow_right_alt,
                  iconSize: 40*xFact,
                  onTap: () => widget.forward!(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}