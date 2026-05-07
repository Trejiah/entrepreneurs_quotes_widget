import 'package:flutter/material.dart';
import 'app_color.dart';

final AppColors defaultTheme = AppColors(
  background: const Color(0xFF1f1f1f),
  onBackground: const Color(0xFFfff9ee),
  onBackgroundSub: const Color(0xFFb4ac9c),

  onPrimButtonGold: Color(0xFFeca70b),
  lowButtonGold: Color(0xFFffe19a),
  primButtonGradient: const AppPaintable.gradient(
    LinearGradient(
      colors: [Color(0xFFffe19a), Color(0xFFfdd16f), Color(0xFFeca70b)],
      stops: [0,0.3,1],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
  ),
  onPrimButton: Color(0xFF1f1f1f),
  containerPrimButton: const Color(0xFFef9b2b),

  secButtonGradient: const AppPaintable.color(Color(0xFFf8ecd3)),
  secButton: const Color(0xFFf8ecd3),
  onSecButton: const Color(0xFF1f1f1f),
  containerSecButton: const Color(0xFFb8c187),

  tertButtonGradient: const AppPaintable.color(Color(0x00b8c187)),
  onTertButton: const Color(0xFFfff9ee),
  containerTertButton: const Color(0xFFfff9ee),

  textField: const Color(0xFF504b41),
  onTextField: const Color(0xFFbaac9c),
  containerTextField: const Color(0xFFfff9ee),

  settingsButton : const Color(0xFF333333)
);

// Example of a second theme
final AppColors oceanTheme = AppColors(
  background: const Color(0xFFfaecd6),
  onBackground: const Color(0xFF2e505b),
  lowButtonGold: Color(0xFFffe19a),
  primButtonGradient: const AppPaintable.gradient(
    LinearGradient(
      colors: [Color(0xFFef9b2b), Color(0xFFb86d00)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
  onPrimButton: Colors.white,
  containerPrimButton: const Color(0xFFef9b2b),

  secButtonGradient: const AppPaintable.color(Color(0xFFb8c187)),
  secButton: const Color(0xFFf8ecd3),
  onSecButton: const Color(0xFF2a5225),
  containerSecButton: const Color(0xFFb8c187),

  tertButtonGradient: const AppPaintable.color(Color(0xFFb8c187)),
  onTertButton: Colors.white,
  containerTertButton: const Color(0xFF2e505b),

  textField: const Color(0xFFccd8cd),
  onTextField: const Color(0xFF2e505b),
  containerTextField: const Color(0xFFdde5d9),
  onBackgroundSub: const Color(0xFFb4ac9c),
  onPrimButtonGold: const Color(0xFFeca70b),
    settingsButton : const Color(0xFF333333)
);

/// Registre global
final Map<String, AppColors> appThemes = {
  'default': defaultTheme,
  'ocean': oceanTheme,
};
