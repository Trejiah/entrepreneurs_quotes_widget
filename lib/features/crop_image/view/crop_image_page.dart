import 'dart:typed_data';

import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/crop_image/model/crop_image_models.dart';
import 'package:businessmindset/features/crop_image/view_model/crop_image_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CropImagePage extends ConsumerStatefulWidget {
  final String imagePath;

  const CropImagePage({
    super.key,
    required this.imagePath,
  });

  @override
  ConsumerState<CropImagePage> createState() => _CropImagePageState();
}

class _CropImagePageState extends ConsumerState<CropImagePage> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  final _cropController = CropController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(cropImageViewModelProvider.notifier).loadImage(widget.imagePath);
    });
  }

  void _cropImage() {
    _cropController.crop();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final uiState = ref.watch(cropImageViewModelProvider);
    final cropConfig = CropImageConfig(imagePath: widget.imagePath);

    if (uiState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiState.errorMessage!)),
        );
        Navigator.pop(context);
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: uiState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(20 * xFact),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 40 * xFact,
                                    height: 40 * xFact,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 24 * xFact,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _cropImage,
                                  child: Container(
                                    width: 40 * xFact,
                                    height: 40 * xFact,
                                    decoration: BoxDecoration(
                                      color: appTheme.lowButtonGold,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 24 * xFact,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20 * yFact),
                            Text(
                              translate('positionimage', lang),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20 * xFact,
                                fontFamily: 'YesevaOne',
                              ),
                            ),
                            SizedBox(height: 10 * yFact),
                            Text(
                              translate('cropinstructions', lang),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14 * xFact,
                                fontFamily: 'InterTight',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: Colors.black,
                          child: uiState.imageData != null
                              ? Crop(
                                  image: Uint8List.fromList(uiState.imageData!),
                                  controller: _cropController,
                                  aspectRatio: cropConfig.aspectRatio,
                                  initialSize: cropConfig.initialSize,
                                  withCircleUi: false,
                                  baseColor: Colors.black,
                                  maskColor: Colors.black.withValues(alpha: 0.7),
                                  radius: 0,
                                  onCropped: (croppedData) {
                                    Navigator.pop(context, croppedData);
                                  },
                                  cornerDotBuilder: (size, edgeAlignment) =>
                                      const SizedBox.shrink(),
                                  interactive: true,
                                  fixCropRect: true,
                                  clipBehavior: Clip.none,
                                )
                              : const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(20 * xFact),
                        child: Text(
                          'Format: 1064 x 498 pixels',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12 * xFact,
                            fontFamily: 'InterTight',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

