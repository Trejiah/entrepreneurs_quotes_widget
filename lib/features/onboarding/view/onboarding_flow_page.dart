import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/home/view/home_page.dart';
import 'package:businessmindset/features/onboarding/auth/onboarding_auth_view_model.dart';
import 'package:businessmindset/features/onboarding/data/onboarding_draft_repository_provider.dart';
import 'package:businessmindset/features/onboarding/flow/onboarding_flow_provider.dart';
import 'package:businessmindset/features/onboarding/flow/onboarding_step_registry.dart';
import 'package:businessmindset/features/onboarding/model/onboarding_outcomes.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding0.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding1_3.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding10.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding11.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding13.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding14.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding19.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding20.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding25.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding26.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding27.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding28.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding29.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding30.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding31.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding32.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding33b.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding37.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding38.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding4.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding5_6.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding7_10.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding9.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/services/onboarding_page_time_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _OnboardingStep {
  final Widget Function() builder;
  final VoidCallback? onBack;

  const _OnboardingStep({
    required this.builder,
    required this.onBack,
  });
}

class OnboardingFlowPage extends ConsumerStatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  ConsumerState<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends ConsumerState<OnboardingFlowPage>
    with WidgetsBindingObserver {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  VoidCallback? _systemBackHandler;

  Future<void> _handleSystemBack() async {
    final handler = _systemBackHandler;
    if (handler == null) {
      return;
    }
    handler();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(onboardingFlowProvider.notifier).init();
      _updateSystemUI();
    });
  }

  void _updateSystemUI() {
    final currentStep = ref.read(onboardingFlowProvider).currentStep;
    if (currentStep == 10) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // On iOS/Android, detached is almost never called on force-kill (process killed first).
    // Send the Abandon event as soon as the app pauses to capture real exits.
    if (kDebugMode) {
      debugPrint('[Onboarding] 🔔 Lifecycle: $state');
    }
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _trackOnboardingAbandon();
    }
  }

  /// Track onboarding abandon (app backgrounded or closed without completing).
  Future<void> _trackOnboardingAbandon() async {
    final currentBodyInt = await ref.read(onboardingDraftRepositoryProvider).readCurrentStep();
    final openedAt = OnboardingPageTimeService.openedAt;
    final now = DateTime.now();
    final secondsOnPage = openedAt == null ? 0 : now.difference(openedAt).inSeconds;
    MixpanelService.instance.track(
      '[Onboarding] Abandon',
      {
        'page_number': currentBodyInt,
        'completion_percentage': ((currentBodyInt / OnboardingStepRegistry.maxStep) * 100)
            .toStringAsFixed(1),
        'Temps passé sur la page :': secondsOnPage,
      },
    );
    await MixpanelService.instance.flush();
    if (kDebugMode) {
      debugPrint(
          '[Onboarding] 📊 Abandon detected at page $currentBodyInt/${OnboardingStepRegistry.maxStep}');
    }
  }

  _nextPage(int howmuch) async {
    final flow = ref.read(onboardingFlowProvider);
    final flowVm = ref.read(onboardingFlowProvider.notifier);
    final nextStep = flow.currentStep + howmuch;
    if (nextStep >= flow.maxStep + 1) {
      await flowVm.setStep(flow.maxStep);
      final habits = ref.read(habitsStateProvider);
      final lang = ref.read(languageProvider);
      final premium = ref.read(premiumProvider);
      final summary = await ref.read(onboardingDraftRepositoryProvider).readCompletionSummary();
      
      // Preferences summary before navigating to HomePage
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("📋 [Onboarding] User preferences summary");
        debugPrint("   - name: ${summary['name']}");
        debugPrint("   - gender: ${summary['gender']}");
        debugPrint("   - age: ${summary['age']}");
        debugPrint("   - situation: ${summary['situation']}");
        debugPrint("   - mindset: ${summary['mindset']}");
        debugPrint("   - focus: ${summary['focus']}");
        debugPrint("   - challenge: ${summary['challenge']}");
        debugPrint("   - topics: ${summary['topics']}");
        debugPrint("   - selectedTopics: ${summary['selectedTopics']}");
        debugPrint("   - language: $lang");
        debugPrint("   - themeIndex: ${summary['themeIndex']}");
        debugPrint("   - isCustomTheme: ${summary['isCustomTheme']}");
        debugPrint("   - habits:");
        debugPrint("     - startHour: ${habits.startHour}");
        debugPrint("     - startMinute: ${habits.startMinute}");
        debugPrint("     - endHour: ${habits.endHour}");
        debugPrint("     - endMinute: ${habits.endMinute}");
        debugPrint("     - manyCount: ${habits.dayCount}");
        debugPrint("     - daySelected: ${habits.daySelectedMoToSu}");
        debugPrint("   - premium: $premium");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
      
      await flowVm.complete();
      // Track Mixpanel: onboarding finished, regardless of subscription
      MixpanelService.instance.track('[Onboarding] Completed', {
        'has_subscription': premium,
      });
      // Force flush before navigation to avoid losing the event
      await MixpanelService.instance.flush();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
      );
    } else {
      await flowVm.next(howmuch);
    }
    _updateSystemUI();
  }

  _previousPage(){
    ref.read(onboardingFlowProvider.notifier).previous();
    _updateSystemUI();
  }

  login(BuildContext ctx) async {
    final outcome = await OnboardingAuthViewModel(ref).loginAndLoadCloud();
    if (!ctx.mounted || outcome != OnboardingAuthOutcome.success) {
      return;
    }
    _nextPage(1);
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(onboardingFlowProvider);
    final lang = ref.watch(languageProvider);
    if (!flow.isReady) {
      return const Scaffold(body: SizedBox.expand());
    }
    final steps = _buildSteps(context, lang);
    assert(
      steps.length == OnboardingStepRegistry.stepCount,
      'Inconsistent onboarding page count (expected: ${OnboardingStepRegistry.stepCount}, got: ${steps.length})',
    );
    final index = flow.currentStep.clamp(0, steps.length - 1);
    final currentStep = steps[index];
    _systemBackHandler = currentStep.onBack;

    final allowNavigatorPop = currentStep.onBack == null;
    return PopScope(
      canPop: allowNavigatorPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await _handleSystemBack();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: currentStep.builder(),
      ),
    );
  }

  List<_OnboardingStep> _buildSteps(BuildContext context, String lang) {
    return [
      _OnboardingStep(
        builder: () => OnBoarding0(
          forward: () {
            _nextPage(1);
          },
        ),
        onBack: null,
      ), // 0
      _OnboardingStep(
        builder: () => OnBoarding13(
          forward: () {
            _nextPage(1);
          },
        ),
        onBack: _previousPage,
      ), // 1
      _OnboardingStep(
        builder: () => OnBoarding4(
          forward: () {
            _nextPage(1);
          },
        ),
        onBack: _previousPage,
      ), // 2
      _OnboardingStep(
        builder: () => OnBoarding56(
          forward: () {
            _nextPage(1);
          },
        ),
        onBack: _previousPage,
      ), // 3
      _OnboardingStep(
        builder: () => OnBoarding710(
          forward: () {
            _nextPage(1);
          },
        ),
        onBack: _previousPage,
      ), // 4
      _OnboardingStep(
        builder: () => OnBoarding13bis(
          forward: () {
            _nextPage(1);
          },
        ),
        onBack: _previousPage,
      ), // 5
      _OnboardingStep(
        builder: () => OnBoarding14(
          pageStyle: "choices",
          backIcon: false,
          backward: _previousPage,
          forward: () {
            _nextPage(1);
          },
          variable: "age",
          title: translate("onboardingtitle5", lang),
          subTitle: translate("onboardingsubtitle5", lang),
          choiceList: const [
            "Under",
            "18",
            "25",
            "35",
            "45",
            "55",
          ],
          progress: 1/9,
        ),
        onBack: _previousPage,
      ), // 6
      _OnboardingStep(
        builder: () => OnBoarding14(
          pageStyle: "choices",
          backIcon: true,
          backward: _previousPage,
          forward: () {
            _nextPage(1);
          },
          variable: "gender",
          title: translate("onboardingtitle4", lang).replaceAll("%NAME%", ref.watch(userNameStateProvider)),
          subTitle: translate("onboardingsubtitle5", lang).replaceAll("%NAME%", ref.watch(userNameStateProvider)),
          choiceList: const [
            "Female",
            "Male",
            "Other",
            "nottosay",
          ],
          progress: 2/9,
        ),
        onBack: _previousPage,
      ), // 7
      _OnboardingStep(
        builder: () => OnBoarding14(
          pageStyle: "choices",
          backIcon: true,
          backward: _previousPage,
          forward: () {
            _nextPage(1);
          },
          variable: "situation",
          title: translate("onboardingtitle6", lang).replaceAll("%NAME%", ref.watch(userNameStateProvider)),
          subTitle: translate("onboardingsubtitle6", lang).replaceAll("%NAME%", ref.watch(userNameStateProvider)),
          choiceList: const [
            "Employee",
            "Entrepreneur",
            "Leader",
            "Looking2",
            "Looking",
            "Student",
            "nottosay",
          ],
          progress: 3/9,
        ),
        onBack: _previousPage,
      ), // 8
      _OnboardingStep(
        builder: () => OnBoarding10(
          backIcon: true,
          skipLink: false,
          title: translate("onboardingtitle10", lang),
          subTitle: translate("onboardingsubtitle10", lang),
          buttonText: translate("continue", lang),
          forward: () {
            _nextPage(1);
          },
          backward: _previousPage,
          variable: "theme",
        ),
        onBack: _previousPage,
      ), // 9
      _OnboardingStep(
        builder: () => OnBoarding11(
          backIcon: true,
          skipLink: false,
          backward: _previousPage,
          forward: () {
            _nextPage(1);
          },
          title: translate("onboardingQuote", lang).replaceAll("%NAME%", ref.watch(userNameStateProvider)),
          buttonText: "continue",
        ),
        onBack: _previousPage,
      ), // 10
      _OnboardingStep(
        builder: () => OnBoarding19(
          forward: () {
            _nextPage(1);
          },
        ),
        onBack: _previousPage,
      ), //11
      _OnboardingStep(
        builder: () => OnBoarding14(
          pageStyle: "choices",
          toCheck: true,
          backIcon: true,
          backward: _previousPage,
          forward: () {
            _nextPage(1);
          },
          variable: "focus",
          title: translate("onboardingtitle20", lang).replaceAll("%NAME%", ref.watch(userNameStateProvider)),
          subTitle: translate("onboardingsubtitle20", lang).replaceAll("%NAME%", ref.watch(userNameStateProvider)),
          choiceList: const [
            "startingbus",
            "saclingrev",
            "improvprod",
            "finfree",
            "betlead",
            "preprol",
          ],
          progress: 4/9,
        ),
        onBack: _previousPage,
      ), // 12
      _OnboardingStep(
        builder: () => OnBoarding14(
          pageStyle: "choices",
          toCheck: true,
          backIcon: true,
          backward: _previousPage,
          forward: () {
            _nextPage(1);
          },
          variable: "challenge",
          title: translate("onboardingtitle15", lang).replaceAll("%NAME%", ref.watch(userNameStateProvider)),
          subTitle: translate("onboardingsubtitle15", lang).replaceAll("%NAME%", ref.watch(userNameStateProvider)),
          choiceList: const [
            "staycons",
            "presdeal",
            "mantim",
            "keepfoc",
            "doubt",
            "motivd",
          ],
          progress: 5/9,
        ),
        onBack: _previousPage,
      ), // 13
      _OnboardingStep(
        builder: () => OnBoarding20(

          forward: () {
            _nextPage(1);
          },
        ),
        onBack: _previousPage,
      ), //14
      _OnboardingStep(
        builder: () => OnBoarding9(
          backIcon: false,
          skipLink: false,
          backward: _previousPage,
          forward: () {
            _nextPage(1);
          },
          variable: "habits",
          title: translate("onboardingtitle9", lang),
          subTitle: translate("onboardingsubtitle9", lang),
          choiceList: const [],
          buttonText: "save",
        ),
        onBack: _previousPage,
      ), // 15
      _OnboardingStep(
        builder: () => OnBoarding14(
          pageStyle: "check2",
          toCheck: true,
          backIcon: true,
          backward: _previousPage,
          forward: () {
            _nextPage(1);
          },
          variable: "topics",
          title: translate("onboardingtitle17", lang).replaceAll("%NAME%", ref.watch(userNameStateProvider)),
          subTitle: translate("onboardingsubtitle17", lang).replaceAll("%NAME%", ref.watch(userNameStateProvider)),
          choiceList: const [
            "confmind",
            "focdic",
            "resilience",
            "vispurp",
            "entrepreneurship",
            "leadership",
            "salebranding",
            "growsucces",
            "wealthmoney",
            "womenemp",
            "businessic",
            "frombook",
          ],
          progress: 6/9,
        ),
        onBack: _previousPage,
      ), // 16
      _OnboardingStep(
        builder: () => OnBoarding25(
          forward: () {
            _nextPage(1);
          },
          backIcon: true,
          backward: _previousPage,
          title: translate("onboardingtitle25", lang).replaceAll("%NAME%", ref.watch(userNameStateProvider)),
          subTitle: translate("onboardingsubtitle25", lang).replaceAll("%NAME%", ref.watch(userNameStateProvider)),
          progress: 7/9,
        ),
        onBack: _previousPage,
      ),//17
      _OnboardingStep(
        builder: () => OnBoarding26(
          forward: () {
            _nextPage(1);
          },
          backIcon: true,
          backward: _previousPage,
          title: translate("onboardingtitle26", lang).replaceAll("%NAME%", ref.watch(userNameStateProvider)),
          subTitle: translate("onboardingsubtitle26", lang).replaceAll("%NAME%", ref.watch(userNameStateProvider)),
        ),
        onBack: _previousPage,
      ),//18
      _OnboardingStep(
        builder: () => OnBoarding27(
          backIcon: true,
          backward: _previousPage,
          forward: () {
            _nextPage(1);
          },
          title: translate("onboardingtitle16", lang),
          subTitle: translate("onboardingsubtitle16", lang),
          progress: 8/9,
        ),
        onBack: _previousPage,
      ), // 19
      _OnboardingStep(
        builder: () => OnBoarding28(
          backward: _previousPage,
          forward: () {
            _nextPage(1);
          },
          progress: 9/9, backIcon: true,
        ),
        onBack: _previousPage,
      ),//20
      _OnboardingStep(
        builder: () => OnBoarding29(
          forward: () {
            _nextPage(1);
          },
        ),
        onBack: _previousPage,
      ),//21
      _OnboardingStep(
        builder: () => OnBoarding30(
          forward: () {
            _nextPage(1);
          },
        ),
        onBack: _previousPage,
      ),//22
      _OnboardingStep(
        builder: () => OnBoarding31(
          forward: () {
            _nextPage(1);
          },
        ),
        onBack: _previousPage,
      ),//23
      _OnboardingStep(
        builder: () => OnBoarding32(
          forward: () {
            _nextPage(1);
          },
        ),
        onBack: _previousPage,
      ),//24
      _OnboardingStep(
        builder: () => OnBoarding33b(
          forward: (howmuch) {
            _nextPage(howmuch);
          },
        ),
        onBack: _previousPage,
      ),//25
      _OnboardingStep(
        builder: () => OnBoarding37(
          forward: (howmuch) {
            _nextPage(howmuch);
          },
        ),
        onBack: _previousPage,
      ),//26
      _OnboardingStep(
        builder: () => OnBoarding38(
          forward: (howmuch) {
            _nextPage(howmuch);
          },
        ),
        onBack: _previousPage,
      ),//27
      // 20ter: login / Firebase account creation screen before the end
      //_OnboardingStep(
      //         builder: () => OnBoardingListBase(
      //           pageStyle: "login",
      //           backIcon: false,
      //           skipLink: true,
      //           backward: () {}, // no back
      //           forward: () {
      //             _nextPage(1);
      //           },
      //           title: translate("onboardingtitle20ter", lang),
      //           subTitle: translate("onboardingsubtitle20ter", lang),
      //           choiceList: const [],
      //           buttonText: "Ok",
      //           secondAction: () => login(context),
      //         ),
      //         onBack: null,
      //       ), // 28





   //   _OnboardingStep(
      //         builder: () => OnBoardingListBase(
      //           pageStyle: "declare",
      //           backIcon: true,
      //           skipLink: false,
      //           backward: _previousPage,
      //           forward: () {
      //             _nextPage(1);
      //           },
      //           title: translate("onboardingtitle12", lang),
      //           subTitle: translate("onboardingsubtitle12", lang),
      //           choiceList: const [],
      //           buttonText: "ready",
      //         ),
      //         onBack: _previousPage,
      //       ), // 12
      //       _OnboardingStep(
      //         builder: () => OnBoardingListBase(
      //           pageStyle: "choices",
      //           backIcon: true,
      //           skipLink: true,
      //           backward: _previousPage,
      //           forward: () {
      //             _nextPage(1);
      //           },
      //           variable: "mindset",
      //           title: translate("onboardingtitle13", lang),
      //           subTitle: translate("onboardingsubtitle13", lang),
      //           choiceList: const [
      //             "focused",
      //             "motivated",
      //             "overwhelmed",
      //             "curious",
      //             "driven",
      //             "none"
      //           ],
      //         ),
      //         onBack: _previousPage,
      //       ), // 13
      //       _OnboardingStep(
      //         builder: () => OnBoardingCheck1Base(
      //           pageStyle: "check1",
      //           buttonText: translate("continue", lang),
      //           backIcon: true,
      //           skipLink: true,
      //           backward: _previousPage,
      //           forward: () {
      //             _nextPage(1);
      //           },
      //           variable: "mainfocus",
      //           title: translate("onboardingtitle14", lang),
      //           subTitle: translate("onboardingsubtitle14", lang),
      //           choiceList: const [
      //             "startingbus",
      //             "saclingrev",
      //             "improvprod",
      //             "finfree",
      //             "findbal",
      //             "betlead",
      //             "preprol",
      //             "devhab",
      //             "other2",
      //           ],
      //         ),
      //         onBack: _previousPage,
      //       ), // 14
      //       _OnboardingStep(
      //         builder: () => OnBoardingCheck1Base(
      //           pageStyle: "check1",
      //           buttonText: translate("continue", lang),
      //           backIcon: true,
      //           skipLink: true,
      //           backward: _previousPage,
      //           forward: () {
      //             _nextPage(1);
      //           },
      //           variable: "bigchall",
      //           title: translate("onboardingtitle15", lang),
      //           subTitle: translate("onboardingsubtitle15", lang),
      //           choiceList: const [
      //             "staycons",
      //             "presdeal",
      //             "mantim",
      //             "keepfoc",
      //             "doubt",
      //             "motivd",
      //             "other2",
      //           ],
      //         ),
      //         onBack: _previousPage,
      //       ), // 15
      //       _OnboardingStep(
      //         builder: () => OnBoardingInputBase(
      //           pageStyle: "input2",
      //           backIcon: true,
      //           skipLink: true,
      //           backward: _previousPage,
      //           forward: () {
      //             _nextPage(1);
      //           },
      //           variable: "goals",
      //           boxHeight: 230,
      //           title: translate("onboardingtitle16", lang),
      //           subTitle: translate("onboardingsubtitle16", lang),
      //           choiceList: const [],
      //           buttonText: "continue",
      //           inputMaxCarac: 250,
      //           inputStyle: "input2",
      //           hintText: "Iwantto",
      //         ),
      //         onBack: _previousPage,
      //       ), // 16
      //       _OnboardingStep(
      //         builder: () => OnBoardingCheck1Base(
      //           pageStyle: "check2",
      //           buttonText: translate("continue", lang),
      //           backIcon: true,
      //           skipLink: true,
      //           backward: _previousPage,
      //           forward: () {
      //             _nextPage(1);
      //           },
      //           variable: "topics",
      //           title: translate("onboardingtitle17", lang),
      //           subTitle: translate("onboardingsubtitle17", lang),
      //           choiceList: topicList,
      //         ),
      //         onBack: _previousPage,
      //       ), // 17
      //       _OnboardingStep(
      //         builder: () => OnBoarding18(
      //           backIcon: true,
      //           skipLink: false,
      //           backward: _previousPage,
      //           forward: () {
      //             _nextPage(1);
      //           },
      //           buttonText: translate("awesome", lang),
      //         ),
      //         onBack: _previousPage,
      //       ), // 18
      //       _OnboardingStep(
      //         builder: () => OnBoarding19old(
      //           backIcon: true,
      //           skipLink: false,
      //           backward: _previousPage,
      //           forward: () {
      //             _nextPage(1);
      //           },
      //           buttonText: translate("howitworks", lang),
      //         ),
      //         onBack: _previousPage,
      //       ), // 19
      //       _OnboardingStep(
      //         builder: () => Paywall(
      //           pageStyle: "declare",
      //           backIcon: true,
      //           skipLink: false,
      //           backward: _previousPage,
      //           forward1: () {
      //             _nextPage(1);
      //           },
      //           forward2: () {
      //             _nextPage(3);
      //           },
      //           title: translate("onboardingtitle3", lang),
      //           subTitle: translate("onboardingsubtitle3", lang),
      //           choiceList: const [],
      //           buttonText: "letsgo",
      //         ),
      //         onBack: _previousPage,
      //       ), // 20
      //       _OnboardingStep(
      //         builder: () => OnBoarding20bis(
      //           backIcon: true,
      //           skipLink: false,
      //           backward: _previousPage,
      //           forward: () {
      //             _nextPage(1);
      //           },
      //           title: translate("onboardingtitle20bis", lang),
      //           subTitle: translate("onboardingsubtitle20bis", lang),
      //           choiceList: const [],
      //           buttonText: "letsbegin",
      //         ),
      //         onBack: _previousPage,
      //       ), // 20bis
      //       _OnboardingStep(
      //         builder: () => OnBoardingListBase(
      //           pageStyle: "login",
      //           backIcon: false,
      //           skipLink: true,
      //           backward: () {},
      //           forward: () {
      //             _nextPage(1);
      //           },
      //           title: translate("onboardingtitle20ter", lang),
      //           subTitle: translate("onboardingsubtitle20ter", lang),
      //           choiceList: const [],
      //           buttonText: "Ok",
      //           secondAction: () => login(context),
      //         ),
      //         onBack: null,
      //       ), // 20ter
      //       _OnboardingStep(
      //         builder: () => OnBoarding21old(
      //           backIcon: true,
      //           skipLink: false,
      //           backward: _previousPage2,
      //           forward: () {
      //             _nextPage(1);
      //           },
      //           title: translate("onboardingtitle21", lang),
      //           subTitle: translate("onboardingsubtitle21", lang),
      //           buttonText: translate("addwidget", lang),
      //         ),
      //         onBack: _previousPage2,
      //       ), // 21
    ];
  }
}

