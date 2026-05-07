import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/providers/language_provider.dart';

class OnBoarding29 extends ConsumerStatefulWidget {
  const OnBoarding29({
    super.key,
    this.forward,
  });
  final VoidCallback? forward;

  @override
  ConsumerState<OnBoarding29> createState() => _OnBoarding29State();
}

enum _ProgressStyle { freeze, jump, slowAdvance, fastAdvance }

class _ProgressSegment {
  final _ProgressStyle style;
  final double duration; // Durée du segment en secondes
  final double? jumpAmount; // Pour les sauts : montant du saut (0-1)
  final double? speed; // Pour les avances : vitesse de progression par seconde

  _ProgressSegment({
    required this.style,
    required this.duration,
    this.jumpAmount,
    this.speed,
  });
}

class _OnBoarding29State extends ConsumerState<OnBoarding29> with SingleTickerProviderStateMixin {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  late AnimationController _controller;
  Timer? _textTimer;
  Timer? _phase3TimeoutTimer;
  String _currentText = "";
  double _progress = 0.0;
  final Random _random = Random();
  List<_ProgressSegment>? _segments;
  bool _hasAdvanced = false;

  // Timing en secondes
  static const double _phase1End = 4.0;
  static const double _phase2End = 8.0;
  static const double _phase3End = 12.0;
  static const double _phase3MaxDuration = 14.0; // Durée max de la phase 3 avant timeout
  
  // Parameters for the jerky phase
  static const double _maxJump = 0.05; // Saut max de 15% de progression
  static const double _minSpeed = 0.05; // Vitesse min (5% par seconde)
  static const double _maxSpeed = 0.25; // Vitesse max (25% par seconde)
  static const int _minSegments = 10; // Nombre minimum de segments
  static const int _maxSegments = 20; // Nombre maximum de segments

  @override
  void initState() {
    super.initState();
    // Generate segments for the jerky phase
    _generateSegments();
    
    // Compute the total duration
    final totalDuration = _phase2End + _segments!.fold(0.0, (sum, seg) => sum + seg.duration);
    
    _controller = AnimationController(
      duration: Duration(milliseconds: (totalDuration * 1000).round()),
      vsync: this,
    );

    // Update text and progress
    _controller.addListener(() {
      // Convert the animation value (0-1) to real elapsed time
      final elapsed = _controller.value * totalDuration;
      _updateText(elapsed);
      _updateProgress(elapsed);
      
      // Start the timeout timer when entering phase 3
      if (elapsed >= _phase2End && _phase3TimeoutTimer == null) {
        _phase3TimeoutTimer = Timer(Duration(milliseconds: (_phase3MaxDuration * 1000).round()), () {
          if (mounted && !_hasAdvanced && widget.forward != null) {
            _hasAdvanced = true;
            widget.forward!();
          }
        });
      }
    });

    _controller.forward();
  }

