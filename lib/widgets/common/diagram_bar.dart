import 'dart:math' as math;
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../providers/language_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/global_scaler.dart';
import 'horizontal_line.dart';
import '../../services/mindset_points_service.dart';

class AnimatedWeeklyStats extends ConsumerStatefulWidget {
  const AnimatedWeeklyStats({
    super.key,
    required this.values,
    required this.nbrLabels,
    required this.onBoarding,
    this.controller,
  });

  final List<num> values;
  final int nbrLabels;
  final bool onBoarding;
  final AnimationController? controller;

  @override
  ConsumerState<AnimatedWeeklyStats> createState() => _AnimatedWeeklyStatsState();
}

class _AnimatedWeeklyStatsState extends ConsumerState<AnimatedWeeklyStats> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final bool _ownsController;
  late final Animation<double> _totalAnim;
  late final List<Animation<double>> _anims;
  int maxY = 0;
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  int mpTot =0;
  int step = 0;
  int nbrStep = 5;
  late int _totalMax; // somme finale
  List<num> _currentValues = [];

  // Check whether values are empty or all zero
  bool _areValuesEmpty(List<num> values) {
    return values.isEmpty || values.every((v) => v == 0);
  }

  // Load values from the service if needed
  Future<List<num>> _loadValuesIfNeeded() async {
    if (!_areValuesEmpty(widget.values)) {
      return widget.values;
    }

    // Load values from the service
    try {
      final values = await MindsetPointsService.instance.getAllValues();
      // By default, use the "Today" values (period 0)
      return [
        values['openTodayPoints'] ?? 1,
        values['likeTodayPoints'] ?? 0,
        values['shareTodayPoints'] ?? 0,
      ];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while loading values: $e');
      }
      // On error, return default values
      return [1, 0, 0];
    }
  }

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('AnimatedWeeklyStats initState - widget.values: ${widget.values}');
    }
    
    // Initialize animations only once
    _ownsController = widget.controller == null;
    _c = widget.controller ?? AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    final drive = CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic);
    _anims = const [
      Interval(0.00, 0.70, curve: Curves.easeInOutCubic),
      Interval(0.15, 0.85, curve: Curves.easeInOutCubic),
      Interval(0.30, 1.00, curve: Curves.easeInOutCubic),
    ].map((curve) => CurvedAnimation(parent: _c, curve: curve)).toList();
    _totalAnim = drive;
    
    // Initialize with current values (even if empty, we'll use them temporarily)
    _currentValues = widget.values;
    _initializeScale(widget.values);
    
    // Load values asynchronously if needed
    _loadValuesIfNeeded().then((loadedValues) {
      if (mounted && _areValuesEmpty(widget.values)) {
        setState(() {
          _currentValues = loadedValues;
          _totalMax = loadedValues.fold<num>(0, (s, v) => s + v).toInt();
        });
        _recomputeScale(loadedValues);
        if (_ownsController) _c.forward();
      }
    });
  }

  void _initializeScale(List<num> values) {
    // Use the same logic as _recomputeScale for consistency
    final maxValue = (values.isEmpty 
        ? 1 
        : values.fold<num>(0, (m, v) => v > m ? v : m)).toInt();
    if (kDebugMode) {
      debugPrint('AnimatedWeeklyStats _initializeScale - values: $values, maxValue calculated: $maxValue');
    }

    int desiredMaxLabels = 6; // ex: 0, 5, 10, 15, 20, 25 (6 labels)
    //maxValue = 9;/* your real max, e.g. 20 */

    // 1) starting step: about 4 intervals
    step = (maxValue / 4).round();
    if (step <= 0) step = 1;

    // 2) number of labels if we put ticks of `step` up to above maxValue
    int ticks = ((maxValue + step - 1) ~/ step) + 1; // = ceil(maxValue/step) + 1

    // 3) increase step until ≤ desiredMaxLabels labels
    while (ticks > desiredMaxLabels) {
      step++;
      ticks = ((maxValue + step - 1) ~/ step) + 1;
    }

    // 4) maxY final = step * ceil(maxValue/step)
    maxY = step * ((maxValue + step - 1) ~/ step);

    // 5) final label count (to use in List.generate)
    nbrStep = (maxY ~/ step) + 1;


    if (kDebugMode) {
      debugPrint('maxValue=$maxValue, step=$step, maxY=$maxY, nbrStep=$nbrStep');
      // to check displayed values:
      final labels = List.generate(nbrStep, (i) => maxY - i * step);
      debugPrint('labels: $labels'); // ex: [12, 9, 6, 3, 0]
    }
    // 1) add top margin (e.g. 12%)
    const headroomRatio = 0.12; // ajuste entre 0.08 et 0.18 selon la taille du label
    int scaledMaxY = ((maxY * (1 + headroomRatio)).ceil());

    // 2) reset scaledMaxY to a clean multiple of step
    int roundUpTo(int x, int s) => ((x + s - 1) ~/ s) * s;
    scaledMaxY = roundUpTo(scaledMaxY, step);

    // 3) recompute the label count with this new scale
    int scaledNbrStep = (scaledMaxY ~/ step) + 1;

    // 4) if we exceed the max label count, increase step until within the limit
    while (scaledNbrStep > desiredMaxLabels) {
      step++;
      scaledMaxY = roundUpTo((maxY * (1 + headroomRatio)).ceil(), step);
      scaledNbrStep = (scaledMaxY ~/ step) + 1;
    }

    // 5) replace the "official" scale with the inflated scale
    int finalMaxY;
    int finalNbrStep;
    if (scaledMaxY == 0 || maxValue == 0) {
      // all bars are zero → use one unit so we can layout cleanly
      finalMaxY = step;              // e.g., 1
      finalNbrStep = (finalMaxY ~/ step) + 1; // -> 2 ticks: [1, 0]
      if (kDebugMode) {
        debugPrint('_initializeScale - scaledMaxY=$scaledMaxY, maxValue=$maxValue, setting maxY=$finalMaxY, nbrStep=$finalNbrStep');
      }
    } else {
      finalMaxY = scaledMaxY;
      finalNbrStep = scaledNbrStep;
    }

    final finalTotalMax = values.fold<num>(0, (s, v) => s + v).toInt();
    
    // Update state with setState
    setState(() {
      maxY = finalMaxY;
      nbrStep = finalNbrStep;
      _totalMax = finalTotalMax;
    });
  }

  @override
  void dispose() {
    if (_ownsController) _c.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnimatedWeeklyStats oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.values, widget.values)) {
      // If the new values are empty, try loading from the service
      if (_areValuesEmpty(widget.values)) {
        _loadValuesIfNeeded().then((loadedValues) {
          if (mounted) {
            setState(() {
              _currentValues = loadedValues;
            });
            _recomputeScale(loadedValues);
            if (_ownsController) _c.forward(from: 0);
          }
        });
      } else {
        setState(() {
          _currentValues = widget.values;
        });
        _recomputeScale(widget.values);          // <-- recompute axis
        if (_ownsController) _c.forward(from: 0);
      }
    }
  }
  void _recomputeScale(List<num> values) {
    if (kDebugMode) {
      debugPrint('_recomputeScale called with values: $values');
    }
    // maxValue
    final maxValue = (values.isEmpty ? 1 : values.fold<num>(0, (m, v) => v > m ? v : m)).toInt();
    if (kDebugMode) {
      debugPrint('_recomputeScale - maxValue calculated: $maxValue');
    }

    int desiredMaxLabels = 6;
    int newStep = (maxValue / 4).round();
    if (newStep <= 0) newStep = 1;

    int ticks = ((maxValue + newStep - 1) ~/ newStep) + 1;
    while (ticks > desiredMaxLabels) {
      newStep++;
      ticks = ((maxValue + newStep - 1) ~/ newStep) + 1;
    }

    int localMaxY = newStep * ((maxValue + newStep - 1) ~/ newStep);

    const headroomRatio = 0.12;
    int roundUpTo(int x, int s) => ((x + s - 1) ~/ s) * s;
    int scaledMaxY = roundUpTo((localMaxY * (1 + headroomRatio)).ceil(), newStep);
    int scaledNbrStep = (scaledMaxY ~/ newStep) + 1;
    while (scaledNbrStep > desiredMaxLabels) {
      newStep++;
      // Recompute localMaxY with the new step before recomputing scaledMaxY
      localMaxY = newStep * ((maxValue + newStep - 1) ~/ newStep);
      scaledMaxY = roundUpTo((localMaxY * (1 + headroomRatio)).ceil(), newStep);
      scaledNbrStep = (scaledMaxY ~/ newStep) + 1;
    }
    
    if (kDebugMode) {
      debugPrint('_recomputeScale - newStep=$newStep, localMaxY=$localMaxY, scaledMaxY=$scaledMaxY, scaledNbrStep=$scaledNbrStep');
    }

    // guards for all-zero values
    if (scaledMaxY == 0) {
      scaledMaxY = newStep;            // 1 "unit" to avoid 0/0
      scaledNbrStep = (scaledMaxY ~/ newStep) + 1;
    }

    setState(() {
      step = newStep;
      maxY = scaledMaxY;
      nbrStep = scaledNbrStep;
      _totalMax = values.fold<num>(0, (s, v) => s + v).toInt();
      if (kDebugMode) {
        debugPrint('_recomputeScale - setState: maxY=$maxY, nbrStep=$nbrStep, step=$step');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if(widget.onBoarding) AnimatedBuilder(
          animation: _totalAnim,
          builder: (_, __) {
            final mpTot = (_totalAnim.value * _totalMax).round(); // 0 → somme
            return Text(
              "${translate("thisweek", lang)} : $mpTot MP",
              style: TextStyle(
                fontFamily: "InterTight",
                fontSize: 20 * xFact,
                color: appTheme.onBackground,
              ),
            );
          },
        ),
        widget.onBoarding ? SizedBox(
          height: 0*yFact,
        ) : SizedBox(
          height: 25*yFact,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: widget.onBoarding ? 130*yFact : 180*yFact,
              width: 20*xFact,
              margin: EdgeInsets.only(top: 10*yFact),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  nbrStep, // nombre d'étapes
                      (i) {
                    // Invert to get increasing values from 0 to maxY (bottom to top)
                    // Capture current values to avoid closure issues
                    final currentMaxY = maxY;
                    final currentStep = step;
                    final currentNbrStep = nbrStep;
                    final value = (currentNbrStep - 1 - i) * currentStep;
                    if (kDebugMode && i == 0) {
                      debugPrint('Label generation - currentMaxY=$currentMaxY, currentStep=$currentStep, currentNbrStep=$currentNbrStep, first value=$value (i=0), last value=${(currentNbrStep - 1) * currentStep}');
                    }
                    return FittedBox(
                      child: Text(
                        "$value",
                        style: TextStyle(
                          fontFamily: "InterTight",
                          fontSize: 12 * xFact,
                          color: appTheme.onBackground,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              width: 5*xFact,
            ),
            Stack(
              children: [
                Align(
                  alignment: AlignmentGeometry.topCenter,
                  child: Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 11*yFact,left: 2*xFact),
                        height: widget.onBoarding ? 128*yFact : 178*yFact,
                        width: widget.onBoarding ? 196*xFact : 250*xFact,
                        child: DottedLinesBackground(
                          lineColor: appTheme.onBackgroundSub,
                          lineCount: nbrStep, // nombre de lignes
                          dashWidth: 6*yFact,
                          dashSpace: 4*xFact,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 10*yFact),
                        height:  widget.onBoarding ? 130*yFact : 180*yFact,
                        width: widget.onBoarding ? 200*xFact : 252*xFact,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: appTheme.onBackground,
                              width: 2*xFact,
                            ),
                            bottom: BorderSide(
                              color: appTheme.onBackground,
                              width: 2*yFact,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top : 10*yFact),
                  height: widget.onBoarding ? 128*yFact : 178*yFact,
                  width: widget.onBoarding ? 200*xFact : 255*xFact,
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (_, __) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          // Capture the current maxY value to avoid closure issues
                          final currentMaxY = maxY;
                          final currentStep = step;
                          final currentNbrStep = nbrStep;

                          final barsCount = widget.nbrLabels;
                          final values = List<double>.generate(
                            barsCount,
                            (index) => index < _currentValues.length
                                ? _currentValues[index].toDouble()
                                : 0,
                          );
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(barsCount, (i) {
                              final anim = _anims[i % _anims.length];
                              final progress = anim.value; // 0 → 1 avec la même courbe/stagger
                              final rawValue = values[i];
                              final displayed = math.min(
                                rawValue.toInt(),
                                (rawValue * progress).round(),
                              );

                              // Compute proportional height: (value / maxY) * available height
                              // If maxY = 10 and value = 1, then height = (1/10) * maxHeight = 10% of the height
                              final maxHeight = constraints.maxHeight;
                              final heightRatio = currentMaxY == 0 ? 0.0 : (rawValue / currentMaxY);
                              final targetHeight = heightRatio * maxHeight;
                              // Animate height from 0 to targetHeight based on progress
                              final h = (targetHeight * progress).clamp(0.0, maxHeight);


                              return _Bar(
                                height: h,
                                color: appTheme.onPrimButtonGold,
                                value: displayed,
                              );
                            }),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.height,
    required this.color,
    required this.value,
  });

  final double height;
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) {
    final xFact = ScreenScale.x;
    final yFact = ScreenScale.y;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          "$value",
          style: TextStyle(
            color: appTheme.onBackground,
            fontSize: 12*xFact,
          ),
        ),
        SizedBox(height: 0*yFact),
        Container(
          width: 28*xFact,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(6*xFact),topRight: Radius.circular(6*xFact)),
          ),
        ),
      ],
    );
  }
}
