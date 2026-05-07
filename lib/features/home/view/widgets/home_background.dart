import 'dart:io';

import 'package:flutter/material.dart';

import 'package:businessmindset/utils/image_utils.dart';

/// Fond d’écran Home (dégradés, couleur unie, image asset ou fichier custom).
class HomeBackground extends StatelessWidget {
  const HomeBackground({
    super.key,
    required this.theme,
    required this.isCustom,
  });

  final Map<String, dynamic> theme;
  final bool isCustom;

  @override
  Widget build(BuildContext context) {
    final isImage = theme['isImage'] == true;
    final imageName = theme['imageName'] as String?;

    if (!isImage) {
      final color1 = Color(theme['color1'] as int);
      final color2 =
          theme['color2'] != null ? Color(theme['color2'] as int) : null;
      final color3 =
          theme['color3'] != null ? Color(theme['color3'] as int) : null;
      final nbrcolor = theme['nbrcolor'] as int? ?? 1;
      final p1 = (theme['p1'] as num?)?.toDouble() ?? 0.0;
      final p2 = (theme['p2'] as num?)?.toDouble() ?? 0.0;
      final p3 = (theme['p3'] as num?)?.toDouble() ?? 0.0;

      if (nbrcolor == 1) {
        return Container(color: color1);
      }
      if (nbrcolor == 2 && color2 != null) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color1, color2],
              stops: [p1, p2],
            ),
          ),
        );
      }
      if (nbrcolor == 3 && color2 != null && color3 != null) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color1, color2, color3],
              stops: [p1, p2, p3],
            ),
          ),
        );
      }
      return Container(color: color1);
    }

    if (imageName == null || imageName.isEmpty) {
      return Container(color: Color(theme['color1'] as int));
    }

    final offsetX = (theme['imageOffsetX'] as num?)?.toDouble() ?? 0.0;
    final offsetY = (theme['imageOffsetY'] as num?)?.toDouble() ?? 0.0;

    if (isCustom) {
      final validPath = getValidImagePath(imageName);
      if (validPath != null) {
        final file = File(validPath);
        if (file.existsSync()) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Color(theme['color1'] as int)),
              Image.file(
                file,
                fit: BoxFit.cover,
                alignment: Alignment(offsetX, offsetY),
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Color(theme['color1'] as int));
                },
              ),
            ],
          );
        }
      }
      return Container(color: Color(theme['color1'] as int));
    }

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/backgrounds/$imageName'),
          fit: BoxFit.cover,
          alignment: Alignment(offsetX, offsetY),
        ),
      ),
    );
  }
}
