import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/settings/pages/retake_test_flow/view_model/retake_test_provider.dart';
import 'package:businessmindset/features/settings/pages/retake_test_flow/view_model/retake_test_view_model.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding29.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding30.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding31.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RetakeTestFlow extends ConsumerStatefulWidget {
  const RetakeTestFlow({super.key});

  @override
  ConsumerState<RetakeTestFlow> createState() => _RetakeTestFlowState();
}

class _RetakeTestFlowState extends ConsumerState<RetakeTestFlow> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  void _nextPage() {
    ref.read(retakeTestViewModelProvider.notifier).nextPage();
  }

  void _previousPage() {
    final action = ref.read(retakeTestViewModelProvider.notifier).previousPage();
    if (action == RetakeTestPreviousAction.shouldPopFalse) {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _saveAndReturn() async {
    await ref.read(retakeTestViewModelProvider.notifier).saveAndReturn();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _cancel() async {
    await ref.read(retakeTestViewModelProvider.notifier).cancelAndRestorePrefs();
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(retakeTestViewModelProvider.notifier).loadInitialValues());
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(retakeTestViewModelProvider);
    final vm = ref.read(retakeTestViewModelProvider.notifier);

    Widget currentWidget;

    switch (ui.currentPage) {
      case 0:
        // Page 1: What is your personal status (progress 1/6)
        currentWidget = _RetakeTestPage1(
          backward: _previousPage,
          forward: _nextPage,
          progress: 1 / 6,
          initialValue: ui.situation,
          onValueChanged: vm.setSituation,
        );
        break;

      case 1:
        // Page 2: What do you need to improve (progress 2/6)
        currentWidget = _RetakeTestPage2(
          backward: _previousPage,
          forward: _nextPage,
          progress: 2 / 6,
          initialValues: ui.improvement,
          onValuesChanged: vm.setImprovement,
        );
        break;

      case 2:
        // Page 3: What is your main focus (progress 3/6)
        currentWidget = _RetakeTestPage3(
          backward: _previousPage,
          forward: _nextPage,
          progress: 3 / 6,
          initialValues: ui.mainfocus,
          onValuesChanged: vm.setMainfocus,
        );
        break;

      case 3:
        // Page 4: What is your biggest challenge (progress 4/6)
        currentWidget = _RetakeTestPage4(
          backward: _previousPage,
          forward: _nextPage,
          progress: 4 / 6,
          initialValues: ui.bigchall,
          onValuesChanged: vm.setBigchall,
        );
        break;

      case 4:
        // Page 5: Which topics do you (progress 5/6)
        currentWidget = _RetakeTestPage5(
          backward: _previousPage,
          forward: _nextPage,
          progress: 5 / 6,
          initialValues: ui.topics,
          onValuesChanged: vm.setTopics,
        );
        break;

      case 5:
        // Page 6: What are your goals (progress 6/6)
        currentWidget = _RetakeTestPage6(
          backward: _previousPage,
          forward: _nextPage,
          progress: 6 / 6,
          initialValue: ui.goals,
          onValueChanged: vm.setGoals,
        );
        break;

      case 6:
        // Page 7: Copie de OnBoarding29
        currentWidget = OnBoarding29(
          forward: _nextPage,
        );
        break;

      case 7:
        // Page 8: Copie de OnBoarding30
        currentWidget = OnBoarding30(
          forward: _nextPage,
        );
        break;

      case 8:
        // Page 9: Copy of OnBoarding31 - but we store the computed percentages
        // OnBoarding31 reads from SharedPreferences, so we must save temporarily first
        // the in-memory answers to SharedPreferences so OnBoarding31 can read them
        currentWidget = _RetakeTestPage9(
          forward: _nextPage,
          answers: {
            "situation": ui.situation,
            "improvement": ui.improvement,
            "focus": ui.mainfocus,
            "challenge": ui.bigchall,
            "topics": ui.topics,
          },
          onPercentagesCalculated: vm.setPlanPercentages,
        );
        break;

      case 9:
        // Page 10: Copy of OnBoarding32 but with SecondaryButton "Save" and "Cancel"
        currentWidget = _RetakeTestPage10(
          backward: _previousPage,
          initialPercentages: ui.planPercentages,
          onPercentagesChanged: vm.setPlanPercentages,
          onSave: _saveAndReturn,
          onCancel: _cancel,
        );
        break;

      default:
        currentWidget = Container();
    }

    return PopScope(
      canPop: ui.currentPage == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (ui.currentPage > 0) {
            _previousPage();
          } else {
            Navigator.of(context).pop(false);
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: currentWidget,
      ),
    );
  }
}

// Page 2: What do you need to improve - Based on OnBoarding4 but with progress bar, flamy_nerd, without "nice to meet you"
class _RetakeTestPage2 extends ConsumerStatefulWidget {
  final VoidCallback? backward;
  final VoidCallback forward;
  final double progress;
  final List<String> initialValues;
  final Function(List<String>) onValuesChanged;

  const _RetakeTestPage2({
    this.backward,
    required this.forward,
    required this.progress,
    required this.initialValues,
    required this.onValuesChanged,
  });

  @override
  ConsumerState<_RetakeTestPage2> createState() => _RetakeTestPage2State();
}

class _RetakeTestPage2State extends ConsumerState<_RetakeTestPage2> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  List<bool> isChecked = [];

  final List<String> choiceList = const [
    "myconsistency",
    "myfocus",
    "myambition",
    "myconfidence",
    "mygoals",
  ];

  @override
  void initState() {
    super.initState();
    isChecked = List.filled(choiceList.length, false);
    _loadSavedSelections();
  }

  void _loadSavedSelections() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final saved = widget.initialValues;
      if (saved.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final prefsSaved = prefs.getStringList("improvement") ?? [];
        for (int j = 0; j < choiceList.length; j++) {
          isChecked[j] = prefsSaved.contains(choiceList[j]);
        }
      } else {
        for (int j = 0; j < choiceList.length; j++) {
          isChecked[j] = saved.contains(choiceList[j]);
        }
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  void handleTap() {
    List<String> selectedList = [];
    for (var i = 0; i < choiceList.length; i++) {
      if (isChecked[i]) {
        selectedList.add(choiceList[i]);
      }
    }
    widget.onValuesChanged(selectedList);
    widget.forward();
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
        child: Stack(
          children: [
            // Back icon at the top left
            if (widget.backward != null)
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
              padding: EdgeInsets.only(top: 40 * yFact, bottom: 30 * xFact),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      // Image flamy_nerd
                      SizedBox(
                        height: 100 * yFact,
                        child: Image.asset(
                          'assets/images/flamy/flamy_nerd.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: 0 * yFact),
                      // Question (without "nice to meet you")
                      Padding(
                        padding: EdgeInsetsGeometry.only(left: 30 * xFact, right: 30 * xFact),
                        child: Text(
                          translate("onboarding4_question", lang),
                          style: TextStyle(
                            fontFamily: "YesevaOne",
                            fontSize: 24 * xFact,
                            color: Color(0xFFfff9ee),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 10 * yFact),
                      // Subtitle
                      Padding(
                        padding: EdgeInsetsGeometry.only(left: 40 * xFact, right: 40 * xFact),
                        child: Text(
                          translate("onboarding4_subtitle", lang),
                          style: TextStyle(
                            fontFamily: "InterTight",
                            fontSize: 16 * xFact,
                            color: Color(0xFFb4ac9c),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (choiceList.isNotEmpty) SizedBox(height: 15 * yFact),
                    ],
                  ),
                  // Choices list
                  Flexible(
                    child: ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
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
                            if (index < choiceList.length - 1) SizedBox(height: 10 * yFact),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Bouton Continue en bas
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
                    onTap: () => handleTap(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Page 10: Copy of OnBoarding32 but with SecondaryButton "Save" and "Cancel"
class _RetakeTestPage10 extends ConsumerStatefulWidget {
  final VoidCallback? backward;
  final Map<String, double> initialPercentages;
  final Function(Map<String, double>) onPercentagesChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _RetakeTestPage10({
    this.backward,
    required this.initialPercentages,
    required this.onPercentagesChanged,
    required this.onSave,
    required this.onCancel,
  });

  @override
  ConsumerState<_RetakeTestPage10> createState() => _RetakeTestPage10State();
}

class _RetakeTestPage10State extends ConsumerState<_RetakeTestPage10> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  // Copy of the logic from OnBoarding32
  Map<String, double> _initialPercentages = {};
  Map<String, double> _axisValues = {};
  final Map<String, double> _calculatedPercentages = {};
  bool _hasChanges = false;
  String? _draggingPoint;
  double _maxAxisValue = 100.0;

  final List<String> _categoryKeys = ['growth', 'discipline', 'confidence', 'strategy'];
  final Map<String, String> _categoryNameKeys = {
    'growth': 'plan_category_growth',
    'discipline': 'plan_category_discipline',
    'confidence': 'plan_category_confidence',
    'strategy': 'plan_category_strategy',
  };

  @override
  void initState() {
    super.initState();
    for (var key in _categoryKeys) {
      _initialPercentages[key] = 25.0;
      _axisValues[key] = 25.0;
    }
    _loadSavedPercentages();
  }

  Future<void> _loadSavedPercentages() async {
    // Use the initial values passed as parameter, or load from SharedPreferences
    if (widget.initialPercentages.isNotEmpty) {
      // Use the temporary values passed as parameter (priority)
      _initialPercentages = Map.from(widget.initialPercentages);
      
      if (kDebugMode) {
        debugPrint("📊 [RetakeTestPage10] Using temporary percentages:");
        for (var entry in _initialPercentages.entries) {
          debugPrint("  ${entry.key}: ${entry.value.toStringAsFixed(2)}%");
        }
      }
    } else {
      // Fallback: load from SharedPreferences if no temporary values
      final prefs = await SharedPreferences.getInstance();
      for (var key in _categoryKeys) {
        final percentage = prefs.getDouble("plan_${key}_percentage");
        if (percentage != null && percentage >= 10.0 && percentage <= 100.0) {
          _initialPercentages[key] = percentage;
        } else {
          _initialPercentages[key] = 25.0;
        }
      }
      
      if (kDebugMode) {
        debugPrint("📊 [RetakeTestPage10] Loading from SharedPreferences (fallback):");
        for (var entry in _initialPercentages.entries) {
          debugPrint("  ${entry.key}: ${entry.value.toStringAsFixed(2)}%");
        }
      }
    }

    if (_initialPercentages.isNotEmpty) {
      _maxAxisValue = _initialPercentages.values.reduce((a, b) => a > b ? a : b);
    } else {
      _maxAxisValue = 100.0;
    }

    for (var key in _categoryKeys) {
      _axisValues[key] = _initialPercentages[key] ?? 0.0;
    }

    _updateCalculatedPercentages();

    if (mounted) {
      setState(() {});
    }
  }

  void _updateCalculatedPercentages() {
    double total = _axisValues.values.fold(0.0, (sum, val) => sum + val);

    if (total == 0) {
      for (var key in _categoryKeys) {
        _calculatedPercentages[key] = 25.0;
      }
    } else {
      for (var key in _categoryKeys) {
        final axisValue = _axisValues[key] ?? 0.0;
        _calculatedPercentages[key] = (axisValue / total) * 100.0;
      }
    }
    
    // Notify the parent of the new percentages after the build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onPercentagesChanged(Map.from(_calculatedPercentages));
      }
    });
  }

  void _onPointDragged(String categoryKey, double newValue) {
    final clampedValue = newValue.clamp(0.0, _maxAxisValue);
    final oldValue = _axisValues[categoryKey] ?? 0.0;

    if ((clampedValue - oldValue).abs() < 0.01) return;

    _axisValues[categoryKey] = clampedValue;
    _updateCalculatedPercentages();

    _hasChanges = _axisValues.entries.any((entry) {
      final initial = _initialPercentages[entry.key] ?? 0.0;
      return (entry.value - initial).abs() > 0.1;
    });

    setState(() {});
  }

  void _resetToInitial() {
    setState(() {
      _axisValues = Map.from(_initialPercentages);
      _updateCalculatedPercentages();
      _hasChanges = false;
    });
  }

  void _save() {
    // Percentages are already updated in the parent via onPercentagesChanged
    // We just call onSave to trigger the final save
    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final userName = ref.watch(userNameStateProvider);

    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      color: appTheme.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (widget.backward != null)
                        GestureDetector(
                          onTap: widget.backward,
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: appTheme.onBackground,
                            size: 30 * xFact,
                          ),
                        ),
                      SizedBox(width: 10 * xFact),
                      Expanded(
                        child: Text(
                          "$userName's ${translate("plan_title", lang)}",
                          style: TextStyle(
                            fontFamily: "YesevaOne",
                            fontSize: 28 * xFact,
                            color: appTheme.onBackground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15 * yFact),
                  Center(
                    child: SizedBox(
                      width: 90 * xFact,
                      child: Image.asset(
                        'assets/images/flamy/flamy_podium.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image, size: 150 * xFact, color: appTheme.onBackground);
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20 * yFact),
                  Text(
                    translate("plan_intro_text", lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "YesevaOne",
                      fontSize: 18 * xFact,
                      color: appTheme.onBackground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10 * yFact),
                  Text(
                    translate("plan_intro_subtext", lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "InterTight",
                      fontSize: 14 * xFact,
                      color: appTheme.onBackground.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: 20 * yFact),
                ],
              ),
              Column(
                children: [
                  // Spider chart - Use the _SpiderChart widget from onboarding32.dart
                  SizedBox(
                    height: 280 * yFact,
                    child: _SpiderChart(
                      axisValues: _axisValues,
                      categoryKeys: _categoryKeys,
                      categoryNameKeys: _categoryNameKeys,
                      lang: lang,
                      maxAxisValue: _maxAxisValue,
                      onPointDragged: _onPointDragged,
                      onDragStart: (key) {
                        setState(() {
                          _draggingPoint = key;
                        });
                      },
                      onDragEnd: () {
                        setState(() {
                          _draggingPoint = null;
                        });
                      },
                      draggingKey: _draggingPoint,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(bottom:  30.0),
                child: Column(
                  children: [
                    _hasChanges ?
                    Center(
                      child: GestureDetector(
                        onTap: _resetToInitial,
                        child: Text(
                          translate("reset", lang),
                          style: TextStyle(
                            fontFamily: "InterTight",
                            fontSize: 20 * xFact,
                            color: appTheme.onPrimButtonGold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ) : SizedBox(height: 28*yFact,),
                    SizedBox(height: 10*yFact,),
                    SecondaryButton(
                      text: translate("save", lang),
                      onTap: _save,
                    ),
                    SizedBox(height: 10*yFact,),
                    GestureDetector(
                      onTap: widget.onCancel,
                      child: Text(
                        translate("cancel", lang),
                        style: TextStyle(
                          fontFamily: "InterTight",
                          fontSize: 18 * xFact,
                          color: appTheme.onBackground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== Custom pages that store in memory instead of saving ==========

// Page 1: What is your personal status
class _RetakeTestPage1 extends ConsumerStatefulWidget {
  final VoidCallback? backward;
  final VoidCallback forward;
  final double progress;
  final String? initialValue;
  final Function(String) onValueChanged;

  const _RetakeTestPage1({
    this.backward,
    required this.forward,
    required this.progress,
    this.initialValue,
    required this.onValueChanged,
  });

  @override
  ConsumerState<_RetakeTestPage1> createState() => _RetakeTestPage1State();
}

class _RetakeTestPage1State extends ConsumerState<_RetakeTestPage1> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    _loadSavedValue();
  }

  void _loadSavedValue() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString("situation");
      if (saved != null && _selectedValue == null) {
        setState(() {
          _selectedValue = saved;
        });
      }
    });
  }

  void handleTap(String choice) {
    setState(() {
      _selectedValue = choice;
    });
    widget.onValueChanged(choice);
    widget.forward();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final choiceList = const [
      "Employee",
      "Entrepreneur",
      "Leader",
      "Looking2",
      "Looking",
      "Student",
      "nottosay",
    ];

    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      color: appTheme.background,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            if (widget.backward != null)
              Positioned(
                top: 15 * yFact,
                left: 20 * xFact,
                child: GestureDetector(
                  onTap: widget.backward,
                  child: Icon(Icons.arrow_back_ios, color: Color(0xFFfff9ee)),
                ),
              ),
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
              padding: EdgeInsets.only(top: 40 * yFact, bottom: 30 * xFact),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 100 * yFact,
                    child: Image.asset('assets/images/flamy/flamy_nerd.png', fit: BoxFit.contain),
                  ),
                  SizedBox(height: 0 * yFact),
                  Padding(
                    padding: EdgeInsetsGeometry.only(left: 30 * xFact, right: 30 * xFact),
                    child: Text(
                      translate("onboardingtitle6", lang),
                      style: TextStyle(
                        fontFamily: "YesevaOne",
                        fontSize: 24 * xFact,
                        color: Color(0xFFfff9ee),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 10 * yFact),
                  Padding(
                    padding: EdgeInsetsGeometry.only(left: 40 * xFact, right: 40 * xFact),
                    child: Text(
                      translate("onboardingsubtitle6", lang),
                      style: TextStyle(
                        fontFamily: "InterTight",
                        fontSize: 16 * xFact,
                        color: Color(0xFFb4ac9c),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (choiceList.isNotEmpty) SizedBox(height: 15 * yFact),
                  Flexible(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: choiceList.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            Padding(
                              padding: EdgeInsetsGeometry.only(left: 20 * xFact, right: 20 * xFact),
                              child: TertiaryButton(
                                center: false,
                                borderWidth: 1 * xFact,
                                text: translate(choiceList[index], lang),
                                onTap: () => handleTap(choiceList[index]),
                              ),
                            ),
                            if (index < choiceList.length - 1) SizedBox(height: 10 * yFact),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Page 2: What do you need to improve (already created, but needs editing)
// Page 3: What is your main focus
class _RetakeTestPage3 extends ConsumerStatefulWidget {
  final VoidCallback? backward;
  final VoidCallback forward;
  final double progress;
  final List<String> initialValues;
  final Function(List<String>) onValuesChanged;

  const _RetakeTestPage3({
    this.backward,
    required this.forward,
    required this.progress,
    required this.initialValues,
    required this.onValuesChanged,
  });

  @override
  ConsumerState<_RetakeTestPage3> createState() => _RetakeTestPage3State();
}

class _RetakeTestPage3State extends ConsumerState<_RetakeTestPage3> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  List<bool> isChecked = [];
  final choiceList = const [
    "startingbus",
    "saclingrev",
    "improvprod",
    "finfree",
    "betlead",
    "preprol",
  ];

  @override
  void initState() {
    super.initState();
    isChecked = List.filled(choiceList.length, false);
    _loadSavedValues();
  }

  void _loadSavedValues() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final saved = widget.initialValues;
      if (saved.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        // focus == mainfocus
        final prefsSaved = prefs.getStringList("focus") ?? prefs.getStringList("mainfocus") ?? [];
        for (int j = 0; j < choiceList.length; j++) {
          isChecked[j] = prefsSaved.contains(choiceList[j]);
        }
      } else {
        for (int j = 0; j < choiceList.length; j++) {
          isChecked[j] = saved.contains(choiceList[j]);
        }
      }
      if (mounted) setState(() {});
    });
  }

  void handleTap() {
    List<String> selectedList = [];
    for (var i = 0; i < choiceList.length; i++) {
      if (isChecked[i]) {
        selectedList.add(choiceList[i]);
      }
    }
    widget.onValuesChanged(selectedList);
    widget.forward();
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
        child: Stack(
          children: [
            if (widget.backward != null)
              Positioned(
                top: 15 * yFact,
                left: 20 * xFact,
                child: GestureDetector(
                  onTap: widget.backward,
                  child: Icon(Icons.arrow_back_ios, color: Color(0xFFfff9ee)),
                ),
              ),
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
              padding: EdgeInsets.only(top: 40 * yFact, bottom: 30 * xFact),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 100 * yFact,
                    child: Image.asset('assets/images/flamy/flamy_nerd.png', fit: BoxFit.contain),
                  ),
                  SizedBox(height: 0 * yFact),
                  Padding(
                    padding: EdgeInsetsGeometry.only(left: 30 * xFact, right: 30 * xFact),
                    child: Text(
                      translate("onboardingtitle14", lang),
                      style: TextStyle(
                        fontFamily: "YesevaOne",
                        fontSize: 24 * xFact,
                        color: Color(0xFFfff9ee),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 10 * yFact),
                  Padding(
                    padding: EdgeInsetsGeometry.only(left: 40 * xFact, right: 40 * xFact),
                    child: Text(
                      translate("onboardingsubtitle20", lang),
                      style: TextStyle(
                        fontFamily: "InterTight",
                        fontSize: 16 * xFact,
                        color: Color(0xFFb4ac9c),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (choiceList.isNotEmpty) SizedBox(height: 15 * yFact),
                  Flexible(
                    child: ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
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
                            if (index < choiceList.length - 1) SizedBox(height: 10 * yFact),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
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
                    onTap: () => handleTap(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Page 4: What is your biggest challenge (same as Page 3 but with different choices)
class _RetakeTestPage4 extends ConsumerStatefulWidget {
  final VoidCallback? backward;
  final VoidCallback forward;
  final double progress;
  final List<String> initialValues;
  final Function(List<String>) onValuesChanged;

  const _RetakeTestPage4({
    this.backward,
    required this.forward,
    required this.progress,
    required this.initialValues,
    required this.onValuesChanged,
  });

  @override
  ConsumerState<_RetakeTestPage4> createState() => _RetakeTestPage4State();
}

class _RetakeTestPage4State extends ConsumerState<_RetakeTestPage4> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  List<bool> isChecked = [];
  final choiceList = const [
    "staycons",
    "presdeal",
    "mantim",
    "keepfoc",
    "doubt",
    "motivd",
  ];

  @override
  void initState() {
    super.initState();
    isChecked = List.filled(choiceList.length, false);
    _loadSavedValues();
  }

  void _loadSavedValues() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final saved = widget.initialValues;
      if (saved.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        // challenge == bigchall
        final prefsSaved = prefs.getStringList("challenge") ?? prefs.getStringList("bigchall") ?? [];
        for (int j = 0; j < choiceList.length; j++) {
          isChecked[j] = prefsSaved.contains(choiceList[j]);
        }
      } else {
        for (int j = 0; j < choiceList.length; j++) {
          isChecked[j] = saved.contains(choiceList[j]);
        }
      }
      if (mounted) setState(() {});
    });
  }

  void handleTap() {
    List<String> selectedList = [];
    for (var i = 0; i < choiceList.length; i++) {
      if (isChecked[i]) {
        selectedList.add(choiceList[i]);
      }
    }
    widget.onValuesChanged(selectedList);
    widget.forward();
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
        child: Stack(
          children: [
            if (widget.backward != null)
              Positioned(
                top: 15 * yFact,
                left: 20 * xFact,
                child: GestureDetector(
                  onTap: widget.backward,
                  child: Icon(Icons.arrow_back_ios, color: Color(0xFFfff9ee)),
                ),
              ),
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
              padding: EdgeInsets.only(top: 40 * yFact, bottom: 30 * xFact),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 100 * yFact,
                    child: Image.asset('assets/images/flamy/flamy_nerd.png', fit: BoxFit.contain),
                  ),
                  SizedBox(height: 0 * yFact),
                  Padding(
                    padding: EdgeInsetsGeometry.only(left: 30 * xFact, right: 30 * xFact),
                    child: Text(
                      translate("onboardingtitle15", lang),
                      style: TextStyle(
                        fontFamily: "YesevaOne",
                        fontSize: 24 * xFact,
                        color: Color(0xFFfff9ee),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 10 * yFact),
                  Padding(
                    padding: EdgeInsetsGeometry.only(left: 40 * xFact, right: 40 * xFact),
                    child: Text(
                      translate("onboardingsubtitle15", lang),
                      style: TextStyle(
                        fontFamily: "InterTight",
                        fontSize: 16 * xFact,
                        color: Color(0xFFb4ac9c),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (choiceList.isNotEmpty) SizedBox(height: 15 * yFact),
                  Flexible(
                    child: ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
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
                            if (index < choiceList.length - 1) SizedBox(height: 10 * yFact),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
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
                    onTap: () => handleTap(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Page 5: Which topics do you (style check2)
class _RetakeTestPage5 extends ConsumerStatefulWidget {
  final VoidCallback? backward;
  final VoidCallback forward;
  final double progress;
  final List<String> initialValues;
  final Function(List<String>) onValuesChanged;

  const _RetakeTestPage5({
    this.backward,
    required this.forward,
    required this.progress,
    required this.initialValues,
    required this.onValuesChanged,
  });

  @override
  ConsumerState<_RetakeTestPage5> createState() => _RetakeTestPage5State();
}

class _RetakeTestPage5State extends ConsumerState<_RetakeTestPage5> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  List<bool> isChecked = [];
  final choiceList = const [
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
  ];

  @override
  void initState() {
    super.initState();
    isChecked = List.filled(choiceList.length, false);
    _loadSavedValues();
  }

  void _loadSavedValues() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final saved = widget.initialValues;
      if (saved.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final prefsSaved = prefs.getStringList("topics") ?? [];
        for (int j = 0; j < choiceList.length; j++) {
          isChecked[j] = prefsSaved.contains(choiceList[j]);
        }
      } else {
        for (int j = 0; j < choiceList.length; j++) {
          isChecked[j] = saved.contains(choiceList[j]);
        }
      }
      if (mounted) setState(() {});
    });
  }

  void handleTap() {
    List<String> selectedList = [];
    for (var i = 0; i < choiceList.length; i++) {
      if (isChecked[i]) {
        selectedList.add(choiceList[i]);
      }
    }
    widget.onValuesChanged(selectedList);
    widget.forward();
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
        child: Stack(
          children: [
            if (widget.backward != null)
              Positioned(
                top: 15 * yFact,
                left: 20 * xFact,
                child: GestureDetector(
                  onTap: widget.backward,
                  child: Icon(Icons.arrow_back_ios, color: Color(0xFFfff9ee)),
                ),
              ),
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
              padding: EdgeInsets.only(top: 40 * yFact, bottom: 30 * xFact),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 100 * yFact,
                    child: Image.asset('assets/images/flamy/flamy_nerd.png', fit: BoxFit.contain),
                  ),
                  SizedBox(height: 0 * yFact),
                  Padding(
                    padding: EdgeInsetsGeometry.only(left: 30 * xFact, right: 30 * xFact),
                    child: Text(
                      translate("onboardingtitle17", lang),
                      style: TextStyle(
                        fontFamily: "YesevaOne",
                        fontSize: 24 * xFact,
                        color: Color(0xFFfff9ee),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 10 * yFact),
                  Padding(
                    padding: EdgeInsetsGeometry.only(left: 40 * xFact, right: 40 * xFact),
                    child: Text(
                      translate("onboardingsubtitle17", lang),
                      style: TextStyle(
                        fontFamily: "InterTight",
                        fontSize: 16 * xFact,
                        color: Color(0xFFb4ac9c),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (choiceList.isNotEmpty) SizedBox(height: 15 * yFact),
                  Flexible(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: choiceList.length,
                      separatorBuilder: (context, index) => Divider(
                        color: appTheme.onBackground,
                        thickness: 1 * yFact,
                        height: 12 * yFact,
                      ),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
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
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isChecked[index] = !isChecked[index];
                                  });
                                },
                                child: Icon(
                                  isChecked[index] ? Icons.check : Icons.add,
                                  size: 20 * xFact,
                                  color: Color(0xFFfff9ee),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
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
                    onTap: () => handleTap(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Page 6: What are your goals
class _RetakeTestPage6 extends ConsumerStatefulWidget {
  final VoidCallback? backward;
  final VoidCallback forward;
  final double progress;
  final String? initialValue;
  final Function(String) onValueChanged;

  const _RetakeTestPage6({
    this.backward,
    required this.forward,
    required this.progress,
    this.initialValue,
    required this.onValueChanged,
  });

  @override
  ConsumerState<_RetakeTestPage6> createState() => _RetakeTestPage6State();
}

class _RetakeTestPage6State extends ConsumerState<_RetakeTestPage6> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  String inputText = "";
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _textFieldKey = GlobalKey();

  void _scrollToTextField() {
    if (!_focusNode.hasFocus || _textFieldKey.currentContext == null) return;
    
    // Wait for the keyboard to open
    Future.delayed(Duration(milliseconds: 500), () {
      if (!mounted || _textFieldKey.currentContext == null) return;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _textFieldKey.currentContext == null) return;
        
        // Use Scrollable.ensureVisible simply
        try {
          Scrollable.ensureVisible(
            _textFieldKey.currentContext!,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.0,
          );
        } catch (e) {
          // If that doesn't work, try with the ScrollController
          if (_scrollController.hasClients) {
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            if (keyboardHeight > 0) {
              // Scroll by an amount based on the keyboard height
              final currentScroll = _scrollController.position.pixels;
              final targetScroll = currentScroll + (keyboardHeight * 0.5);
              _scrollController.animateTo(
                targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    inputText = widget.initialValue ?? "";
    _textController.text = inputText;
    _textController.addListener(() {
      setState(() {
        inputText = _textController.text;
      });
    });
    _loadSavedInput();
    // Scroll to the field only when it gains focus (keyboard opens)
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _scrollToTextField();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadSavedInput() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (inputText.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final saved = prefs.getString("goals");
        if (saved != null) {
          _textController.text = saved;
          setState(() {
            inputText = saved;
          });
        }
      }
    });
  }

  void handleTap() {
    widget.onValueChanged(inputText);
    widget.forward();
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
            // Main content with scroll to stay visible when the keyboard opens
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Header with progress bar and back icon
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        // Barre de progression
                        Padding(
                          padding: EdgeInsets.only(top: 9, left: 0, right: 0),
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
                        // Back icon
                        if (widget.backward != null)
                          Positioned(
                            top: 15 * yFact,
                            left: 20 * xFact,
                            child: GestureDetector(
                              onTap: widget.backward,
                              child: Icon(Icons.arrow_back_ios, color: appTheme.onBackground),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Contenu principal
                  SliverPadding(
                    padding: EdgeInsets.only(
                      top: 40 * yFact,
                      bottom: 100 * yFact,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 100 * yFact,
                            child: Image.asset('assets/images/flamy/flamy_nerd.png', fit: BoxFit.contain),
                          ),
                          SizedBox(height: 0 * yFact),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 50 * xFact),
                            child: Text(
                              translate("onboardingtitle16", lang),
                              style: TextStyle(
                                fontFamily: "YesevaOne",
                                fontSize: 24 * xFact,
                                color: Color(0xFFfff9ee),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 10 * yFact),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40 * xFact),
                            child: Text(
                              translate("onboardingsubtitle16", lang),
                              style: TextStyle(
                                fontFamily: "InterTight",
                                fontSize: 16 * xFact,
                                color: appTheme.onBackgroundSub,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 30 * yFact),
                          Padding(
                            padding: EdgeInsetsGeometry.only(right: 35 * xFact, left: 35 * xFact),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  key: _textFieldKey,
                                  child: CustomTextField(
                                    minLines: 8,
                                    maxLines: 8,
                                    maxLength: 250,
                                    inputStyle: "input2",
                                    fontFamily: "InterTight",
                                    fontSize: 18 * xFact,
                                    backgroundColor: Color(0xFF504b41).withAlpha(90),
                                    borderColor: Color(0xFF504b41),
                                    textColor: appTheme.onBackground,
                                    hintText: translate("Iwantto", lang),
                                    controller: _textController,
                                    focusNode: _focusNode,
                                    textInputAction: TextInputAction.done,
                                    onChanged: (String value) {
                                      setState(() {
                                        inputText = value;
                                      });
                                    },
                                    onSubmitted: () {
                                      // Close the keyboard when validating with the Enter key
                                      _focusNode.unfocus();
                                    },
                                  ),
                                ),
                                // Counter positioned just below, right-aligned
                                Padding(
                                  padding: EdgeInsets.only(
                                    right: 12 * xFact,
                                    top: 4 * yFact,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: _textController,
                                      builder: (context, value, child) {
                                        return Text(
                                          '${value.text.length}/250',
                                          style: TextStyle(
                                            fontFamily: "InterTight",
                                            fontSize: 18 * xFact * 0.8,
                                            color: appTheme.onBackground,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 30 * yFact,
              left: 20 * xFact,
              right: 20 * xFact,
              child: SecondaryButton(
                text: translate("continue", lang),
                onTap: () => handleTap(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Page 9: OnBoarding31 modified to store percentages in memory
class _RetakeTestPage9 extends ConsumerStatefulWidget {
  final VoidCallback forward;
  final Function(Map<String, double>) onPercentagesCalculated;
  final Map<String, dynamic> answers; // Réponses stockées en mémoire

  const _RetakeTestPage9({
    required this.forward,
    required this.onPercentagesCalculated,
    required this.answers,
  });

  @override
  ConsumerState<_RetakeTestPage9> createState() => _RetakeTestPage9State();
}

class _RetakeTestPage9State extends ConsumerState<_RetakeTestPage9> {
  bool _hasSavedTemporaryAnswers = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _saveTemporaryAnswers();
  }
  
  Future<void> _saveTemporaryAnswers() async {
    if (_hasSavedTemporaryAnswers) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Temporarily save answers so OnBoarding31 can read them
    if (widget.answers["situation"] != null) {
      await prefs.setString("situation", widget.answers["situation"] as String);
    } else {
      await prefs.remove("situation");
    }
    
    await prefs.setStringList("improvement", 
      (widget.answers["improvement"] as List<String>?) ?? []);
    
    await prefs.setStringList("focus", 
      (widget.answers["focus"] as List<String>?) ?? []);
    
    await prefs.setStringList("challenge", 
      (widget.answers["challenge"] as List<String>?) ?? []);
    
    await prefs.setStringList("topics", 
      (widget.answers["topics"] as List<String>?) ?? []);
    
    if (kDebugMode) {
      debugPrint("💾 [RetakeTestPage9] Temporary answers saved for OnBoarding31:");
      debugPrint("  situation: ${widget.answers["situation"]}");
      debugPrint("  improvement: ${widget.answers["improvement"]}");
      debugPrint("  focus: ${widget.answers["focus"]}");
      debugPrint("  challenge: ${widget.answers["challenge"]}");
      debugPrint("  topics: ${widget.answers["topics"]}");
    }
    
    _hasSavedTemporaryAnswers = true;
    _isLoading = false;
    
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Make sure answers are saved before showing OnBoarding31
    if (_isLoading || !_hasSavedTemporaryAnswers) {
      return Container(
        color: appTheme.background,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    // OnBoarding31 reads from SharedPreferences and computes percentages
    // Intercept forward to retrieve the computed percentages
    return OnBoarding31(
      forward: () async {
        // OnBoarding31 computed and saved the percentages
        // Fetch them from SharedPreferences (they were saved temporarily)
        // Then store them in memory via the callback
        await Future.delayed(Duration(milliseconds: 50)); // Attendre que la sauvegarde soit faite
        final prefs = await SharedPreferences.getInstance();
        final percentages = <String, double>{};
        for (var key in ['growth', 'discipline', 'confidence', 'strategy']) {
          final percentage = prefs.getDouble("plan_${key}_percentage");
          if (percentage != null) {
            percentages[key] = percentage;
          }
        }
        
        if (kDebugMode) {
          debugPrint("📊 [RetakeTestPage9] Percentages computed from OnBoarding31:");
          for (var entry in percentages.entries) {
            debugPrint("  ${entry.key}: ${entry.value.toStringAsFixed(2)}%");
          }
        }
        
        widget.onPercentagesCalculated(percentages);
        widget.forward();
      },
    );
  }
}

// Copy of the _SpiderChart widget from onboarding32.dart
class _SpiderChart extends StatefulWidget {
  final Map<String, double> axisValues;
  final List<String> categoryKeys;
  final Map<String, String> categoryNameKeys;
  final Function(String, double) onPointDragged;
  final Function(String) onDragStart;
  final VoidCallback onDragEnd;
  final String? draggingKey;
  final String lang;
  final double maxAxisValue;

  const _SpiderChart({
    required this.axisValues,
    required this.categoryKeys,
    required this.categoryNameKeys,
    required this.onPointDragged,
    required this.onDragStart,
    required this.onDragEnd,
    required this.lang,
    required this.maxAxisValue,
    this.draggingKey,
  });

  @override
  State<_SpiderChart> createState() => _SpiderChartState();
}

class _SpiderChartState extends State<_SpiderChart> {
  String? _localDraggingKey;
  double? _dragStartValue;
  double _accumulatedDelta = 0.0;
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final center = Offset(size.width / 2, size.height / 2);
        final radius = math.min(size.width, size.height) / 2 - 50 * xFact;
        final maxValue = widget.maxAxisValue;

        return Stack(
          children: [
            CustomPaint(
              painter: _SpiderChartPainter(
                axisValues: widget.axisValues,
                categoryKeys: widget.categoryKeys,
                draggingKey: _localDraggingKey ?? widget.draggingKey,
                maxAxisValue: maxValue,
                xFact: xFact,
                yFact: yFact,
              ),
              size: size,
            ),
            ...widget.categoryKeys.asMap().entries.map((entry) {
              final i = entry.key;
              final key = entry.value;
              final value = widget.axisValues[key] ?? 0.0;
              final angle = (i * 2 * math.pi / widget.categoryKeys.length) - (math.pi / 2);
              final pointRadius = (value / maxValue) * radius;
              final pointX = center.dx + pointRadius * math.cos(angle);
              final pointY = center.dy + pointRadius * math.sin(angle);
              final isDragging = (_localDraggingKey ?? widget.draggingKey) == key;

              return Positioned(
                left: pointX - 10 * xFact,
                top: pointY - 10 * xFact,
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _localDraggingKey = key;
                      _dragStartValue = widget.axisValues[key] ?? 0.0;
                      _accumulatedDelta = 0.0;
                    });
                    widget.onDragStart(key);
                  },
                  onPanUpdate: (details) {
                    if (_localDraggingKey == key && _dragStartValue != null) {
                      final angle = (i * 2 * math.pi / widget.categoryKeys.length) - (math.pi / 2);
                      final axisDx = math.cos(angle);
                      final axisDy = math.sin(angle);
                      final deltaProjection = details.delta.dx * axisDx + details.delta.dy * axisDy;
                      final deltaValue = (deltaProjection / radius) * maxValue;
                      _accumulatedDelta += deltaValue;
                      final newValue = (_dragStartValue! + _accumulatedDelta).clamp(0.0, maxValue);
                      widget.onPointDragged(key, newValue);
                    }
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _localDraggingKey = null;
                      _dragStartValue = null;
                      _accumulatedDelta = 0.0;
                    });
                    widget.onDragEnd();
                  },
                  child: Container(
                    width: 20 * xFact,
                    height: 20 * xFact,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: Container(
                        width: isDragging ? 16 * xFact : 12 * xFact,
                        height: isDragging ? 16 * xFact : 12 * xFact,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: appTheme.onPrimButtonGold,
                          boxShadow: isDragging ? [
                            BoxShadow(
                              color: appTheme.onPrimButtonGold.withValues(alpha: 0.3),
                              blurRadius: 8 * xFact,
                              spreadRadius: 4 * xFact,
                            ),
                          ] : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            ...widget.categoryKeys.asMap().entries.map((entry) {
              final i = entry.key;
              final key = entry.value;
              final iconPath = 'assets/images/$key.png';
              final angle = (i * 2 * math.pi / widget.categoryKeys.length) - (math.pi / 2);
              final iconX = center.dx + (radius + 25 * xFact) * math.cos(angle);
              final iconY = center.dy + (radius + 20 * yFact) * math.sin(angle);

              return Positioned(
                left: iconX - 12 * xFact,
                top: iconY - 12 * yFact,
                child: SizedBox(
                  width: 25 * xFact,
                  height: 25 * xFact,
                  child: Image.asset(
                    iconPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.circle, size: 30 * xFact, color: appTheme.onPrimButtonGold);
                    },
                  ),
                ),
              );
            }),
            ...widget.categoryKeys.asMap().entries.map((entry) {
              final i = entry.key;
              final key = entry.value;
              final angle = (i * 2 * math.pi / widget.categoryKeys.length) - (math.pi / 2);
              final iconX = center.dx + (radius + 20 * xFact) * math.cos(angle);
              final iconY = center.dy + (radius + 20 * xFact) * math.sin(angle);

              final categoryName = translate(widget.categoryNameKeys[key]!, widget.lang);
              final textOffset = 0 * xFact;

              if (key == 'growth') {
                return Positioned(
                  left: iconX - 60 * xFact,
                  top: iconY - 26 * xFact - textOffset,
                  width: 120 * xFact,
                  child: Text(
                    categoryName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "InterTight",
                      fontSize: 11 * xFact,
                      color: appTheme.onBackground,
                    ),
                  ),
                );
              } else if (key == 'confidence') {
                return Positioned(
                  left: iconX - 60 * xFact,
                  top: iconY + 14 * xFact + textOffset,
                  width: 120 * xFact,
                  child: Text(
                    categoryName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "InterTight",
                      fontSize: 11 * xFact,
                      color: appTheme.onBackground,
                    ),
                  ),
                );
              } else if (key == 'strategy') {
                return Positioned(
                  left: iconX - 15 * xFact - 9 * xFact,
                  top: iconY + 15 * xFact + textOffset,
                  width: 80 * xFact,
                  child: Text(
                      categoryName,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: "InterTight",
                        fontSize: 11 * xFact,
                        color: appTheme.onBackground,
                      ),
                    ),
                );
              } else if (key == 'discipline') {
                return Positioned(
                  left: iconX - 55 * xFact,
                  top: iconY + 15 * xFact + textOffset,
                  width: 80 * xFact,
                  child: Text(
                    categoryName,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: "InterTight",
                      fontSize: 11 * xFact,
                      color: appTheme.onBackground,
                    ),
                  ),
                );
              }
              return SizedBox.shrink();
            }),
          ],
        );
      },
    );
  }
}

class _SpiderChartPainter extends CustomPainter {
  final Map<String, double> axisValues;
  final List<String> categoryKeys;
  final String? draggingKey;
  final double maxAxisValue;
  final double xFact;
  final double yFact;

  _SpiderChartPainter({
    required this.axisValues,
    required this.categoryKeys,
    this.draggingKey,
    required this.maxAxisValue,
    required this.xFact,
    required this.yFact,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 50 * xFact;

    final gridPaint = Paint()
      ..color = appTheme.onBackgroundSub.withValues(alpha: 0.3)
      ..strokeWidth = 0.5 * xFact;

    final gridSteps = [0.25, 0.5, 0.75, 1.0];
    for (var step in gridSteps) {
      final gridValue = maxAxisValue * step;
      final gridRadius = (gridValue / maxAxisValue) * radius;
      canvas.drawCircle(center, gridRadius, gridPaint);
    }

    final axisPaint = Paint()
      ..color = appTheme.onBackgroundSub
      ..strokeWidth = 1 * xFact;

    for (var i = 0; i < categoryKeys.length; i++) {
      final angle = (i * 2 * math.pi / categoryKeys.length) - (math.pi / 2);
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(endX, endY), axisPaint);
    }

    final polygonPath = Path();
    for (var i = 0; i < categoryKeys.length; i++) {
      final key = categoryKeys[i];
      final value = axisValues[key] ?? 0.0;
      final angle = (i * 2 * math.pi / categoryKeys.length) - (math.pi / 2);
      final pointRadius = (value / maxAxisValue) * radius;
      final pointX = center.dx + pointRadius * math.cos(angle);
      final pointY = center.dy + pointRadius * math.sin(angle);

      if (i == 0) {
        polygonPath.moveTo(pointX, pointY);
      } else {
        polygonPath.lineTo(pointX, pointY);
      }
    }
    polygonPath.close();

    final fillPaint = Paint()
      ..color = appTheme.onPrimButtonGold.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawPath(polygonPath, fillPaint);

    final strokePaint = Paint()
      ..color = appTheme.onPrimButtonGold
      ..strokeWidth = 2 * xFact
      ..style = PaintingStyle.stroke;
    canvas.drawPath(polygonPath, strokePaint);
  }

  @override
  bool shouldRepaint(_SpiderChartPainter oldDelegate) {
    return oldDelegate.axisValues != axisValues || oldDelegate.draggingKey != draggingKey;
  }
}


