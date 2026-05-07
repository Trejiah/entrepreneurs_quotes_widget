import 'dart:io';

import 'package:businessmindset/features/themes/model/themes_models.dart';
import 'package:businessmindset/features/themes/view_model/themes_ui_state.dart';
import 'package:businessmindset/providers/habits_provider.dart' show sharedPrefsProvider;
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/services/widget_subscription_sync.dart';
import 'package:businessmindset/theme/themedatas.dart';
import 'package:businessmindset/utils/image_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemesNotifier extends StateNotifier<ThemesUiState> {
  ThemesNotifier(this._ref) : super(const ThemesUiState());

  final Ref _ref;

  static const MethodChannel _widgetChannel =
      MethodChannel('businessmindset/deeplink');

  void clearOutcome() {
    if (state.lastOutcome is ThemesOutcomeNone) return;
    state = state.copyWith(lastOutcome: const ThemesOutcomeNone());
  }

  void _emit(ThemesOutcome outcome) {
    state = state.copyWith(lastOutcome: outcome);
  }

  void setOutcome(ThemesOutcome outcome) => _emit(outcome);

  void initSelection({required bool fromWidget}) {
    final prefs = _ref.read(sharedPrefsProvider);

    int themeIndex;
    bool isCustom;

    if (fromWidget) {
      themeIndex =
          prefs.getInt('widgetThemeIndex') ?? prefs.getInt('themeIndex') ?? 0;
      isCustom = prefs.getBool('widgetIsCustomTheme') ??
          prefs.getBool('isCustomTheme') ??
          false;
    } else {
      themeIndex = _ref.read(themeIndexProvider);
      isCustom = _ref.read(isCustomThemeProvider);
    }

    final customThemes = _ref.read(themeCustomListProvider);

    if (isCustom) {
      if (themeIndex < 0 || themeIndex >= customThemes.length) {
        isCustom = false;
        themeIndex = prefs.getInt('themeIndex') ?? 0;
      }
    } else {
      if (themeIndex < 0 || themeIndex >= allAppThemes.length) {
        themeIndex = 0;
      }
    }

    state = state.copyWith(
      selectedCustomIndex: isCustom ? themeIndex : null,
      selectedAppIndex: isCustom ? null : themeIndex,
      clearSelectedCustomIndex: !isCustom,
      clearSelectedAppIndex: isCustom,
    );
  }

  ThemesOutcome onCreateThemeTap({required bool premium}) {
    if (!premium) {
      return const ThemesOutcomeOpenPaywall(ThemesPaywallSource.createTheme);
    }
    return const ThemesOutcomeOpenQuoteEditor();
  }

  Future<ThemesOutcome> onCustomThemeTap({
    required WidgetRef ref,
    required int customIndex,
    required bool premium,
    required bool fromWidget,
  }) async {
    if (!premium) {
      return const ThemesOutcomeOpenPaywall(ThemesPaywallSource.customThemeTap);
    }

    state = state.copyWith(
      selectedCustomIndex: customIndex,
      selectedAppIndex: null,
      clearSelectedAppIndex: true,
    );

    final customThemes = _ref.read(themeCustomListProvider);
    if (customIndex < 0 || customIndex >= customThemes.length) {
      return const ThemesOutcomeNone();
    }

    final themeOriginal = customThemes[customIndex];
    final isImage = themeOriginal['isImage'] == true;
    final imageName = themeOriginal['imageName'] as String?;

    if (fromWidget && isImage && imageName != null && imageName.isNotEmpty) {
      final file = File(imageName);
      if (!file.existsSync()) {
        return const ThemesOutcomeShowSnack('imagenotfound');
      }
      return ThemesOutcomeOpenCropForWidget(
        customIndex: customIndex,
        imagePath: imageName,
      );
    }

    if (fromWidget) {
      await _saveWidgetSelection(themeIndex: customIndex, isCustomTheme: true);
      await _syncWidgetAfterThemeSelected(
        themeIndex: customIndex,
        isCustomTheme: true,
        includeCustomThemes: true,
      );
      return const ThemesOutcomePop(modified: true);
    }

    await _ref
        .read(themeIndexProvider.notifier)
        .setTheme(customIndex, isCustom: true);
    _ref.read(isCustomThemeProvider.notifier).setValue(true);

    final isPremiumForWidget = _ref.read(premiumProvider);
    if (!isPremiumForWidget) {
      await _syncWidgetAfterThemeSelected(
        themeIndex: customIndex,
        isCustomTheme: true,
        includeCustomThemes: false,
      );
    }

    return const ThemesOutcomeNone();
  }

  Future<ThemesOutcome> applyCroppedWidgetImageForCustomTheme({
    required WidgetRef ref,
    required int customIndex,
    required List<int> croppedBytes,
  }) async {
    final customThemes = _ref.read(themeCustomListProvider);
    if (customIndex < 0 || customIndex >= customThemes.length) {
      return const ThemesOutcomeNone();
    }

    final widgetImageName =
        await saveImageToWidgetGroup(Uint8List.fromList(croppedBytes));
    if (widgetImageName == null) {
      return const ThemesOutcomeShowSnack('imagesavefailed');
    }

    final themeOriginal = customThemes[customIndex];
    final themeUpdated = Map<String, dynamic>.from(themeOriginal);
    themeUpdated['widgetImageName'] = widgetImageName;

    await addOrUpdateThemeLocal(themeUpdated);
    await addOrUpdateThemeInProvider(ref, themeUpdated);

    if (kDebugMode) {
      debugPrint('✅ [ThemesPage] Widget image saved: $widgetImageName');
      debugPrint('✅ [ThemesPage] Theme updated with widgetImageName');
    }

    await _saveWidgetSelection(themeIndex: customIndex, isCustomTheme: true);
    await _syncWidgetAfterThemeSelected(
      themeIndex: customIndex,
      isCustomTheme: true,
      includeCustomThemes: true,
    );

    return const ThemesOutcomePop(modified: true);
  }

  Future<ThemesOutcome> onAppThemeTap({
    required int uiIndex,
    required bool premium,
    required bool fromWidget,
  }) async {
    final originalIndex = ThemesCatalog.shuffledAppThemeIndices[uiIndex];
    final isFree = ThemesCatalog.isThemeFree(originalIndex);
    final isLocked = !premium && !isFree;

    if (isLocked) {
      return const ThemesOutcomeOpenPaywall(ThemesPaywallSource.appThemeTap);
    }

    state = state.copyWith(
      selectedAppIndex: originalIndex,
      selectedCustomIndex: null,
      clearSelectedCustomIndex: true,
    );

    if (kDebugMode) {
      debugPrint(
        '[WidgetTap] ThemesPage app theme tapped uiIndex=$uiIndex originalIndex=$originalIndex '
        'fromWidget=$fromWidget premium=$premium',
      );
    }

    if (fromWidget) {
      await _saveWidgetSelection(themeIndex: originalIndex, isCustomTheme: false);
      await _syncWidgetAfterThemeSelected(
        themeIndex: originalIndex,
        isCustomTheme: false,
        includeCustomThemes: false,
      );
      return const ThemesOutcomePop(modified: true);
    }

    await _ref
        .read(themeIndexProvider.notifier)
        .setTheme(originalIndex, isCustom: false);
    _ref.read(isCustomThemeProvider.notifier).setValue(false);

    final isPremiumForWidget = _ref.read(premiumProvider);
    if (!isPremiumForWidget) {
      await _syncWidgetAfterThemeSelected(
        themeIndex: originalIndex,
        isCustomTheme: false,
        includeCustomThemes: false,
      );
    }

    return const ThemesOutcomeNone();
  }

  Future<void> deleteCustomThemeEverywhere(Map<String, dynamic> toDelete) async {
    final name = (toDelete['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) return;
    // La suppression doit passer un WidgetRef (provider).
    // La vue doit appeler `deleteThemeEverywhere(ref, name)` directement.
    // Ici on garde une méthode utilitaire au besoin (mais sans WidgetRef).
  }

  Future<void> deleteCustomThemeEverywhereWithRef(
    WidgetRef ref,
    Map<String, dynamic> toDelete,
  ) async {
    final name = (toDelete['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) return;
    await deleteThemeEverywhere(ref, name);
  }

  void applyPremiumPurchase() {
    _ref.read(premiumProvider.notifier).state = true;
    final prefs = _ref.read(sharedPrefsProvider);
    prefs.setBool('premiumState', true);
  }

  Future<void> _saveWidgetSelection({
    required int themeIndex,
    required bool isCustomTheme,
  }) async {
    final prefs = _ref.read(sharedPrefsProvider);
    await prefs.setInt('widgetThemeIndex', themeIndex);
    await prefs.setBool('widgetIsCustomTheme', isCustomTheme);
  }

  Future<void> _syncWidgetAfterThemeSelected({
    required int themeIndex,
    required bool isCustomTheme,
    required bool includeCustomThemes,
  }) async {
    final langForWidget = _ref.read(languageProvider);
    final isPremiumForWidget = _ref.read(premiumProvider);
    final premiumExpirationEpochMs = await fetchWidgetPremiumExpirationEpochMs();

    final payload = <String, dynamic>{
      'themeIndex': themeIndex,
      'isCustomTheme': isCustomTheme,
      'language': langForWidget,
      'isPremium': isPremiumForWidget,
      'premiumExpirationEpochMs': premiumExpirationEpochMs,
      'configured': true,
    };

    if (includeCustomThemes) {
      payload['customThemes'] = _ref.read(themeCustomListProvider);
    }

    try {
      await _widgetChannel.invokeMethod('updateWidgetData', payload);
      if (includeCustomThemes) {
        final allCustomThemes = _ref.read(themeCustomListProvider);
        debugPrint(
          '✅ [ThemesPage] List of ${allCustomThemes.length} custom themes synced with the widget',
        );
      }
      MixpanelService.instance.track(
        '[Widget] Refresh widget',
        {'source': 'theme_page'},
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to update widget theme: $e');
      }
    }
  }
}

