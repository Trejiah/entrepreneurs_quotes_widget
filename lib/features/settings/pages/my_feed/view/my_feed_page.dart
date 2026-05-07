import 'dart:math' as math;
import 'package:businessmindset/features/settings/pages/my_feed/view_model/my_feed_provider.dart';
import 'package:businessmindset/features/settings/pages/my_feed/view_model/my_feed_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:businessmindset/features/settings/pages/retake_test_flow/view/retake_test_flow_page.dart';

class MyFeed extends ConsumerStatefulWidget {
  const MyFeed({super.key});

  @override
  ConsumerState<MyFeed> createState() => _MyFeedState();
}

class _MyFeedState extends ConsumerState<MyFeed> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myFeedViewModelProvider.notifier).loadSavedPercentages();
    });
  }

  Future<void> _save() async {
    await ref.read(myFeedViewModelProvider.notifier).save();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final vmState = ref.watch(myFeedViewModelProvider);
    final vm = ref.read(myFeedViewModelProvider.notifier);

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
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 10 * xFact),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(Icons.arrow_back_ios,
                              color: appTheme.onBackground, size: 30 * xFact),
                        ),
                        SizedBox(width: 5 * xFact),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              translate("personalized_feed", lang),
                              style: TextStyle(
                                fontFamily: "YesevaOne",
                                color: appTheme.onBackground,
                                fontSize: 35 * xFact,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10 * yFact),
                    Padding(
                      padding: EdgeInsets.only(left: 20 * xFact, right: 20 * xFact),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          translate("plan_intro_subtext", lang),
                          style: TextStyle(
                            fontFamily: "InterTight",
                            fontSize: 18 * xFact,
                            color: appTheme.onBackgroundSub,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10 * yFact),
                SizedBox(
                  height: 350 * yFact,
                  child: _SpiderChart(
                    axisValues: vmState.axisValues,
                    categoryKeys: MyFeedViewModel.categoryKeys,
                    categoryNameKeys: MyFeedViewModel.categoryNameKeys,
                    lang: lang,
                    maxAxisValue: vmState.maxAxisValue,
                    onPointDragged: vm.onPointDragged,
                    onDragStart: vm.setDraggingPoint,
                    onDragEnd: () {
                      if (kDebugMode) {
                        final state = ref.read(myFeedViewModelProvider);
                        debugPrint("📊 [MyFeed] AFTER MODIFICATION:");
                        for (final key in MyFeedViewModel.categoryKeys) {
                          final axis = state.axisValues[key] ?? 0.0;
                          final calculated = state.calculatedPercentages[key] ?? 0.0;
                          debugPrint("  $key:");
                          debugPrint("    • Axis value: ${axis.toStringAsFixed(2)}");
                          debugPrint(
                            "    • Computed percentage: ${calculated.toStringAsFixed(2)}%",
                          );
                        }
                        debugPrint("");
                      }
                      vm.setDraggingPoint(null);
                    },
                    draggingKey: vmState.draggingPoint,
                  ),
                ),
                SizedBox(
                  height: 10 * yFact,
                ),
                Column(
                  children: [
                    vmState.hasChanges
                        ? Padding(
                            padding: EdgeInsets.only(bottom: 20 * yFact),
                            child: Center(
                              child: GestureDetector(
                                onTap: vm.resetToInitial,
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
                            ),
                          )
                        : SizedBox(height: 48 * yFact),
                    Padding(
                      padding: EdgeInsets.only(right: 20 * xFact, left: 20 * xFact),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SecondaryButton(
                          text: translate("save", lang),
                          onTap: _save,
                        ),
                      ),
                    ),
                    SizedBox(height: 15 * yFact),
                    Padding(
                      padding:
                          EdgeInsets.only(right: 20 * xFact, left: 20 * xFact, bottom: 30 * yFact),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          onTap: () async {
                            final navigator = Navigator.of(context);
                            final result = await navigator.push(
                              MaterialPageRoute(
                                builder: (context) => const RetakeTestFlow(),
                              ),
                            );
                            if (result == true) {
                              await vm.loadSavedPercentages();
                              if (!mounted) return;
                              navigator.pop(true);
                            }
                          },
                          child: Text(
                            translate("retake_the_test", lang),
                            style: TextStyle(
                              fontFamily: "InterTight",
                              fontSize: 18 * xFact,
                              color: appTheme.onBackground,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpiderChart extends StatefulWidget {
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

  final Map<String, double> axisValues;
  final List<String> categoryKeys;
  final Map<String, String> categoryNameKeys;
  final Function(String, double) onPointDragged;
  final Function(String) onDragStart;
  final VoidCallback onDragEnd;
  final String? draggingKey;
  final String lang;
  final double maxAxisValue;

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
        final radius = math.min(size.width, size.height) / 2 - 80 * xFact;
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
                left: pointX - 12.5 * xFact,
                top: pointY - 12.5 * xFact,
                child: GestureDetector(
                  onPanStart: (details) {
                    if (kDebugMode) {
                      debugPrint("👆 [MyFeed] Touch detected on point: $key");
                    }
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
                    width: 25 * xFact,
                    height: 25 * xFact,
                    decoration: const BoxDecoration(
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
                          boxShadow: isDragging
                              ? [
                                  BoxShadow(
                                    color: appTheme.onPrimButtonGold.withValues(alpha: 0.3),
                                    blurRadius: 8 * xFact,
                                    spreadRadius: 4 * xFact,
                                  ),
                                ]
                              : null,
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

              if (key == 'growth') {
                return Positioned(
                  left: iconX - 60 * xFact,
                  top: iconY - 45 * xFact,
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
                  top: iconY + 14 * xFact,
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
                  left: iconX - 34 * xFact,
                  top: iconY + 15 * xFact,
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
                  top: iconY + 15 * xFact,
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
              return const SizedBox.shrink();
            }),
          ],
        );
      },
    );
  }
}

class _SpiderChartPainter extends CustomPainter {
  _SpiderChartPainter({
    required this.axisValues,
    required this.categoryKeys,
    this.draggingKey,
    required this.maxAxisValue,
    required this.xFact,
    required this.yFact,
  });

  final Map<String, double> axisValues;
  final List<String> categoryKeys;
  final String? draggingKey;
  final double maxAxisValue;
  final double xFact;
  final double yFact;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 80 * xFact;

    final gridPaint = Paint()
      ..color = appTheme.onBackgroundSub.withValues(alpha: 0.3)
      ..strokeWidth = 0.5 * xFact;

    final gridSteps = [0.25, 0.5, 0.75, 1.0];
    for (final step in gridSteps) {
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

