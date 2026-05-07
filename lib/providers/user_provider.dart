import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/save_cloud.dart';
import '../theme/themedatas.dart';

class ThemeNotifier extends StateNotifier<int> {
  final Ref ref;
  ThemeNotifier(this.ref, super.initialIndex);

  Future<void> setTheme(int index, {required bool isCustom}) async {
    if (isCustom) {
      final customList = ref.read(themeCustomListProvider);
      if (index >= 0 && index < customList.length) {
        state = index;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt("themeIndex", index);
        await prefs.setBool("isCustomTheme", true);
        
        // Save to Firebase
        saveOneToCloud("", "themeIndex", index);
        saveOneToCloud("", "isCustomTheme", true);
      }
    } else {
      debugPrint("settheme index in ThemeNotifier: $index");
      if (index >= 0 && index < allAppThemes.length) {
        state = index;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt("themeIndex", index);
        await prefs.setBool("isCustomTheme", false);
        
        // Save to Firebase
        saveOneToCloud("", "themeIndex", index);
        saveOneToCloud("", "isCustomTheme", false);
      }
    }
  }

  void setIndex(int index) {
    state = index;
  }
}

final premiumProvider = StateProvider<bool>((ref) {
  // Will be provided via override in main.dart
  throw UnimplementedError("themeIndexProvider doit être override avant runApp()");
});


final themeIndexProvider = StateNotifierProvider<ThemeNotifier, int>((ref) {
  // Will be provided via override in main.dart
  throw UnimplementedError("themeIndexProvider doit être override avant runApp()");
});

final isCustomThemeProvider = StateNotifierProvider<IsCustomThemeNotifier, bool>((ref) {
  // Will be provided via override in main.dart
  throw UnimplementedError("isCustomThemeProvider doit être override avant runApp()");
});

class IsCustomThemeNotifier extends StateNotifier<bool> {
  IsCustomThemeNotifier(super.initialValue);

  Future<void> setIsCustom(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isCustomTheme", value);
    
    // Save to Firebase
    saveOneToCloud("", "isCustomTheme", value);
  }

  void setValue(bool value) {
    state = value;
  }
}

final currentThemeProvider = Provider<Map<String,dynamic>>((ref) {
  final index = ref.watch(themeIndexProvider);
  final isCustom = ref.watch(isCustomThemeProvider);
  
  if (isCustom) {
    final customList = ref.watch(themeCustomListProvider);
    if (index >= 0 && index < customList.length) {
      final theme = customList[index];
      
      // ⚠️ If the custom theme has an image, check that it exists locally
      final isImage = theme["isImage"] == true;
      final imageName = theme["imageName"] as String?;
      final hasImage = isImage && imageName != null && imageName.isNotEmpty;
      
      if (hasImage) {
        // Check whether the image exists locally
        final file = File(imageName);
        if (!file.existsSync()) {
          // Image doesn't exist (uninstall/reinstall) → use default theme
          if (kDebugMode) {
            debugPrint("⚠️ [ThemeProvider] Custom theme with image not found locally");
            debugPrint("   - Index: $index");
            debugPrint("   - Image path: $imageName");
            debugPrint("   - Using default theme");
          }
          return allAppThemes[0];
        }
      }
      
      return theme;
    }
    // Fallback si index invalide
    return allAppThemes[0];
  } else {
    if (index >= 0 && index < allAppThemes.length) {
      return allAppThemes[index];
    }
    // Fallback si index invalide
    return allAppThemes[0];
  }
});
