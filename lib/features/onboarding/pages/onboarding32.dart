import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:businessmindset/features/onboarding/domain/onboarding_radar_domain.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/habits_provider.dart';

class OnBoarding32 extends ConsumerStatefulWidget {
  const OnBoarding32({
    super.key,
    this.forward,
  });
  final VoidCallback? forward;

  @override
  ConsumerState<OnBoarding32> createState() => _OnBoarding32State();
}

class _OnBoarding32State extends ConsumerState<OnBoarding32> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  
  // Initial percentages (saved)
  final Map<String, double> _initialPercentages = {};
  // Absolute axis values (0-100) for display
  Map<String, double> _axisValues = {};
  // Proportionally computed percentages (for saving)
  final Map<String, double> _calculatedPercentages = {};
  // Indicates whether changes were made
  bool _hasChanges = false;
  // Point currently being moved (null if none)
  String? _draggingPoint;
  // Fixed max value for the visual scale (based on initial values)
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
    // Initialize with valid default values (25% each)
    for (var key in _categoryKeys) {
      _initialPercentages[key] = 25.0;
      _axisValues[key] = 25.0;
    }
    _loadSavedPercentages();
  }

  Future<void> _loadSavedPercentages() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Load the initial percentages (they will never change)
    for (var key in _categoryKeys) {
      final percentage = prefs.getDouble("plan_${key}_percentage");
      if (percentage != null && percentage >= 10.0 && percentage <= 100.0) {
        _initialPercentages[key] = percentage;
      } else {
        // Default value if not saved or invalid
        _initialPercentages[key] = 25.0;
      }
    }
    
    // 2. Compute the fixed max value for the visual scale = max of initial percentages
    // This value will never change and defines the scale of all axes
    if (_initialPercentages.isNotEmpty) {
      _maxAxisValue = _initialPercentages.values.reduce((a, b) => a > b ? a : b);
    } else {
      _maxAxisValue = 100.0;
    }
    
    // 3. Initialize axis values with the initial percentages
    // These values will change during drag, but the max scale stays fixed
    for (var key in _categoryKeys) {
      _axisValues[key] = _initialPercentages[key] ?? 0.0;
    }
    
    _updateCalculatedPercentages();
    
    if (kDebugMode) {
      debugPrint("═══════════════════════════════════════════════════════════");
      debugPrint("📊 [OnBoarding32] LOADED VALUES:");
      debugPrint("═══════════════════════════════════════════════════════════");
      debugPrint("  📏 Valeur max fixe pour l'échelle: ${_maxAxisValue.toStringAsFixed(2)}");
      for (var key in _categoryKeys) {
        final initial = _initialPercentages[key] ?? 0.0;
        final axis = _axisValues[key] ?? 0.0;
        final calculated = _calculatedPercentages[key] ?? 0.0;
        debugPrint("  $key:");
        debugPrint("    • Initial (saved): ${initial.toStringAsFixed(2)}%");
        debugPrint("    • Axis value: ${axis.toStringAsFixed(2)}");
        debugPrint("    • Computed percentage: ${calculated.toStringAsFixed(2)}%");
      }
      debugPrint("═══════════════════════════════════════════════════════════\n");
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  void _updateCalculatedPercentages() {
    final next = proportionalPercentagesFromAxisValues(_axisValues, _categoryKeys);
    _calculatedPercentages
      ..clear()
      ..addAll(next);

    if (kDebugMode) {
      final totalAxis = _axisValues.values.fold(0.0, (a, b) => a + b);
      debugPrint("📊 [OnBoarding32] Computed percentages:");
      debugPrint("  Total axis values: ${totalAxis.toStringAsFixed(2)}");
      for (var entry in _calculatedPercentages.entries) {
        final axisVal = _axisValues[entry.key] ?? 0.0;
        debugPrint("  ${entry.key}: axis=${axisVal.toStringAsFixed(1)}, computed=${entry.value.toStringAsFixed(2)}%");
      }
    }
  }

  void _onPointDragged(String categoryKey, double newValue) {
    // Clamp between 0 and the fixed max value (based on initial values)
    final clampedValue = newValue.clamp(0.0, _maxAxisValue);
    final oldValue = _axisValues[categoryKey] ?? 0.0;
    
    // Reduce the threshold for better responsiveness (0.01 instead of 0.1)
    if ((clampedValue - oldValue).abs() < 0.01) return;
    
    _axisValues[categoryKey] = clampedValue;
    _updateCalculatedPercentages();
    
    // Check whether changes were made
    _hasChanges = _axisValues.entries.any((entry) {
      final initial = _initialPercentages[entry.key] ?? 0.0;
      return (entry.value - initial).abs() > 0.1;
    });
    
    // Logs only at end of drag (in onPanEnd) to avoid latency
    setState(() {});
  }

  void _resetToInitial() {
    setState(() {
      _axisValues = Map.from(_initialPercentages);
      _updateCalculatedPercentages();
      _hasChanges = false;
    });
    
    if (kDebugMode) {
      debugPrint("🔄 [OnBoarding32] Reset to initial values");
    }
  }

  Future<void> _saveAndForward() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save the computed percentages (not the axis values)
    for (var entry in _calculatedPercentages.entries) {
      await prefs.setDouble("plan_${entry.key}_percentage", entry.value);
    }
    
    if (kDebugMode) {
      debugPrint("💾 [OnBoarding32] New percentages saved:");
      for (var entry in _calculatedPercentages.entries) {
        debugPrint("  ${entry.key}: ${entry.value.toStringAsFixed(2)}%");
      }
    }
    
    if (widget.forward != null) {
      widget.forward!();
    }
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
        child: Builder(
          builder: (context) {
            // Enable scroll only if text scale > 1.2
            final textScale = MediaQuery.of(context).textScaler.scale(1.0);
            final shouldEnableScroll = textScale > 1.2;
            
            final content = Padding(
              padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
              child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$userName's ${translate("plan_title", lang)}",
                      style: TextStyle(
                        fontFamily: "YesevaOne",
                        fontSize: 28 * xFact,
                        color: appTheme.onBackground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10 * yFact),
                    // Image Flamy podium
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
                    SizedBox(height: 10 * yFact),
                    // Texte d'introduction
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
                  ],
                ),
                SizedBox(height: 10 * yFact),
                Column(
                  children: [
                    // Diagramme spider
                    SizedBox(
                      height: 330 * yFact,
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
                          // Logs en fin de drag seulement
                          if (kDebugMode) {
                            debugPrint("📊 [OnBoarding32] AFTER MODIFICATION:");
                            for (var key in _categoryKeys) {
                              final axis = _axisValues[key] ?? 0.0;
                              final calculated = _calculatedPercentages[key] ?? 0.0;
                              debugPrint("  $key:");
                              debugPrint("    • Axis value: ${axis.toStringAsFixed(2)}");
                              debugPrint("    • Computed percentage: ${calculated.toStringAsFixed(2)}%");
                            }
                            debugPrint("");
                          }
                          setState(() {
                            _draggingPoint = null;
                          });
                        },
                        draggingKey: _draggingPoint,
                      ),
                    ),
                    // Reset button (shown only if changes were made)
                  ],
                ),
                Column(
                  children: [_hasChanges ?
                  Padding(
                    padding: EdgeInsets.only(bottom: 20 * yFact),
                    child: Center(
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
                    ),
                  ) : SizedBox(height: 20*yFact,),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 30 * yFact),
                        child: PrimaryButton(
                          text: translate("start_now", lang),
                          icon: Icons.arrow_right_alt,
                          iconSize: 40 * xFact,
                          onTap: _saveAndForward,
                        ),
                      ),
                    ),
                  ],
                )
                // Bouton Start Now
                ],
              ),
            );
            
            // Return with or without scroll depending on textScale
            if (shouldEnableScroll) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: content,
                ),
              );
            } else {
              return content;
            }
          },
        ),
      ),
    );
  }

}

