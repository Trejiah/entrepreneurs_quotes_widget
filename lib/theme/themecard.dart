import 'dart:io';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:flutter/material.dart';

import '../core/global_scaler.dart';
import '../utils/image_utils.dart';

class ThemeCard extends StatefulWidget {
  const ThemeCard({
    super.key,
    required this.onTap,
    required this.onDelete,
    required this.currentTheme,
    required this.isCustom,
    required this.isPremium,
    this.selected = false,
    this.isFree = false,
    this.language = "en",
  });
  final bool isCustom;
  final bool isPremium;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool selected;
  final Map<String,dynamic> currentTheme;
  final bool isFree;
  final String language;

  @override
  State<ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<ThemeCard> {
  ImageProvider? _cachedImageProvider;
  String? _lastImagePath;

  @override
  void didUpdateWidget(ThemeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Do not recreate the ImageProvider if the path hasn't changed
    final newImageName = widget.currentTheme["imageName"] as String?;
    final oldImageName = oldWidget.currentTheme["imageName"] as String?;
    if (newImageName != oldImageName) {
      _cachedImageProvider = null;
      _lastImagePath = null;
    }
  }

  ImageProvider _getImageProvider() {
    final imageTxt = widget.currentTheme["imageName"] as String?;
    final isImage = widget.currentTheme["isImage"] as bool? ?? false;
    
    if (!isImage) {
      return const AssetImage('assets/images/backgrounds/1_skyline.jpg');
    }
    
    if (widget.isCustom && imageTxt != null && imageTxt.isNotEmpty) {
      final validPath = getValidImagePath(imageTxt);
      if (validPath != null && validPath == _lastImagePath && _cachedImageProvider != null) {
        return _cachedImageProvider!;
      }
      if (validPath != null && File(validPath).existsSync()) {
        _lastImagePath = validPath;
        _cachedImageProvider = FileImage(File(validPath));
        return _cachedImageProvider!;
      } else {
        return const AssetImage('assets/images/backgrounds/1_skyline.jpg');
      }
    } else {
      return AssetImage('assets/images/backgrounds/$imageTxt');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.currentTheme;
    final isCustom = widget.isCustom;
    final isPremium = widget.isPremium;
    final selected = widget.selected;
    final isFree = widget.isFree;
    final language = widget.language;
    final onTap = widget.onTap;
    final onDelete = widget.onDelete;
    final color1   = currentTheme["color1"];
    final color2   = currentTheme["color2"];
    final color3   = currentTheme["color3"];
    final p1       = currentTheme["p1"]; // stop 1
    final p2       = currentTheme["p2"]; // stop 2
    final p3       = currentTheme["p3"]; // stop 3
    final nbr      = currentTheme["nbrcolor"];
    final font     = currentTheme["fontfamily"];
    final colorText= currentTheme["fontcolor"];
    final isImage  = currentTheme["isImage"];

    final xFact = ScreenScale.x;
    final yFact = ScreenScale.y;

    final border = Border.all(
      color: selected ? Colors.white : Colors.transparent,
      width: selected ? 2 : 0,
    );

    // Retrieve saved positioning (default 0.0 if not set)
    final offsetX = (currentTheme["imageOffsetX"] as num?)?.toDouble() ?? 0.0;
    final offsetY = (currentTheme["imageOffsetY"] as num?)?.toDouble() ?? 0.0;
    
    // Determine the ImageProvider to use (with cache)
    final imageProvider = _getImageProvider();

    final gradientDecoration = BoxDecoration(
      color: nbr == 1 ? Color(color1) : null,
      gradient: nbr == 2
          ? LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(color1), Color(color2)],
        stops: _stops2(p1, p2),
      )
          : (nbr == 3
          ? LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(color1), Color(color2), Color(color3)],
        stops: _stops3(p1, p2, p3),
      )
          : null),
      borderRadius: BorderRadius.circular(16*xFact),
      border: border,
      boxShadow: [BoxShadow(blurRadius: 6*xFact, offset: Offset(0, 2*xFact), color: Colors.black26)],
    );

    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              isImage
                  ? Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16*xFact),
                        border: border,
                        boxShadow: [BoxShadow(blurRadius: 6*xFact, offset: Offset(0, 2*xFact), color: Colors.black26)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16*xFact),
                        child: SizedBox.expand(
                          child: Image(
                            image: imageProvider,
                            fit: BoxFit.cover,
                            alignment: Alignment(offsetX, offsetY),
                            gaplessPlayback: true,
                            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded || frame != null) {
                                return child;
                              }
                              return Container(color: Colors.grey[900]);
                            },
                          ),
                        ),
                      ),
                    )
                  : Container(padding: EdgeInsets.all(16*xFact), decoration: gradientDecoration, child: const SizedBox.expand()),
              Align(
                alignment: Alignment.center,
                child: Text('Aa', style: TextStyle(fontFamily: font, fontSize: 24*xFact, color: Color(colorText))),
              ),
            ],
          ),
        ),
        if (selected)
          Positioned(
            top: 8*yFact,
            right: 8*xFact,
            child: CircleAvatar(radius: 10*xFact, backgroundColor: Colors.white, child: Icon(Icons.check, size: 14*xFact, color: Colors.black87)),
          ),
        if (isCustom)
          Positioned(
            top: 6*yFact,
            left: 6*xFact,
            child: GestureDetector(
              onTap: onDelete,
              child: SizedBox(
                width: 22*xFact,
                child: Image.asset(
                  "assets/images/delete.png",
                ),
              ),
            ),
          ),
        if (isFree && !selected && !isPremium)
          Positioned(
            top: 6*yFact,
            right: 6*xFact,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6*xFact, vertical: 3*yFact),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20*xFact),
              ),
              child: Text(
                language == "fr" ? "Gratuit" : "Free",
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: "InterTight",
                  fontSize: 10*xFact,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        // Lock for non-premium app themes (top right) - only if not custom and not free
        if (!isCustom && !isFree && !selected && !isPremium)
          Positioned(
            top: 6*yFact,
            right: 6*xFact,
            child: SizedBox(
              width: 20*xFact,
              height: 20*yFact,
              child: Image.asset("assets/images/cadenas.png", color: appTheme.onTextField),
            ),
          ),
        // Lock for non-premium custom themes (bottom right)
        if (isCustom && !isPremium)
          Positioned(
            bottom: 6*yFact,
            right: 6*xFact,
            child: SizedBox(
              width: 20*xFact,
              height: 20*yFact,
              child: Image.asset("assets/images/cadenas.png", color: appTheme.onTextField),
            ),
          ),
      ],
    );
  }
}

// --- Helpers: respect provided stops, with light safety ---
List<double> _stops2(double a, double b) {
  double s1 = a.clamp(0.0, 1.0);
  double s2 = b.clamp(0.0, 1.0);
  if (s2 < s1) { final t = s1; s1 = s2; s2 = t; }
  if ((s2 - s1).abs() < 1e-6) {
    // avoid identical stops (errors or undesired flat areas)
    s1 = (s1 - 1e-3).clamp(0.0, 1.0);
    s2 = (s2 + 1e-3).clamp(0.0, 1.0);
    if (s1 == s2) s2 = (s1 < 1.0) ? s1 + 1e-3 : s1; // ultime garde-fou
  }
  return [s1, s2];
}

List<double> _stops3(double a, double b, double c) {
  final list = [a, b, c].map((e) => e.clamp(0.0, 1.0)).toList()..sort();
  // slightly offset if equal
  for (int i = 1; i < list.length; i++) {
    if ((list[i] - list[i - 1]).abs() < 1e-6) {
      list[i] = (list[i] + 1e-3).clamp(0.0, 1.0);
    }
  }
  return list;
}