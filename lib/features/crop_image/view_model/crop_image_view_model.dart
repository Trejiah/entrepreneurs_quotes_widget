import 'dart:io';

import 'package:businessmindset/features/crop_image/view_model/crop_image_ui_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CropImageNotifier extends StateNotifier<CropImageUiState> {
  CropImageNotifier() : super(const CropImageUiState());

  Future<void> loadImage(String imagePath) async {
    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
    );
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      state = state.copyWith(
        imageData: bytes,
        isLoading: false,
        clearErrorMessage: true,
      );
    } catch (e) {
      debugPrint('❌ [CropImage] Error while loading the image: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Impossible de charger l'image.",
      );
    }
  }
}

