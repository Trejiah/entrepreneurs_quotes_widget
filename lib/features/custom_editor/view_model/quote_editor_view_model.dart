import 'dart:io';

import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/features/custom_editor/view_model/quote_editor_ui_state.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/theme/themedatas.dart';
import 'package:businessmindset/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class QuoteEditorNotifier extends StateNotifier<QuoteEditorUiState> {
  QuoteEditorNotifier()
      : super(QuoteEditorUiState(
          bgColor: const Color(0xFF54C3E5),
          citationColor: appTheme.onBackground,
          fontFamily: 'InterTight',
        ));

  double get resolvedFontSize =>
      fontFamilyToSize[state.fontFamily] ?? textSize3;

  bool _hasValidBackgroundImage() {
    final p = state.backgroundImagePath;
    if (p == null) return false;
    return File(p).existsSync();
  }

  void setBackgroundFromColor(Color color) {
    state = state.copyWith(
      bgColor: color.withAlpha(0xFF),
      backgroundImagePath: null,
      isImageBackground: false,
    );
  }

  void setCitationColor(Color color) {
    state = state.copyWith(citationColor: color.withAlpha(0xFF));
  }

  void setFontFamily(String family) {
    state = state.copyWith(fontFamily: family);
  }

  void applyImagePanDelta(double dx, double dy) {
    const sensitivity = 200.0;
    state = state.copyWith(
      imageOffsetX:
          (state.imageOffsetX - dx / sensitivity).clamp(-1.0, 1.0),
      imageOffsetY:
          (state.imageOffsetY - dy / sensitivity).clamp(-1.0, 1.0),
    );
  }

  Future<void> pickBackgroundImageFromGallery() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    state = state.copyWith(
      backgroundImagePath: x.path,
      isImageBackground: true,
      imageOffsetX: 0.0,
      imageOffsetY: 0.0,
    );
  }

  Future<String?> saveCustomTheme(WidgetRef ref) async {
    try {
      String? savedImagePath = '';
      final path = state.backgroundImagePath;
      if (path != null && File(path).existsSync()) {
        debugPrint('📸 [QuoteEditor] Image source: $path');
        final permanentPath = await copyImageToPermanentLocation(path);
        debugPrint('📸 [QuoteEditor] Chemin permanent: $permanentPath');
        if (permanentPath != null) {
          savedImagePath = permanentPath;
          final savedFile = File(permanentPath);
          debugPrint(
              '📸 [QuoteEditor] File exists after copy: ${savedFile.existsSync()}');
        } else {
          savedImagePath = path;
          debugPrint(
              '⚠️ [QuoteEditor] Copy failed, using temporary path: $savedImagePath');
        }
      }

      final hasImage = _hasValidBackgroundImage();
      final newTheme = <String, dynamic>{
        'color1': hasImage
            ? appTheme.background.toARGB32()
            : state.bgColor.toARGB32(),
        'color2': 0xff29918a,
        'color3': 0xffe09571,
        'p1': 0.0,
        'p2': 0.0,
        'p3': 0.0,
        'nbrcolor': 1,
        'fontfamily': state.fontFamily,
        'fontcolor': state.citationColor.toARGB32(),
        'fontsize': resolvedFontSize,
        'name': '',
        'isImage': state.isImageBackground,
        'imageName': savedImagePath,
        'imageOffsetX': state.imageOffsetX,
        'imageOffsetY': state.imageOffsetY,
      };

      debugPrint(
          '📸 [QuoteEditor] Theme to save: isImage=${state.isImageBackground}, imageName=$savedImagePath');

      final generatedName = await _addNewThemeEverywhere(ref, newTheme);
      debugPrint('✅ Theme saved under name $generatedName');
      MixpanelService.instance.track('[Theme] Custom Created', {});
      return generatedName;
    } catch (e, st) {
      debugPrint('QuoteEditor save error: $e\n$st');
      return null;
    }
  }

  Future<String> _addNewThemeEverywhere(
    WidgetRef ref,
    Map<String, dynamic> theme,
  ) async {
    final name = await generateThemeName();
    theme['name'] = name;
    await addOrUpdateThemeLocal(theme);
    await addOrUpdateThemeInProvider(ref, theme);
    await addOrUpdateThemeFirebase(theme);
    return name;
  }
}
