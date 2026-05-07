import 'package:flutter/material.dart';

import 'package:businessmindset/app/globals/app_theme_globals.dart' show appTheme;

/// Lightweight model paired with [PointIncrementWidget] to render a "+1"
/// floating animation when the user earns a Mindset Point.
class PointIncrementAnimation {
  PointIncrementAnimation({
    required this.key,
    required this.type,
    required this.controller,
  });

  final Key key;
  final String type;
  final AnimationController controller;
}

/// Floating "+1" indicator that drifts upwards while fading out.
/// The motion is driven by [PointIncrementAnimation.controller].
class PointIncrementWidget extends StatelessWidget {
  const PointIncrementWidget({
    super.key,
    required this.animation,
    required this.xFact,
    required this.yFact,
  });

  final PointIncrementAnimation animation;
  final double xFact;
  final double yFact;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation.controller,
      builder: (context, child) {
        final progress = animation.controller.value;
        final offsetY = -60 * yFact * progress;
        final opacity = 1.0 - progress;

        return Positioned(
          right: -30 * xFact,
          top: 10 * yFact + offsetY,
          child: Opacity(
            opacity: opacity,
            child: Text(
              '+1',
              style: TextStyle(
                color: appTheme.onPrimButtonGold,
                fontSize: 18 * xFact,
                fontWeight: FontWeight.bold,
                fontFamily: 'InterTight',
              ),
            ),
          ),
        );
      },
    );
  }
}
