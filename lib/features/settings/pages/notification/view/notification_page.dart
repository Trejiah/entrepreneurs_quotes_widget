import 'package:bottom_picker/bottom_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/widgets/common/weekday_selector.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/services/save_cloud.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:businessmindset/services/notification_service.dart';
import 'package:businessmindset/services/mixpanel_service.dart';

class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  DateTime startTime = DateTime(2025, 1, 1, 9, 0, 0, 0, 0);
  DateTime endTime = DateTime(2025, 1, 1, 17, 0, 0, 0, 0);
  List<bool> daySelected = List.filled(7, false);
  int manyCount = 0;
  bool manyMaxDis = false;
  int manyMax = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final locale = Localizations.localeOf(context);
      final startsOnSunday = locale.countryCode == 'US';
      ref.read(startsOnSundayProvider.notifier).state = startsOnSunday;
      _loadDates();
    });
  }

  void _loadDates() {
    final habits = ref.read(habitsStateProvider);
    final now = DateTime.now();
    final localizedDays = ref.read(daySelectedLocalizedProvider);

    if (!mounted) return;
    setState(() {
      manyCount = habits.dayCount > 0 ? habits.dayCount : 3;
      startTime =
          DateTime(now.year, now.month, now.day, habits.startHour, habits.startMinute);
      endTime = DateTime(now.year, now.month, now.day, habits.endHour, habits.endMinute);
      daySelected = localizedDays;
    });

    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📋 [NotificationPage] Loading");
      debugPrint("   - manyCount: $manyCount");
      debugPrint("   - startHour: ${startTime.hour}:${startTime.minute}");
      debugPrint("   - endHour: ${endTime.hour}:${endTime.minute}");
      debugPrint("   - daySelected: $daySelected");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }

  List<bool> _toMoSu(List<bool> localized, {required bool startsOnSunday}) {
    if (!startsOnSunday) return localized;
    return [
      localized[1],
      localized[2],
      localized[3],
      localized[4],
      localized[5],
      localized[6],
      localized[0],
    ];
  }

  bool _isTimeValid() {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes > startMinutes;
  }

  Future<void> handleTap(BuildContext ctx) async {
    final finalManyCount = manyCount;
    final finalStartHour = startTime.hour;
    final finalStartMinute = startTime.minute;
    final finalEndHour = endTime.hour;
    final finalEndMinute = endTime.minute;
    final finalDaySelected = daySelected;

    final locale = Localizations.localeOf(context);
    final startsOnSunday = locale.countryCode == 'US';
    final dayMoSu = _toMoSu(finalDaySelected, startsOnSunday: startsOnSunday);

    final lang = ref.read(languageProvider);
    await ref.read(habitsStateProvider.notifier).setHabits(
          dayCount: finalManyCount,
          startHour: finalStartHour,
          startMinute: finalStartMinute,
          endHour: finalEndHour,
          endMinute: finalEndMinute,
          daySelectedMoToSu: dayMoSu,
        );

    saveOneToCloud("notif", "manyCount", finalManyCount);
    saveOneToCloud("notif", "startHour", finalStartHour);
    saveOneToCloud("notif", "startMinute", finalStartMinute);
    saveOneToCloud("notif", "endHour", finalEndHour);
    saveOneToCloud("notif", "endMinute", finalEndMinute);
    saveOneToCloud("notif", "daySelected", dayMoSu.map((e) => e.toString()).toList());

    final prefs = ref.read(sharedPrefsProvider);
    final habits = ref.read(habitsStateProvider);
    await NotificationService.instance.scheduleFromHabits(
      prefs: prefs,
      habits: habits,
      languageCode: lang,
      triggeredAutomatically: false,
      ignoreForcedQuotes: true,
    );

    if (kDebugMode) {
      await NotificationService.instance.debugPendingNotifications();
    }

    MixpanelService.instance.track('[Notif] Save', {'source': 'notification_page'});
    if (!ctx.mounted) return;
    Navigator.of(ctx).pop();
  }

  void handleDate(DateTime dt, String when) {
    switch (when) {
      case "Start":
        startTime = dt;
      case "End":
        endTime = dt;
    }
    setState(() {});
  }

  void openTimePicker(BuildContext context, String when) {
    DateTime chosenTime = DateTime.now();
    switch (when) {
      case "Start":
        chosenTime = startTime;
      case "End":
        chosenTime = endTime;
    }
    int displayHour = chosenTime.hour;
    if (displayHour == 0) {
      displayHour = 12;
    } else if (displayHour > 12) {
      displayHour = displayHour - 12;
    }

    BottomPicker.time(
      initialTime: Time(hours: displayHour, minutes: chosenTime.minute),
      minuteInterval: 1,
      use24hFormat: false,
      backgroundColor: appTheme.secButton,
      buttonSingleColor: appTheme.background,
      height: 400 * yFact,
      itemExtent: 30 * xFact,
      pickerThemeData: CupertinoTextThemeData(
        dateTimePickerTextStyle: TextStyle(
          fontSize: 24 * xFact,
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
              size: 32 * xFact,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        );
      },
      onSubmit: (value) {
        final selected = value as DateTime;
        handleDate(selected, when);
      },
      buttonWidth: 100 * xFact,
      buttonPadding: 0,
      buttonContent: SizedBox(
        height: 45 * yFact,
        child: Center(
          child: Text(
            'Ok',
            style: TextStyle(
              color: appTheme.onBackground,
              fontSize: 18 * xFact,
              fontWeight: FontWeight.w600,
              fontFamily: 'InterTight',
            ),
          ),
        ),
      ),
    ).show(context);
  }

  Widget rowSelect(String title, String content, bool isBorder, String when) {
    return Padding(
      padding: EdgeInsetsGeometry.only(left: 40 * xFact, right: 40 * xFact),
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
                  fontSize: 20 * xFact,
                ),
              ),
              Container(
                width: 150 * xFact,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 1 * xFact,
                    color: !isBorder ? Colors.transparent : appTheme.containerTertButton,
                  ),
                  borderRadius: BorderRadius.circular(20 * xFact),
                ),
                child: isBorder
                    ? GestureDetector(
                        onTap: () {
                          openTimePicker(context, when);
                        },
                        child: Center(
                          child: Text(
                            content,
                            style: TextStyle(
                              color: appTheme.onTertButton,
                              fontFamily: 'InterTight',
                              fontWeight: FontWeight.w400,
                              fontSize: 20 * xFact,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  manyCount--;
                                  if (manyCount < 0) manyCount = 0;
                                });
                              },
                              child: Container(
                                width: 30 * xFact,
                                height: 30 * xFact,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: appTheme.containerTertButton),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.remove,
                                    color: appTheme.onTertButton,
                                    size: 20 * xFact,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              content,
                              style: TextStyle(
                                color: appTheme.onTertButton,
                                fontFamily: 'InterTight',
                                fontWeight: FontWeight.w400,
                                fontSize: 20 * xFact,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  manyCount++;
                                  if (manyCount >= manyMax) manyCount = manyMax;
                                });
                              },
                              child: Container(
                                width: 30 * xFact,
                                height: 30 * xFact,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: appTheme.containerTertButton),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.add,
                                    color: appTheme.onTertButton,
                                    size: 20 * xFact,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          SizedBox(
            height: 15 * yFact,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: appTheme.background),
        child: SafeArea(
          top: true,
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10 * xFact),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 10 * xFact,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back_ios,
                            color: appTheme.onBackground, size: 30 * xFact),
                      ),
                      SizedBox(width: 5 * xFact),
                      Text(
                        translate("Notifications", lang),
                        style: TextStyle(
                          fontFamily: "YesevaOne",
                          color: appTheme.onBackground,
                          fontSize: 35 * xFact,
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 40 * yFact,
                        child: manyMaxDis
                            ? Text(
                                translate("notifications_max_freemium", lang),
                                style: TextStyle(
                                  color: appTheme.onPrimButtonGold,
                                  fontFamily: 'InterTight',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 20 * xFact,
                                ),
                                textAlign: TextAlign.center,
                              )
                            : SizedBox(),
                      ),
                      rowSelect(translate("Howmany", lang), "x$manyCount", false, ""),
                      Builder(builder: (context) {
                        int hour = startTime.hour;
                        int minute = startTime.minute;
                        String minuteString = "";
                        if (minute <= 9) {
                          minuteString = "0$minute";
                        } else {
                          minuteString = "$minute";
                        }
                        final isPM = hour >= 12;
                        final ampm = isPM ? "PM" : "AM";
                        if (hour == 0) {
                          hour = 12;
                        } else if (hour > 12) {
                          hour = hour - 12;
                        }
                        return rowSelect(
                          translate("Startat", lang),
                          "$hour : $minuteString $ampm",
                          true,
                          "Start",
                        );
                      }),
                      Builder(builder: (context) {
                        int hour = endTime.hour;
                        int minute = endTime.minute;
                        String minuteString = "";
                        if (minute <= 9) {
                          minuteString = "0$minute";
                        } else {
                          minuteString = "$minute";
                        }
                        final isPM = hour >= 12;
                        final ampm = isPM ? "PM" : "AM";
                        if (hour == 0) {
                          hour = 12;
                        } else if (hour > 12) {
                          hour = hour - 12;
                        }
                        return rowSelect(
                          translate("Endat", lang),
                          "$hour : $minuteString $ampm",
                          true,
                          "End",
                        );
                      }),
                      Padding(
                        padding: EdgeInsetsGeometry.only(left: 40 * xFact, right: 40 * xFact),
                        child: Align(
                          alignment: AlignmentGeometry.centerLeft,
                          child: Text(
                            "Repeat",
                            style: TextStyle(
                              color: appTheme.onTertButton,
                              fontFamily: 'InterTight',
                              fontWeight: FontWeight.w400,
                              fontSize: 20 * xFact,
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
                ),
                Padding(
                  padding: EdgeInsetsGeometry.only(
                      right: 20 * xFact, left: 20 * xFact, bottom: 30 * yFact),
                  child: Align(
                    alignment: AlignmentGeometry.bottomCenter,
                    child: Opacity(
                      opacity: _isTimeValid() ? 1.0 : 0.5,
                      child: SecondaryButton(
                        text: translate("save", lang),
                        onTap: _isTimeValid() ? () => handleTap(context) : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