  void _generateSegments() {
    final remainingProgress = 1.0 - (_phase2End / _phase3End); // Progression restante après 2.3s
    final remainingTime = _phase3End - _phase2End; // Temps restant (1.2s)
    
    // Random segment count
    final numSegments = _minSegments + _random.nextInt(_maxSegments - _minSegments + 1);
    
    // Create a list with all styles to ensure they appear at least once
    final allStyles = List<_ProgressStyle>.from(_ProgressStyle.values);
    
    // Add exactly 2 extra freezes (we already have 1 in _ProgressStyle.values)
    allStyles.add(_ProgressStyle.freeze);
    allStyles.add(_ProgressStyle.freeze);
    
    // Add random styles to fill the remaining segments (without freeze)
    final nonFreezeStyles = _ProgressStyle.values.where((s) => s != _ProgressStyle.freeze).toList();
    while (allStyles.length < numSegments) {
      allStyles.add(nonFreezeStyles[_random.nextInt(nonFreezeStyles.length)]);
    }
    // Shuffle to randomize the order
    allStyles.shuffle(_random);
    
    _segments = [];
    double totalDurationUsed = 0.0;
    double totalProgressUsed = 0.0;
    
    for (int i = 0; i < numSegments; i++) {
      final style = allStyles[i];
      final isLast = i == numSegments - 1;
      
      double segmentDuration;
      double? jumpAmount;
      double? speed;
      
      switch (style) {
        case _ProgressStyle.freeze:
          // Freeze: no progression, random duration
          segmentDuration = 0.1 + _random.nextDouble() * 0.9; // 0.1 à 0.4s
          break;
          
        case _ProgressStyle.jump:
          // Jump: instant progression
          segmentDuration = 0.05 + _random.nextDouble() * 0.15; // 0.05 à 0.2s
          if (isLast) {
            // Last segment: use all remaining progression
            jumpAmount = remainingProgress - totalProgressUsed;
          } else {
            jumpAmount = 0.02 + _random.nextDouble() * (_maxJump - 0.02); // 2% à maxJump
          }
          break;
          
        case _ProgressStyle.slowAdvance:
          // Avance lente
          speed = _minSpeed + _random.nextDouble() * (_minSpeed * 0.5); // Entre minSpeed et 1.5*minSpeed
          if (isLast) {
            segmentDuration = (remainingProgress - totalProgressUsed) / speed;
          } else {
            segmentDuration = 0.2 + _random.nextDouble() * 0.3; // 0.2 à 0.5s
          }
          break;
          
        case _ProgressStyle.fastAdvance:
          // Avance rapide
          speed = _maxSpeed * 0.6 + _random.nextDouble() * (_maxSpeed * 0.8); // Entre 70% et 100% de maxSpeed
          if (isLast) {
            segmentDuration = (remainingProgress - totalProgressUsed) / speed;
          } else {
            segmentDuration = 0.1 + _random.nextDouble() * 0.2; // 0.1 à 0.3s
          }
          break;
      }
      
      // Adjust for the last segment if needed
      if (isLast) {
        final remainingTimeForLast = remainingTime - totalDurationUsed;
        if (segmentDuration > remainingTimeForLast) {
          segmentDuration = remainingTimeForLast;
        }
      } else {
        // Make sure we don't exceed the total time
        if (totalDurationUsed + segmentDuration > remainingTime * 0.9) {
          segmentDuration = remainingTime * 0.9 - totalDurationUsed;
        }
      }
      
      _segments!.add(_ProgressSegment(
        style: style,
        duration: segmentDuration,
        jumpAmount: jumpAmount,
        speed: speed,
      ));
      
      totalDurationUsed += segmentDuration;
      if (style == _ProgressStyle.jump && jumpAmount != null) {
        totalProgressUsed += jumpAmount;
      } else if (speed != null) {
        totalProgressUsed += speed * segmentDuration;
      }
    }
    
    // Make sure the last segment completes to 100%
    if (_segments!.isNotEmpty) {
      final lastSegment = _segments!.last;
      final progressNeeded = remainingProgress - (totalProgressUsed - 
        (lastSegment.style == _ProgressStyle.jump ? (lastSegment.jumpAmount ?? 0.0) : 
         (lastSegment.speed != null ? lastSegment.speed! * lastSegment.duration : 0.0)));
      
      if (progressNeeded > 0.001) { // Tolérance pour les erreurs d'arrondi
        // Adjust the last segment to complete
        if (lastSegment.style == _ProgressStyle.jump) {
          _segments![_segments!.length - 1] = _ProgressSegment(
            style: _ProgressStyle.jump,
            duration: lastSegment.duration,
            jumpAmount: (lastSegment.jumpAmount ?? 0.0) + progressNeeded,
          );
        } else if (lastSegment.speed != null) {
          // Adjust the duration to complete the progression
          final additionalDuration = progressNeeded / lastSegment.speed!;
          _segments![_segments!.length - 1] = _ProgressSegment(
            style: lastSegment.style,
            duration: lastSegment.duration + additionalDuration,
            speed: lastSegment.speed,
          );
        }
      }
    }
  }

  void _updateText(double elapsed) {
    String newText;
    if (elapsed < _phase1End) {
      newText = translate("analyzing_answers", ref.read(languageProvider));
    } else if (elapsed < _phase2End) {
      newText = translate("identifying_goals", ref.read(languageProvider));
    } else {
      newText = translate("building_plan", ref.read(languageProvider));
    }

    if (newText != _currentText) {
      setState(() {
        _currentText = newText;
      });
    }
  }

