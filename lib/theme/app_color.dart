import 'package:flutter/material.dart';
class AppColors {
  final Color background;
  final Color onBackground;

  final AppPaintable primButtonGradient;
  final Color onPrimButton;
  final Color containerPrimButton;

  final AppPaintable  secButtonGradient;
  final Color secButton;
  final Color onSecButton;
  final Color containerSecButton;

  final AppPaintable tertButtonGradient;
  final Color onTertButton;
  final Color containerTertButton;

  final Color textField;
  final Color onTextField;
  final Color containerTextField;
  final Color onBackgroundSub;
  final Color onPrimButtonGold;

  final Color settingsButton;
  final Color lowButtonGold;


  const AppColors({
    required this.background,
    required this.onBackground,
    required this.primButtonGradient,
    required this.onPrimButton,
    required this.containerPrimButton,
    required this.secButtonGradient,
    required this.secButton,
    required this.onSecButton,
    required this.containerSecButton,
    required this.tertButtonGradient,
    required this.onTertButton,
    required this.containerTertButton,
    required this.textField,
    required this.onTextField,
    required this.containerTextField,
    required this.onBackgroundSub,
    required this.onPrimButtonGold,
    required this.settingsButton,
    required this.lowButtonGold,
  });
}


class AppPaintable {
  final Color? color;
  final Gradient? gradient;

  const AppPaintable.color(this.color) : gradient = null;
  const AppPaintable.gradient(this.gradient) : color = null;

  /// Automatically applies the right property in a BoxDecoration.
  void applyTo(BoxDecoration decoration) {
    // (optional — for future helpers)
  }

  /// Shortcut for debug or dominant color
  Color get mainColor {
    if (color != null) return color!;
    if (gradient != null && gradient!.colors.isNotEmpty) {
      return gradient!.colors.first;
    }
    return Colors.grey;
  }
}
