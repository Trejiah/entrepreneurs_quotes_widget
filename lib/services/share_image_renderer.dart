import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Pure-Flutter offscreen renderer used when no native share-card generator
/// is available (currently: Android — see `MediaChannelHandler.kt`'s
/// `notImplemented` for `generateShareImageBytes`).
///
/// The widget is mounted off-screen via an [Overlay] so the user never sees
/// it, painted with [RepaintBoundary], converted to PNG bytes, then removed.
class ShareImageRenderer {
  ShareImageRenderer._();

  /// Render a 1080x1920 share card and return raw PNG bytes.
  /// Returns `null` if no [Overlay] is available in [context].
  static Future<Uint8List?> render({
    required BuildContext context,
    required String quote,
    String? signature,
    String? bookTitle,
    String? userName,
    bool themeIsImage = false,
    String? themeImageName,
    String? themeColor1,
    String? themeColor2,
    String? themeColor3,
    int themeNbrColor = 1,
    String? themeFontFamily,
    double? themeFontSize,
    String? themeFontColor,
  }) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return null;

    final boundaryKey = GlobalKey();
    final completer = Completer<void>();

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -10000,
        top: -10000,
        child: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(
            key: boundaryKey,
            child: _ShareCard(
              quote: quote,
              signature: signature,
              bookTitle: bookTitle,
              userName: userName,
              themeIsImage: themeIsImage,
              themeImageName: themeImageName,
              themeColor1: themeColor1,
              themeColor2: themeColor2,
              themeColor3: themeColor3,
              themeNbrColor: themeNbrColor,
              themeFontFamily: themeFontFamily,
              themeFontSize: themeFontSize,
              themeFontColor: themeFontColor,
              onLayoutDone: () {
                if (!completer.isCompleted) completer.complete();
              },
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    try {
      await completer.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () {},
      );
      // Wait for the next frame so RepaintBoundary has a layer to capture.
      await WidgetsBinding.instance.endOfFrame;

      final renderObject = boundaryKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) return null;

      final image = await renderObject.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData?.buffer.asUint8List();
    } catch (e, st) {
      debugPrint('[ShareImageRenderer] render failed: $e\n$st');
      return null;
    } finally {
      entry.remove();
    }
  }
}

class _ShareCard extends StatefulWidget {
  final String quote;
  final String? signature;
  final String? bookTitle;
  final String? userName;
  final bool themeIsImage;
  final String? themeImageName;
  final String? themeColor1;
  final String? themeColor2;
  final String? themeColor3;
  final int themeNbrColor;
  final String? themeFontFamily;
  final double? themeFontSize;
  final String? themeFontColor;
  final VoidCallback onLayoutDone;

  const _ShareCard({
    required this.quote,
    required this.signature,
    required this.bookTitle,
    required this.userName,
    required this.themeIsImage,
    required this.themeImageName,
    required this.themeColor1,
    required this.themeColor2,
    required this.themeColor3,
    required this.themeNbrColor,
    required this.themeFontFamily,
    required this.themeFontSize,
    required this.themeFontColor,
    required this.onLayoutDone,
  });

  @override
  State<_ShareCard> createState() => _ShareCardState();
}

class _ShareCardState extends State<_ShareCard> {
  static const _width = 1080.0;
  static const _height = 1920.0;
  bool _imageReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.themeIsImage && widget.themeImageName != null) {
      // Pre-warm asset; fire onLayoutDone once decoded.
      final image = AssetImage('assets/images/${widget.themeImageName}');
      final stream = image.resolve(const ImageConfiguration());
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (_, __) {
          stream.removeListener(listener);
          if (mounted && !_imageReady) {
            setState(() => _imageReady = true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onLayoutDone();
            });
          }
        },
        onError: (_, __) {
          stream.removeListener(listener);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onLayoutDone();
          });
        },
      );
      stream.addListener(listener);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onLayoutDone();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          _buildScrim(),
          _buildContent(),
          _buildBranding(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    if (widget.themeIsImage && widget.themeImageName != null) {
      return Image.asset(
        'assets/images/${widget.themeImageName}',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.black),
      );
    }
    final colors = _buildColorList();
    if (colors.length < 2) {
      return Container(color: colors.first);
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildScrim() {
    if (!widget.themeIsImage) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.20),
            Colors.black.withOpacity(0.45),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildContent() {
    final fontColor = _parseColor(widget.themeFontColor) ?? Colors.white;
    final fontFamily = (widget.themeFontFamily?.isNotEmpty ?? false)
        ? widget.themeFontFamily
        : null;
    // Mirrors the SwiftUI sizing on iOS: 96pt nominal at 1080 width.
    final baseFontSize = (widget.themeFontSize ?? 28.0) * 3.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 96, vertical: 200),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.quote,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fontColor,
                fontFamily: fontFamily,
                fontSize: baseFontSize,
                height: 1.25,
                fontWeight: FontWeight.w600,
                shadows: const [
                  Shadow(blurRadius: 6, color: Colors.black38, offset: Offset(0, 2)),
                ],
              ),
            ),
            if ((widget.signature ?? '').isNotEmpty) ...[
              const SizedBox(height: 48),
              Text(
                '— ${widget.signature}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fontColor.withOpacity(0.85),
                  fontFamily: fontFamily,
                  fontSize: baseFontSize * 0.55,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if ((widget.bookTitle ?? '').isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                widget.bookTitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fontColor.withOpacity(0.65),
                  fontFamily: fontFamily,
                  fontSize: baseFontSize * 0.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBranding() {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          'Business Mindset',
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 36,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            shadows: const [
              Shadow(blurRadius: 4, color: Colors.black54, offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _buildColorList() {
    final c1 = _parseColor(widget.themeColor1) ?? Colors.black;
    if (widget.themeNbrColor <= 1) return [c1];
    final c2 = _parseColor(widget.themeColor2) ?? c1;
    if (widget.themeNbrColor == 2) return [c1, c2];
    final c3 = _parseColor(widget.themeColor3) ?? c2;
    return [c1, c2, c3];
  }

  Color? _parseColor(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    var hex = raw.replaceFirst('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return null;
    return Color(value);
  }
}