// Widget for the spider chart
class _SpiderChart extends StatefulWidget {
  final Map<String, double> axisValues;
  final List<String> categoryKeys;
  final Map<String, String> categoryNameKeys;
  final Function(String, double) onPointDragged;
  final Function(String) onDragStart;
  final VoidCallback onDragEnd;
  final String? draggingKey;
  final String lang; // Ajout de la langue pour les traductions
  final double maxAxisValue; // Valeur max fixe pour l'échelle visuelle

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
  double? _dragStartValue; // Valeur initiale au début du drag
  double _accumulatedDelta = 0.0; // Delta accumulé depuis le début du drag
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
            // Draggable points - each point is a Container with a GestureDetector
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
                left: pointX - 12.5 * xFact, // Zone de touch plus large
                top: pointY - 12.5 * xFact,
                child: GestureDetector(
                  onPanStart: (details) {
                    if (kDebugMode) {
                      debugPrint("👆 [OnBoarding32] Touch detected on point: $key");
                    }
                    setState(() {
                      _localDraggingKey = key;
                      // Save the current value at the start of the drag
                      _dragStartValue = widget.axisValues[key] ?? 0.0;
                      _accumulatedDelta = 0.0;
                    });
                    widget.onDragStart(key);
                  },
                  onPanUpdate: (details) {
                    if (_localDraggingKey == key && _dragStartValue != null) {
                      // Calculer l'angle de l'axe
                      final angle = (i * 2 * math.pi / widget.categoryKeys.length) - (math.pi / 2);

                      // Project the motion delta onto the axis
                      // The delta is in pixels, we must convert it to an axis value
                      final axisDx = math.cos(angle);
                      final axisDy = math.sin(angle);
                      final deltaProjection = details.delta.dx * axisDx + details.delta.dy * axisDy;

                      // Convert pixel delta to value delta
                      // If radius pixels = maxValue, then 1 pixel = maxValue / radius
                      final deltaValue = (deltaProjection / radius) * maxValue;

                      // Accumulate the delta
                      _accumulatedDelta += deltaValue;

                      // Compute the new value from initial value + accumulated delta
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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    // Point visible
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
            // Icons at the ends of the axes
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
            // Category texts (after icons and GestureDetector so they are visible)
            ...widget.categoryKeys.asMap().entries.map((entry) {
              final i = entry.key;
              final key = entry.value;
              final angle = (i * 2 * math.pi / widget.categoryKeys.length) - (math.pi / 2);
              final iconX = center.dx + (radius + 20 * xFact) * math.cos(angle);
              final iconY = center.dy + (radius + 20 * xFact) * math.sin(angle);
              
              final categoryName = translate(widget.categoryNameKeys[key]!, widget.lang);
              final textOffset = 0 * xFact; // Distance entre l'icône et le texte
              
              // Text based on position
              if (key == 'growth') {
                // Above the icon
                return Positioned(
                  left: iconX - 60 * xFact,
                  top: iconY - 40 * xFact - textOffset,
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
                // Below the icon
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
                  left: iconX - 15 * xFact - 16 * xFact,
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
                    )
                );
              } else if (key == 'discipline') {
                // Right-aligned, under the icon
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
  final double maxAxisValue; // Valeur max pour l'échelle visuelle
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
    final radius = math.min(size.width, size.height) / 2 - 80 * xFact;
    
    // Draw grid lines based on maxAxisValue
    final gridPaint = Paint()
      ..color = appTheme.onBackgroundSub.withValues(alpha: 0.3)
      ..strokeWidth = 0.5 * xFact;
    
    // Compute grid values based on maxAxisValue
    final gridSteps = [0.25, 0.5, 0.75, 1.0];
    for (var step in gridSteps) {
      final gridValue = maxAxisValue * step;
      final gridRadius = (gridValue / maxAxisValue) * radius;
      canvas.drawCircle(center, gridRadius, gridPaint);
    }
    
    // Draw the main axes
    final axisPaint = Paint()
      ..color = appTheme.onBackgroundSub
      ..strokeWidth = 1 * xFact;
    
    for (var i = 0; i < categoryKeys.length; i++) {
      final angle = (i * 2 * math.pi / categoryKeys.length) - (math.pi / 2);
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);
      
      canvas.drawLine(center, Offset(endX, endY), axisPaint);
    }
    
    // Draw the polygon
    final polygonPath = Path();
    final points = <Offset>[];
    
    for (var i = 0; i < categoryKeys.length; i++) {
      final key = categoryKeys[i];
      final value = axisValues[key] ?? 0.0;
      final angle = (i * 2 * math.pi / categoryKeys.length) - (math.pi / 2);
      // Use maxAxisValue for the visual scale (but value stays 0-100)
      final pointRadius = (value / maxAxisValue) * radius;
      final pointX = center.dx + pointRadius * math.cos(angle);
      final pointY = center.dy + pointRadius * math.sin(angle);
      final point = Offset(pointX, pointY);
      points.add(point);
      
      if (i == 0) {
        polygonPath.moveTo(pointX, pointY);
      } else {
        polygonPath.lineTo(pointX, pointY);
      }
    }
    polygonPath.close();
    
    // Fill the polygon
    final fillPaint = Paint()
      ..color = appTheme.onPrimButtonGold.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawPath(polygonPath, fillPaint);
    
    // Draw the polygon outline
    final strokePaint = Paint()
      ..color = appTheme.onPrimButtonGold
      ..strokeWidth = 2 * xFact
      ..style = PaintingStyle.stroke;
    canvas.drawPath(polygonPath, strokePaint);
    
    // Points are now separate widgets, no need to draw them here
  }

  @override
  bool shouldRepaint(_SpiderChartPainter oldDelegate) {
    return oldDelegate.axisValues != axisValues || oldDelegate.draggingKey != draggingKey;
  }
}

