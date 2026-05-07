import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/services/notification_service.dart';
import 'package:businessmindset/widgets/common/weekday_selector.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:bottom_picker/bottom_picker.dart';

class OnBoarding9 extends ConsumerStatefulWidget {
  const OnBoarding9({
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
  ConsumerState<OnBoarding9> createState() => _OnBoarding9State();
}

class _OnBoarding9State extends ConsumerState<OnBoarding9> {
  List<String> choiceList=[];
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  List<bool> isSelected = [];
  List<bool> isChecked = [];
  bool _isHandlingTap = false;
  int manyCount = 3;
  int manyMax = 10;
  DateTime startTime = DateTime(2025,1,1,8,0,0,0,0); // 8h par défaut
  DateTime endTime = DateTime(2025,1,1,18,0,0,0,0); // 18h par défaut
  List<bool> daySelected = List.filled(7, true); // Tous les jours par défaut

  @override
  void initState() {
    super.initState();
    choiceList = widget.choiceList;
    isSelected = List.filled(choiceList.length, false);
    isChecked  = List.filled(choiceList.length, false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final locale = Localizations.localeOf(context);
      final startsOnSunday = locale.countryCode == 'US';
      ref.read(startsOnSundayProvider.notifier).state = startsOnSunday;
      final localizedDays = ref.read(daySelectedLocalizedProvider);
      setState(() => daySelected = localizedDays);
    });
    _loadDates();
  }

  @override
  void didUpdateWidget(covariant OnBoarding9 oldWidget) {
    super.didUpdateWidget(oldWidget);
    choiceList = widget.choiceList;
    isSelected = List.filled(choiceList.length, false);
    isChecked  = List.filled(choiceList.length, false);
  }

  void _loadDates() {
    final habits = ref.read(habitsStateProvider);
    final now = DateTime.now();

    if (!mounted) return;
    setState(() {
        manyCount = habits.dayCount > 0 ? habits.dayCount : 3;
        startTime = DateTime(now.year, now.month, now.day, habits.startHour, habits.startMinute);
        endTime = DateTime(now.year, now.month, now.day, habits.endHour, habits.endMinute);
    });
  }

  /// UI -> Mo..Su
  List<bool> _toMoSu(List<bool> localized, {required bool startsOnSunday}) {
    if (!startsOnSunday) return localized;     // déjà Mo..Su
    // Su..Sa -> Mo..Su
    return [
      localized[1], // Mo
      localized[2], // Tu
      localized[3], // We
      localized[4], // Th
      localized[5], // Fr
      localized[6], // Sa
      localized[0], // Su
    ];
  }

  Future<void> handleTap() async {
    if (_isHandlingTap) return;
    _isHandlingTap = true;

    try {
    final finalManyCount = manyCount;
    final finalStartHour = startTime.hour;
    final finalStartMinute = startTime.minute;
    final finalEndHour = endTime.hour;
    final finalEndMinute = endTime.minute;
    final finalDaySelected = daySelected;
    
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("How many : $finalManyCount "
          "\nStart : $finalStartHour:$finalStartMinute "
          "\nEnd : $finalEndHour:$finalEndMinute");
      debugPrint("L to S : ${finalDaySelected.map((e)=>e?'T':'F').join(',')}");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }

    // Local → display order -> convert to Mo..Su for storage
    final locale = Localizations.localeOf(context);
    final startsOnSunday = locale.countryCode == 'US';
    final dayMoSu = _toMoSu(finalDaySelected, startsOnSunday: startsOnSunday);

    await ref.read(habitsStateProvider.notifier).setHabits(
      dayCount: finalManyCount,
      startHour: finalStartHour,
      startMinute: finalStartMinute,
      endHour: finalEndHour,
      endMinute: finalEndMinute,
      daySelectedMoToSu: dayMoSu,
    );

    // Request notification permission on this screen (not at startup).
    // Continue the flow even if the user refuses: they can enable it later in Settings.
    final notifGranted = await NotificationService.instance.requestUserNotificationPermissions();
    MixpanelService.instance.track(
      '[Onboarding] Notification permission',
      {'granted': notifGranted},
    );

    widget.forward?.call();
    } finally {
      _isHandlingTap = false;
    }
  }


