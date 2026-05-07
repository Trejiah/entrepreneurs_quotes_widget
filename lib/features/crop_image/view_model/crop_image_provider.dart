import 'package:businessmindset/features/crop_image/view_model/crop_image_ui_state.dart';
import 'package:businessmindset/features/crop_image/view_model/crop_image_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cropImageViewModelProvider =
    StateNotifierProvider.autoDispose<CropImageNotifier, CropImageUiState>(
  (ref) => CropImageNotifier(),
);

