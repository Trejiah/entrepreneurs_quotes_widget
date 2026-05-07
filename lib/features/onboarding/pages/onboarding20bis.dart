import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/widgets/app_button.dart';

class OnBoarding20bis extends ConsumerStatefulWidget {
  const OnBoarding20bis({
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
  ConsumerState<OnBoarding20bis> createState() => _OnBoarding20bisState();
}

class _OnBoarding20bisState extends ConsumerState<OnBoarding20bis> {
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
  void didUpdateWidget(covariant OnBoarding20bis oldWidget) {
    super.didUpdateWidget(oldWidget);
    choiceList = widget.choiceList;
  }



  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return Scaffold(
      body : Container(
        height: double.maxFinite,
        width: double.maxFinite,
        color: appTheme.background,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 40*yFact,
                  ),
                  Align(
                    alignment: AlignmentGeometry.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top : 50*yFact),
                      child: SizedBox(
                          height: 210*yFact,
                          width: 210*xFact,
                          child: Image.asset("assets/images/flamme.png")
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20*yFact,
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
                    height: 45*yFact,
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
      ),
    );
  }
}