  void handleDate(DateTime dt, String when) {
    // ton traitement ici
    debugPrint("Choisi : $dt , $when");
    switch(when){
      case "Start" : startTime = dt;
      case "End" : endTime = dt;
    }
    setState(() {
    });
  }

  void openTimePicker(BuildContext context, String when) {
    DateTime chosenTime = DateTime.now();
    switch(when){
      case "Start" : chosenTime = startTime;
      case "End" : chosenTime = endTime;
    }
    BottomPicker.time(
      initialTime: Time(hours: chosenTime.hour, minutes: chosenTime.minute),
      minuteInterval: 1,
        use24hFormat: false,
      backgroundColor: appTheme.secButton,
      buttonSingleColor: appTheme.background,
      pickerThemeData: CupertinoTextThemeData(
        dateTimePickerTextStyle: TextStyle(
          fontSize: 24*xFact,
          fontFamily: 'InterTight',
          fontWeight: FontWeight.w600,
          color: appTheme.background,
        ),
      ),
      headerBuilder: (context) {
        return Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: appTheme.background,
              size: 32*xFact, // 👈 taille de la croix
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        );
      },

      onSubmit: (value) {
        // For BottomPicker.time, value is a Time (hours/minutes)
        final selected = value as DateTime;
        handleDate(selected,when);
      },
      // (optional) custom OK button
      buttonContent: Center(child: Text(
          'Ok',
        style: TextStyle(
          color: appTheme.onBackground
        ),
      )),
    ).show(context);
  }

  Widget rowSelect(String title, String content, bool isBorder, String when){
    return Padding(
      padding: EdgeInsetsGeometry.only(left: 40*xFact,right: 40*xFact),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: appTheme.onTertButton,
                  fontFamily: 'InterTight',
                  fontWeight: FontWeight.w400,
                  fontSize: 20*xFact,
                ),
              ),
              Container(
                  width: 150*xFact,
                  decoration: BoxDecoration(
                      border: Border.all(
                        width: 1*xFact,
                        color: !isBorder ? Colors.transparent : appTheme.containerTertButton,
                      ),
                      borderRadius: BorderRadius.circular(20*xFact)
                  ),
                  child: isBorder ? GestureDetector(
                    onTap: () {
                      openTimePicker(context,when);
                    },
                    child: Center(
                      child: Text(
                        content,
                        style: TextStyle(
                          color: appTheme.onTertButton,
                          fontFamily: 'InterTight',
                          fontWeight: FontWeight.w400,
                          fontSize: 20*xFact,
                        ),
                      ),
                    ),
                  ) : Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              manyCount--;
                              if(manyCount <= 0) manyCount = 0;
                            });
                          },
                          child: Container(
                            width : 30*xFact,
                            height: 30*xFact,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: appTheme.containerTertButton)
                            ),
                            child: Center(
                              child: Icon(
                                  Icons.remove,
                                  color: appTheme.onTertButton,
                                  size: 20*xFact,
                              )
                            ),
                          ),
                        ),
                        Text(
                          content,
                          style: TextStyle(
                            color: appTheme.onTertButton,
                            fontFamily: 'InterTight',
                            fontWeight: FontWeight.w400,
                            fontSize: 20*xFact,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              manyCount++;
                              if(manyCount >= manyMax) manyCount = manyMax;
                            });
                          },
                          child: Container(
                            width : 30*xFact,
                            height: 30*xFact,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: appTheme.containerTertButton)
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add,
                                color: appTheme.onTertButton,
                                size: 20*xFact,
                              )
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(
            height: 15*yFact,
          )
        ],
      ),
    );
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
        child: Builder(
          builder: (context) {
            // Enable scroll only if text scale > 1.2
            final textScale = MediaQuery.of(context).textScaler.scale(1.0);
            final shouldEnableScroll = textScale > 1.2;
            
            final content = Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              Column(
                children: [
                  SizedBox(height: 30*yFact,),
                  SizedBox(
                    height: 120*yFact,
                    child: Image.asset(
                      'assets/images/flamy/flamy_mail.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(
                    height: 15*yFact,
                  ),
                  // Texte principal
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40*xFact),
                    child: Text(
                      translate(widget.title, lang),
                      style: TextStyle(
                        fontFamily: "YesevaOne",
                        fontSize: 24*xFact,
                        color: Color(0xFFfff9ee),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    height: 20*yFact,
                  ),
                  // Notification preview
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30*xFact),
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: 70*yFact, // Hauteur minimale pour garantir la visibilité
                      ),
                      padding: EdgeInsets.all(8*xFact),
                      decoration: BoxDecoration(
                        color: Color(0xFF504b41).withAlpha(105),
                        borderRadius: BorderRadius.circular(12*xFact),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Notification content - vertically centered
                          Expanded(
                            child: Center(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 45*xFact,
                                    height: 45*xFact,
                                    decoration: BoxDecoration(
                                      color: appTheme.background,
                                      borderRadius: BorderRadius.all(Radius.circular(3)),
                                    ),
                                    child: Image.asset(
                                      'assets/images/flamy/flamy_glasses.png',
                                      fit: BoxFit.fitHeight,
                                    ),
                                  ),
                                  SizedBox(width: 12*xFact),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          translate("Business Mindset", lang),
                                          style: TextStyle(
                                            fontFamily: "InterTight",
                                            fontSize: 16*xFact,
                                            fontWeight: FontWeight.w600,
                                            color: appTheme.onBackground,
                                          ),
                                        ),
                                        SizedBox(height: 4*yFact),
                                        Text(
                                          translate("onboarding9_notification_text", lang),
                                          style: TextStyle(
                                            fontFamily: "InterTight",
                                            fontSize: 12*xFact,
                                            color: appTheme.onBackground,
                                          ),
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8*xFact),
                          // "now" on the right, top-aligned
                          Text(
                            translate("now", lang),
                            style: TextStyle(
                              fontFamily: "InterTight",
                              fontSize: 12*xFact,
                              color: Color(0xFFb4ac9c),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          
                  SizedBox(
                    height: 20*yFact,
                  ),
                  rowSelect(translate("Howmany", lang), "x$manyCount",false,""),
                  Builder(
                      builder: (context) {
                        int hour = startTime.hour;
                        int minute = startTime.minute;
                        String minuteString = "";
                        if (minute <= 9) {
                          minuteString = "0$minute";
                        }else{
                          minuteString = "$minute";
                        }
                        final isPM = hour >= 12;
                        final ampm = isPM ? "PM" : "AM";
                        if(ampm == "PM") hour = hour - 12;
                        return rowSelect(translate("Startat", lang), "$hour : $minuteString $ampm",true,"Start");
                      }
                  ),
                  Builder(
                      builder: (context) {
                        int hour = endTime.hour;
                        int minute = endTime.minute;
                        String minuteString = "";
                        if (minute <= 9) {
                          minuteString = "0$minute";
                        }else{
                          minuteString = "$minute";
                        }
                        final isPM = hour >= 12;
                        final ampm = isPM ? "PM" : "AM";
                        if(ampm == "PM") hour = hour - 12;
                        return rowSelect(translate("Endat", lang), "$hour : $minuteString $ampm",true,"End");
                      }
                  ),
                  SizedBox(
                    height: 15*yFact,
                  ),
                  Padding(
                    padding: EdgeInsetsGeometry.only(left: 40*xFact,right: 40*xFact),
                    child: Align(
                      alignment: AlignmentGeometry.centerLeft,
                      child: Text(
                        "Repeat",
                        style: TextStyle(
                          color: appTheme.onTertButton,
                          fontFamily: 'InterTight',
                          fontWeight: FontWeight.w400,
                          fontSize: 20*xFact,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
          
                  WeekdaySelector(
                    enabled: true,
                    onChanged: (List<bool> value) {
                      daySelected = value;
                    },
                  ),
                ],
              ),
                SizedBox(
                  height: 50*yFact,
                ),
              Padding(
                padding: EdgeInsetsGeometry.only(right: 20*xFact,left: 20*xFact,bottom: 30*yFact),
                child: Align(
                  alignment: AlignmentGeometry.bottomCenter,
                  child: SecondaryButton(
                    text: translate(widget.buttonText!,lang),
                    onTap: () => handleTap(),
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