  void _updateProgress(double elapsed) {
    double newProgress;
    
    if (elapsed < _phase2End) {
      // Normal progress until 2.3s
      // At 2.3s, we should be at 2.3/3.5 = 0.657
      newProgress = elapsed / _phase3End;
    } else {
      // After 2.3s, jerky progression
      final progressAtPhase3 = _phase2End / _phase3End;
      final elapsedSincePhase3 = elapsed - _phase2End;
      
      // Find the current segment
      double segmentTimeAccumulated = 0.0;
      double progressAccumulated = 0.0;
      
      for (int i = 0; i < _segments!.length; i++) {
        final segment = _segments![i];
        final segmentEndTime = segmentTimeAccumulated + segment.duration;
        
        if (elapsedSincePhase3 <= segmentEndTime) {
          // We're inside this segment
          final timeInSegment = elapsedSincePhase3 - segmentTimeAccumulated;
          
          switch (segment.style) {
            case _ProgressStyle.freeze:
              // Freeze: no progression
              progressAccumulated = progressAccumulated; // Pas de changement
              break;
              
            case _ProgressStyle.jump:
              // Jump: instant progression at the end of the segment
              if (timeInSegment >= segment.duration * 0.8) {
                // Apply the jump to the end of the segment
                progressAccumulated += segment.jumpAmount ?? 0.0;
              }
              break;
              
            case _ProgressStyle.slowAdvance:
            case _ProgressStyle.fastAdvance:
              // Avance : progression continue
              if (segment.speed != null) {
                progressAccumulated += segment.speed! * timeInSegment;
              }
              break;
          }
          
          break;
        } else {
          // We passed this segment, apply its full progression
          switch (segment.style) {
            case _ProgressStyle.freeze:
              // Rien
              break;
            case _ProgressStyle.jump:
              progressAccumulated += segment.jumpAmount ?? 0.0;
              break;
            case _ProgressStyle.slowAdvance:
            case _ProgressStyle.fastAdvance:
              if (segment.speed != null) {
                progressAccumulated += segment.speed! * segment.duration;
              }
              break;
          }
          segmentTimeAccumulated = segmentEndTime;
        }
      }
      
      // Make sure we reach 100% at the end
      final maxRemainingProgress = 1.0 - progressAtPhase3;
      progressAccumulated = progressAccumulated.clamp(0.0, maxRemainingProgress);
      
      // If we've reached the end of all segments, force to 100%
      if (elapsedSincePhase3 >= _segments!.fold(0.0, (sum, seg) => sum + seg.duration)) {
        newProgress = 1.0;
      } else {
        newProgress = progressAtPhase3 + progressAccumulated;
      }
    }

    setState(() {
      _progress = newProgress.clamp(0.0, 1.0);
      
      // Appeler forward quand on atteint 100%
      if (_progress >= 1.0 && widget.forward != null && !_hasAdvanced) {
        _hasAdvanced = true;
        // Use a small delay to ensure the UI is updated
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted && widget.forward != null) {
            widget.forward!();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textTimer?.cancel();
    _phase3TimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final imagePath = 'assets/images/flamy/flamy_nerd.png';
    
    // Couleur de fond (background)
    final bgColor = appTheme.background;
    // Gray color slightly lighter than the background
    final grayColor = Color.lerp(bgColor, Colors.white, 0.1) ?? bgColor;
    // Couleur gold
    final goldColor = appTheme.onPrimButtonGold;
    
    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top text
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30.0),
                    child: Text(
                      translate("creating_plan", lang),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "YesevaOne",
                        fontSize: 24 * xFact,
                        color: appTheme.onBackground,
                      ),
                    ),
                  ),
                  SizedBox(height: 40 * yFact),
                  // Image with progress ring
                  // Image flamy_nerd
                  SizedBox(
                    width: 280 * xFact,
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 20 * yFact),
                  SizedBox(
                    width: 100 * xFact,
                    height: 100 * yFact,
                    child: CustomPaint(
                      painter: _GradientCircularProgressPainter(
                        progress: _progress,
                        strokeWidth: 8 * xFact,
                        backgroundColor: grayColor,
                        startColor: goldColor,
                        endColor: grayColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 20 * yFact),
                  // Bottom text (changes based on timing)
                  // Fixed height to prevent elements from moving when text wraps to 2 lines
                  SizedBox(
                    height: 80 * yFact, // Hauteur suffisante pour 2 lignes
                    child: Center(
                      child: Text(
                        _currentText.isEmpty
                            ? translate("analyzing_answers", lang)
                            : _currentText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "YesevaOne",
                          fontSize: 20 * xFact,
                          color: appTheme.onBackground,
                        ),
                      ),
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

// Custom painter for the progress ring with gradient
class _GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color startColor;
  final Color endColor;

  _GradientCircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.startColor,
    required this.endColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw the background (full gray ring)
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw the progress with gradient
    if (progress > 0) {
      final startAngle = -3.14159 / 2; // Commencer en haut (12h)
      final sweepAngle = 2 * 3.14159 * progress; // Angle en radians dans le sens horaire
      
      // Draw the arc segment by segment to create the gradient manually
      // This gives us full control over where the gradient starts
      const int segments = 60; // Nombre de segments pour un dégradé fluide
      final segmentAngle = sweepAngle / segments;
      
      for (int i = 0; i < segments; i++) {
        final segmentStartAngle = startAngle + (i * segmentAngle);
        final t = i / segments; // Position dans le dégradé (0 = gris, 1 = gold)
        
        // Interpolate the color from gray to gold
        final color = Color.lerp(endColor, startColor, t) ?? startColor;
        
        final segmentPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
        
        // Draw a small segment of the arc
        canvas.drawArc(
          rect,
          segmentStartAngle,
          segmentAngle,
          false,
          segmentPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.startColor != startColor ||
        oldDelegate.endColor != endColor;
  }
}

