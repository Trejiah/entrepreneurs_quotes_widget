import 'dart:async';
import 'dart:io';

import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/app/my_app.dart';
import 'package:businessmindset/bootstrap/firebase_bootstrap.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart'
    show IsCustomThemeNotifier, ThemeNotifier, isCustomThemeProvider, premiumProvider, themeIndexProvider;
import 'package:businessmindset/services/mindset_points_service.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/services/notification_service.dart';
import 'package:businessmindset/services/revenuecat_service.dart';
import 'package:businessmindset/services/trial_duration_ab_service.dart';
import 'package:businessmindset/theme/app_theme.dart';
import 'package:businessmindset/theme/themedatas.dart';
import 'package:businessmindset/utils/image_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  bool _ready = false;
  final Stopwatch _bootWatch = Stopwatch();

  late SharedPreferences prefs;
  late HabitsNotifier habitsNotifier;
  final List<Map<String, dynamic>> themeList = [];

  late bool hasOnboard;
  late bool savedPremium;
  late int savedIndex;
  late bool savedIsCustomTheme;
  late String savedUserName;
  late String lang;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAsync();
    });
  }

  Future<void> _initAsync() async {
    try {
      _bootWatch
        ..reset()
        ..start();
      void bootLog(String message) {
        debugPrint('[BOOT ${_bootWatch.elapsedMilliseconds}ms] $message');
      }
      bootLog('initAsync:start');

      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      Size logical() => Size(
            view.physicalSize.width / view.devicePixelRatio,
            view.physicalSize.height / view.devicePixelRatio,
          );

      if (!ScreenScale.init(logicalSize: logical())) {
        bootLog('ScreenScale:first init failed, retrying');
        for (var i = 0; i < 10; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 16));
          if (ScreenScale.init(logicalSize: logical())) break;
        }
      }
      bootLog('ScreenScale:done');

      bootLog('Firebase:init:start');
      await initializeFirebaseWithRetry();
      bootLog('Firebase:init:done');

      appTheme = appThemes['default']!;

      bootLog('SharedPreferences:getInstance:start');
      prefs = await SharedPreferences.getInstance();
      bootLog('SharedPreferences:getInstance:done');

      bootLog('TrialAB:ensureAssigned:start');
      final trialAbDays = await TrialDurationAbService.ensureAssigned(prefs);
      bootLog('TrialAB:ensureAssigned:done days=$trialAbDays');

      hasOnboard = prefs.getBool("hasOnboard") ?? false;
      savedIndex =
          prefs.getInt("themeIndex") ?? prefs.getInt("theme") ?? 0;
      savedIsCustomTheme =
          prefs.getBool("isCustomTheme") ?? false;
      savedPremium = prefs.getBool("premiumState") ?? false;
      savedUserName = prefs.getString("userName") ?? prefs.getString("name") ?? "Nobody";

      lang = 'en';
      final storedLang = prefs.getString('language');
      if (storedLang != lang) {
        await prefs.setString('language', lang);
      }

      if (!kIsWeb) {
        final expirationTimestamp =
        prefs.getInt("premiumExpirationDate");
        if (expirationTimestamp != null) {
          final expirationDate =
          DateTime.fromMillisecondsSinceEpoch(expirationTimestamp);
          if (DateTime.now().isBefore(expirationDate)) {
            savedPremium = true;
          } else {
            savedPremium = false;
            await prefs.setBool("premiumState", false);
            await prefs.remove("premiumExpirationDate");
          }
        }

        try {
          final authUser = FirebaseAuth.instance.currentUser;
          final userId = authUser?.uid;
          bootLog('RevenueCat:ensureConfigured:start userId=${userId ?? "null"}');
          await RevenueCatService.instance.ensureConfigured(appUserId: userId);
          bootLog('RevenueCat:ensureConfigured:done');

          bootLog('RevenueCat:getCustomerInfo:start');
          final customerInfo = await RevenueCatService.instance.getCustomerInfo(forceRefresh: true);
          bootLog('RevenueCat:getCustomerInfo:done');
          final hasActiveEntitlement = RevenueCatService.instance.hasActiveEntitlement(customerInfo);
          final expirationDate = RevenueCatService.instance.getExpirationDate(customerInfo);

        final skipAutoSync = prefs.getBool("skipAutoRevenueCatSync") ?? false;

        if (skipAutoSync) {
        } else {
          if (hasActiveEntitlement) {
            savedPremium = true;
            await prefs.setBool("premiumState", true);
            if (expirationDate != null) {
              await prefs.setInt("premiumExpirationDate", expirationDate.millisecondsSinceEpoch);
            }

          } else {
            savedPremium = false;
            await prefs.setBool("premiumState", false);
            await prefs.remove("premiumExpirationDate");

          }
        }


        } catch (e, stackTrace) {
          bootLog('RevenueCat:error $e');
          debugPrint('[BOOT ${_bootWatch.elapsedMilliseconds}ms] RevenueCat:stack $stackTrace');
        }
      }

      bootLog('Habits:load:start');
      final loadedHabits = await loadHabitsStateFromPrefs(prefs);
      habitsNotifier = HabitsNotifier(prefs, loadedHabits);
      bootLog('Habits:load:done');

      bootLog('Themes:load:start');
      final loadedThemes = await loadThemeListFromPrefs();
      themeList
        ..clear()
        ..addAll(loadedThemes);
      bootLog('Themes:load:done count=${themeList.length}');

      if (savedIsCustomTheme && savedIndex < themeList.length) {
        bootLog('ThemeImage:preload:start index=$savedIndex');
        final currentTheme = themeList[savedIndex];
        final isImage = currentTheme["isImage"] == true;
        final imageName = currentTheme["imageName"] as String?;
        if (isImage && imageName != null && imageName.isNotEmpty) {
          final validPath = getValidImagePath(imageName);
          if (validPath != null && File(validPath).existsSync()) {
            final imageProvider = FileImage(File(validPath));
            final completer = Completer<void>();
            final stream = imageProvider.resolve(ImageConfiguration.empty);
            late ImageStreamListener listener;
            listener = ImageStreamListener(
              (info, sync) {
                if (!completer.isCompleted) completer.complete();
                stream.removeListener(listener);
              },
              onError: (e, s) {
                if (!completer.isCompleted) completer.complete();
                stream.removeListener(listener);
              },
            );
            stream.addListener(listener);
            await completer.future;
          }
        }
        bootLog('ThemeImage:preload:done');
      }

      bootLog('NotificationService:init:start');
      await NotificationService.instance.init();
      bootLog('NotificationService:init:done');

      bootLog('UI:setReady:start');
      setState(() => _ready = true);
      bootLog('UI:setReady:done');

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          bootLog('Deferred:Mixpanel:init:start');
          await MixpanelService.instance.init();
          bootLog('Deferred:Mixpanel:init:done');
        } catch (_) {}

        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser != null && hasOnboard) {

          MindsetPointsService.instance.disableSave();

          try {
            final uid = authUser.uid;
            final databaseRef = FirebaseDatabase.instance.ref('users/$uid');
            final snapshot = await databaseRef.get();

            if (snapshot.exists) {
            } else {
            }
          } catch (e) {

          } finally {
            MindsetPointsService.instance.enableSave();


          }
        }

        if (hasOnboard) {
          bootLog('Deferred:MindsetPoints:incrementOpenOnStartup:start');
          await MindsetPointsService.instance.incrementOpenOnStartup();
          bootLog('Deferred:MindsetPoints:incrementOpenOnStartup:done');
        }
      });
    } catch (e, s) {
      debugPrint('[BOOT ${_bootWatch.elapsedMilliseconds}ms] initAsync:catch $e');
      debugPrint('[BOOT ${_bootWatch.elapsedMilliseconds}ms] initAsync:stack $s');


      SharedPreferences? tempPrefs;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          debugPrint('[BOOT ${_bootWatch.elapsedMilliseconds}ms] Recovery:SharedPreferences attempt=$attempt:start');
          await Future.delayed(Duration(milliseconds: 200 * attempt));
          tempPrefs = await SharedPreferences.getInstance();
          debugPrint('[BOOT ${_bootWatch.elapsedMilliseconds}ms] Recovery:SharedPreferences attempt=$attempt:done');
          break;
        } catch (e) {
          debugPrint('[BOOT ${_bootWatch.elapsedMilliseconds}ms] Recovery:SharedPreferences attempt=$attempt:error $e');
        }
      }

      if (tempPrefs == null) {
        try {
          tempPrefs = await SharedPreferences.getInstance();
        } catch (_) {
        }
      }

      prefs = tempPrefs ?? await SharedPreferences.getInstance();

      debugPrint('[BOOT ${_bootWatch.elapsedMilliseconds}ms] Recovery:TrialAB:start');
      final trialAbDays = await TrialDurationAbService.ensureAssigned(prefs);
      debugPrint('[BOOT ${_bootWatch.elapsedMilliseconds}ms] Recovery:TrialAB:done days=$trialAbDays');

      hasOnboard = false;
      savedIndex = 0;
      savedIsCustomTheme = false;
      savedPremium = false;
      savedUserName = "Nobody";
      lang = 'en';
      habitsNotifier = HabitsNotifier(prefs, HabitsState.defaults());

      setState(() => _ready = true);
      debugPrint('[BOOT ${_bootWatch.elapsedMilliseconds}ms] Recovery:UI:setReady:done');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF1F1F1F),
        ),
      );
    }

    return ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        habitsStateProvider.overrideWith((_) => habitsNotifier),
        themeCustomListProvider.overrideWith((_) => themeList),
        languageProvider.overrideWith((_) => lang),
        premiumProvider.overrideWith((_) => savedPremium),
        userNameStateProvider.overrideWith((_) => savedUserName),
        themeIndexProvider
            .overrideWith((ref) => ThemeNotifier(ref, savedIndex)),
        isCustomThemeProvider.overrideWith(
              (ref) => IsCustomThemeNotifier(savedIsCustomTheme),
        ),
      ],
      child: MyApp(hasOnboard: hasOnboard),
    );
  }
}
