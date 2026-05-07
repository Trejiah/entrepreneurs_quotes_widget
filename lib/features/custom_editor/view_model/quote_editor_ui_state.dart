import 'package:flutter/material.dart';

/// État UI de l’éditeur de citation / thème personnalisé.
class QuoteEditorUiState {
  const QuoteEditorUiState({
    required this.bgColor,
    required this.citationColor,
    required this.fontFamily,
    this.backgroundImagePath,
    this.isImageBackground = false,
    this.imageOffsetX = 0.0,
    this.imageOffsetY = 0.0,
  });

  final Color bgColor;
  final Color citationColor;
  final String? backgroundImagePath;
  final String fontFamily;
  final bool isImageBackground;
  final double imageOffsetX;
  final double imageOffsetY;

  static const Object _unset = Object();

  QuoteEditorUiState copyWith({
    Color? bgColor,
    Color? citationColor,
    String? fontFamily,
    Object? backgroundImagePath = _unset,
    bool? isImageBackground,
    double? imageOffsetX,
    double? imageOffsetY,
  }) {
    return QuoteEditorUiState(
      bgColor: bgColor ?? this.bgColor,
      citationColor: citationColor ?? this.citationColor,
      fontFamily: fontFamily ?? this.fontFamily,
      backgroundImagePath: identical(backgroundImagePath, _unset)
          ? this.backgroundImagePath
          : backgroundImagePath as String?,
      isImageBackground: isImageBackground ?? this.isImageBackground,
      imageOffsetX: imageOffsetX ?? this.imageOffsetX,
      imageOffsetY: imageOffsetY ?? this.imageOffsetY,
    );
  }
}
