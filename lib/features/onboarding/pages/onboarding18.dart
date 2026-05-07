import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/widgets/app_button.dart';

class OnBoarding18 extends ConsumerStatefulWidget {
  const OnBoarding18({
    super.key,
    required this.backIcon,
    required this.skipLink,
    this.backward,
    this.buttonText,
    this.forward,
  });
  final bool backIcon;
  final bool skipLink;
  final String? buttonText;
  final VoidCallback? backward;
  final VoidCallback? forward;

  @override
  ConsumerState<OnBoarding18> createState() => _OnBoarding18State();
}

class _OnBoarding18State extends ConsumerState<OnBoarding18> {
  String pageStyle = "";
  List<String> choiceList=[];
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  //int dayCount = 0;
  List<bool> daySelected = [];
  String topics = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Locale OK ici
    final locale = Localizations.localeOf(context);
    final startsOnSunday = locale.countryCode == 'US';

    // ⬇️ Do not modify a provider during build:
    // defer the write after the current frame, and only if needed.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final current = ref.read(startsOnSundayProvider);
      if (current != startsOnSunday) {
        ref.read(startsOnSundayProvider.notifier).state = startsOnSunday;
      }

      final prefs = await SharedPreferences.getInstance();
      final topicsData = prefs.getStringList("topics") ?? [];
      final selected = List<String>.from(topicsData);

      if (kDebugMode) {
        debugPrint("selected in get: $selected");
      }

      setState(() {
        topics = selected.join(", ");
      });
    });

  }

  String getLocalizedDaysString({
    required List<bool> localizedDays,
    required Locale locale,
  }) {
    // Days by language
    final isFrench = locale.languageCode == 'fr';
    final enDays = ["M", "Tu", "W", "Th", "F", "Sa", "Su"];
    final frDays = ["L", "Ma", "Me", "J", "V", "S", "D"];
    final days = isFrench ? frDays : enDays;

    // Select the active days
    final selected = <String>[];
    for (int i = 0; i < localizedDays.length; i++) {
      if (localizedDays[i]) selected.add(days[i]);
    }
    if(kDebugMode){
      debugPrint("selected in get: $selected");
    }
    // Concatenate nicely
    return selected.join(", ");
  }


  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    //final (backGroundColor, color2, color3, p1, p2, p3, nrb, fontFamily, foreGroundColor, name, isImage, imageTxt) = ref.watch(currentThemeProvider);
    final Map<String,dynamic> themeMap = ref.watch(currentThemeProvider);

    final startHHmm = ref.watch(startHHmmProvider);
    final endHHmm   = ref.watch(endHHmmProvider);
    final localizedDays = ref.watch(daySelectedLocalizedProvider);

    final userName = ref.watch(userNameStateProvider);
    final dayCount = ref.watch(dayCountProvider);

    final locale = Localizations.localeOf(context);
    final totDays = getLocalizedDaysString(localizedDays: localizedDays, locale: locale);
    if(kDebugMode){
      debugPrint("totDays : $totDays");
    }
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
                            color: Color(0xFFfff9ee),
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
                              color: Color(0xFFb4ac9c),
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
              child: Padding(
                padding: EdgeInsetsGeometry.only(left: 30*xFact,right: 30*xFact),
                child: Column(
                  mainAxisAlignment : MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "${translate("onboardingtitle18_0",lang)} $userName!\n${translate("onboardingtitle18_1",lang)}",
                      style: TextStyle(
                        fontFamily: "YesevaOne",
                        fontSize: 28*xFact,
                        color: appTheme.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 50*yFact,
                    ),
                    Row(
                      children: [
                        Icon(Icons.check,color: appTheme.onPrimButtonGold,),
                        SizedBox(width: 5*xFact,),
                        Text(
                          "${translate("theme:", lang)} ${themeMap["name"]}",
                          style: TextStyle(
                            fontFamily: "YesevaOne",
                            fontSize: 18*xFact,
                            color: appTheme.onBackground,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20*yFact,
                    ),
                    Row(
                      children: [
                        Icon(Icons.check,color: appTheme.onPrimButtonGold,),
                        SizedBox(width: 5*xFact,),
                        Text(
                          "${translate("reminder:", lang)} $dayCount per day",
                          style: TextStyle(
                            fontFamily: "YesevaOne",
                            fontSize: 18*xFact,
                            color: appTheme.onBackground,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20*yFact,
                    ),
                    Row(
                      children: [
                        Icon(Icons.check,color: appTheme.onPrimButtonGold,),
                        SizedBox(width: 5*xFact,),
                        Flexible(
                          child: Text(
                            "${translate("schedule:", lang)} $startHHmm-$endHHmm; $totDays",
                            style: TextStyle(
                              fontFamily: "YesevaOne",
                              fontSize: 18 * xFact,
                              color: appTheme.onBackground,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20*yFact,
                    ),
                    Row(
                      children: [
                        Icon(Icons.check,color: appTheme.onPrimButtonGold,),
                        SizedBox(width: 5*xFact,),
                        Flexible(
                          child: Text(
                            "${translate("focusa:", lang)} $topics",
                            style: TextStyle(
                              fontFamily: "YesevaOne",
                              fontSize: 18*xFact,
                              color: appTheme.onBackground,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsGeometry.only(right: 20*xFact,left: 20*xFact,bottom: 30*yFact),
              child: Align(
                alignment: AlignmentGeometry.bottomCenter,
                child: SecondaryButton(
                  text: translate(widget.buttonText!,lang),
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