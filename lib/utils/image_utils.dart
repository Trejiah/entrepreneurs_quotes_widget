import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

/// Copy an image from a source path to the app's permanent directory
/// Return the path of the copied file, or null on error
Future<String?> copyImageToPermanentLocation(String sourcePath) async {
  try {
    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      return null;
    }

    // Get the application documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final customBackgroundsDir = Directory(path.join(appDir.path, 'custom_backgrounds'));
    
    // Create the directory if it doesn't exist
    if (!customBackgroundsDir.existsSync()) {
      await customBackgroundsDir.create(recursive: true);
    }

    // Generate a unique file name based on the timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(sourcePath);
    final fileName = 'custom_bg_$timestamp$extension';
    final destPath = path.join(customBackgroundsDir.path, fileName);

    // Copy the file
    final destFile = await sourceFile.copy(destPath);
    return destFile.path;
  } catch (e) {
    debugPrint('Error while copying the image: $e');
    return null;
  }
}

/// Check whether an image path exists and return the valid path
/// If the path is a temporary path that no longer exists, return null
String? getValidImagePath(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) {
    return null;
  }

  final file = File(imagePath);
  if (file.existsSync()) {
    return imagePath;
  }

  // If the file doesn't exist and it's a temporary path, return null
  if (imagePath.contains('/tmp/') || imagePath.contains('image_picker')) {
    return null;
  }

  return null;
}

// ==================== APP GROUP MANAGEMENT FOR WIDGET ====================

/// Communication channel with native code
const _widgetChannel = MethodChannel('businessmindset/deeplink');

/// Retrieve the App Group path from native iOS code
/// Returns null if native code doesn't respond or on error
Future<String?> _getAppGroupPath() async {
  try {
    final String? path = await _widgetChannel.invokeMethod('getAppGroupPath');
    return path;
  } catch (e) {
    debugPrint('❌ [ImageUtils] Error while fetching the App Group path: $e');
    return null;
  }
}

/// Compress and resize an image to 1064x498 format
/// Return the bytes of the JPEG-compressed image (quality 85%)
Uint8List? compressAndResizeImage(Uint8List imageBytes, {int quality = 85}) {
  try {
    // Decode the image
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      debugPrint('❌ [ImageUtils] Unable to decode the image');
      return null;
    }

    // The image is already cropped to 1064x498 by the crop controller
    // We resize it if it isn't exactly that size
    img.Image resized;
    if (image.width != 1064 || image.height != 498) {
      resized = img.copyResize(image, width: 1064, height: 498);
    } else {
      resized = image;
    }

    // Encode as JPEG with compression
    final compressed = img.encodeJpg(resized, quality: quality);
    return Uint8List.fromList(compressed);
  } catch (e) {
    debugPrint('❌ [ImageUtils] Error while compressing the image: $e');
    return null;
  }
}

/// Save a cropped image to the App Group for the iOS widget
/// Return the file name (without path) or null on error
/// 
/// The image must be in 1064x498 pixel format
/// It will be compressed to JPEG (quality 85%) before saving
Future<String?> saveImageToWidgetGroup(Uint8List croppedImageBytes) async {
  try {
    // 1. Compress and resize the image
    final compressedBytes = compressAndResizeImage(croppedImageBytes);
    if (compressedBytes == null) {
      debugPrint('❌ [ImageUtils] Image compression failed');
      return null;
    }

    debugPrint('📸 [ImageUtils] Image compressed: ${compressedBytes.length} bytes');

    // 2. Get the App Group path
    final groupPath = await _getAppGroupPath();
    if (groupPath == null) {
      debugPrint('❌ [ImageUtils] Unable to get the App Group path');
      return null;
    }

    debugPrint('📁 [ImageUtils] Chemin App Group: $groupPath');

    // 3. Create the custom_themes folder in the App Group
    final themesDir = Directory(path.join(groupPath, 'custom_themes'));
    if (!themesDir.existsSync()) {
      await themesDir.create(recursive: true);
      debugPrint('📁 [ImageUtils] custom_themes folder created');
    }

    // 4. Generate a unique file name
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'widget_$timestamp.jpg';
    final destPath = path.join(themesDir.path, fileName);

    // 5. Save the file
    final file = File(destPath);
    await file.writeAsBytes(compressedBytes);

    debugPrint('✅ [ImageUtils] Image saved: $fileName (${compressedBytes.length} bytes)');

    // 6. Check the file exists
    if (!file.existsSync()) {
      debugPrint('❌ [ImageUtils] Error: File doesn\'t exist after save');
      return null;
    }

    // Return only the file name (not the full path)
    return fileName;
  } catch (e) {
    debugPrint('❌ [ImageUtils] Error while saving to the App Group: $e');
    return null;
  }
}

/// Delete a custom image file from the App Group folder
/// Takes the file name as parameter (without path)
Future<void> deleteImageFromWidgetGroup(String? fileName) async {
  if (fileName == null || fileName.isEmpty) {
    return;
  }

  try {
    // Get the App Group path
    final groupPath = await _getAppGroupPath();
    if (groupPath == null) {
      debugPrint('❌ [ImageUtils] Unable to get the App Group path for deletion');
      return;
    }

    // Build the full path
    final filePath = path.join(groupPath, 'custom_themes', fileName);
    final file = File(filePath);

    // Delete the file if it exists
    if (file.existsSync()) {
      await file.delete();
      debugPrint('✅ [ImageUtils] Image deleted: $fileName');
    } else {
      debugPrint('ℹ️ [ImageUtils] File not found for deletion: $fileName');
    }
  } catch (e) {
    debugPrint('❌ [ImageUtils] Error while deleting the image: $e');
  }
}

/// Clean up all orphan files in the custom_themes folder
/// (files no longer referenced by any theme)
Future<void> cleanupOrphanedImages(List<String> usedFileNames) async {
  try {
    final groupPath = await _getAppGroupPath();
    if (groupPath == null) {
      return;
    }

    final themesDir = Directory(path.join(groupPath, 'custom_themes'));
    if (!themesDir.existsSync()) {
      return;
    }

    // List all files in the folder
    final files = themesDir.listSync();
    int deletedCount = 0;

    for (final file in files) {
      if (file is File) {
        final fileName = path.basename(file.path);
        // If the file isn't in the list of used files, delete it
        if (!usedFileNames.contains(fileName)) {
          await file.delete();
          deletedCount++;
          debugPrint('🗑️ [ImageUtils] Orphan image deleted: $fileName');
        }
      }
    }

    if (deletedCount > 0) {
      debugPrint('✅ [ImageUtils] Cleanup done: $deletedCount orphan images deleted');
    }
  } catch (e) {
    debugPrint('❌ [ImageUtils] Error while cleaning up images: $e');
  }
}

