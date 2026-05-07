// core/screen_scale.dart
import 'dart:math';

import 'package:flutter/widgets.dart';

class ScreenScale {
  static double x = 1.0;
  static double y = 1.0;

  static const double _minScale = 0.80;  // pour petits téléphones
  static const double _maxScale = 1.30;  // limite sur tablettes/iPad

  static bool _initialized = false;

  /// Returns true if we actually applied a valid scale.
  /// Skips the init (leaves x = y = 1.0) if the logical size is not usable yet,
  /// which happens in profile/release on Android when the view hasn't finished
  /// its initial layout. Caller should retry later in that case.
  static bool init({
    required Size logicalSize,
    double baseWidth = 392.72727272727275,  // your design width
    double baseHeight = 829.0909090909091, // your design height
  }) {
    if (logicalSize.width <= 1 || logicalSize.height <= 1) {
      return false;
    }

    final rawX = logicalSize.width / baseWidth;
    final rawY = logicalSize.height / baseHeight;

    x = rawX.clamp(_minScale, _maxScale);
    y = rawY.clamp(_minScale, _maxScale);
    _initialized = true;
    return true;
  }

  static bool get isInitialized => _initialized;

  /// Helper if you want balanced scaling (optional)
  static double get uniform => min(x, y);
}
