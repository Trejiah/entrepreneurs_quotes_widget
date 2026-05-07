import 'dart:async';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/utils/image_utils.dart';

/// Tranche C : préchargement du fond personnalisé (évite un flash au premier rendu).
final homeThemeCoordinatorProvider = Provider<HomeThemeCoordinator>((ref) {
  return HomeThemeCoordinator(ref);
});

class HomeThemeCoordinator {
  HomeThemeCoordinator(this._ref);

  final Ref _ref;

  Future<void> preloadCustomBackgroundIfNeeded() async {
    final isCustomTheme = _ref.read(isCustomThemeProvider);
    if (!isCustomTheme) return;

    final themeMap = _ref.read(currentThemeProvider);
    final isImage = themeMap['isImage'] == true;
    final imageName = themeMap['imageName'] as String?;
    if (!isImage || imageName == null || imageName.isEmpty) return;

    final validPath = getValidImagePath(imageName);
    if (validPath == null || !File(validPath).existsSync()) return;

    final imageProvider = FileImage(File(validPath));
    final completer = Completer<void>();
    final stream = imageProvider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, sync) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
      onError: (e, s) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    await completer.future;
  }
}
