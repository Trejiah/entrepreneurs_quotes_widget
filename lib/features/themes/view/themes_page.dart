import 'dart:typed_data';

import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/themes/model/themes_models.dart';
import 'package:businessmindset/features/themes/view_model/themes_provider.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding20bis.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/theme/themecard.dart';
import 'package:businessmindset/theme/themedatas.dart';
import 'package:businessmindset/features/paywall/view/paywallb_page.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:businessmindset/features/custom_editor/view/quote_editor_page.dart';
import 'package:businessmindset/features/crop_image/view/crop_image_page.dart';

class ThemesPage extends ConsumerStatefulWidget {
  final bool fromWidget;
  const ThemesPage({super.key, this.fromWidget = false});

  @override
  ConsumerState<ThemesPage> createState() => _ThemesPageState();
}

class _ThemesPageState extends ConsumerState<ThemesPage> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(themesViewModelProvider.notifier).initSelection(
            fromWidget: widget.fromWidget,
          );
    });
  }

  bool _handleBackNavigation() => true;

  void _showPaywall() {
    final lang = ref.read(languageProvider);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Paywallb(
          pageStyle: 'notdeclare',
          backIcon: true,
          skipLink: false,
          backward: () {},
          forward1: () => _purchaseOk(),
          forward2: () {},
          title: translate('onboardingtitle3', lang),
          subTitle: translate('onboardingsubtitle3', lang),
          choiceList: [],
          buttonText: 'letsgo',
        ),
      ),
    );
  }

  void _purchaseOk() {
    final lang = ref.read(languageProvider);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => OnBoarding20bis(
          backIcon: false,
          skipLink: false,
          backward: () {},
          forward: () {
            ref.read(themesViewModelProvider.notifier).applyPremiumPurchase();
            Navigator.pop(context);
          },
          title: translate('onboardingtitle20bis', lang),
          subTitle: translate('onboardingsubtitle20bis', lang),
          choiceList: [],
          buttonText: 'letsbegin',
        ),
      ),
    );
  }

  void _deleteDialog(
    BuildContext context, {
    String titleFont = 'YesevaOne',
    String bodyFont = 'InterTight',
    VoidCallback? onSecondary,
    required String lang,
  }) {
    showGeneralDialog(
      context: context,
      barrierLabel: 'delete',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return Opacity(
          opacity: curved.value,
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              decoration: TextDecoration.none,
              decorationStyle: TextDecorationStyle.solid,
            ),
            child: Center(
              child: Container(
                width: MediaQuery.of(ctx).size.width * 9 / 10,
                height: MediaQuery.of(ctx).size.height * 6 / 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF575757),
                  borderRadius: BorderRadius.circular(18 * xFact),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.only(left: 25 * xFact, right: 25 * xFact),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              SizedBox(height: 70 * yFact),
                              SizedBox(
                                width: 80 * xFact,
                                child: Image.asset('assets/images/delete.png'),
                              ),
                              SizedBox(height: 20 * yFact),
                              Text(
                                translate('suredelete', lang),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: titleFont,
                                  fontSize: 28 * xFact,
                                  height: 1.2 * yFact,
                                  color: appTheme.onBackground,
                                ),
                              ),
                              SizedBox(height: 30 * yFact),
                              Text(
                                translate('suredeletesubtitle', lang),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: bodyFont,
                                  fontSize: 18 * xFact,
                                  height: 1.35 * yFact,
                                  color: appTheme.onBackground,
                                ),
                              ),
                              SizedBox(height: 18 * yFact),
                            ],
                          ),
                          Column(
                            children: [
                              SecondaryButton(
                                text: translate('confirm', lang),
                                onTap: () {
                                  onSecondary?.call();
                                  Navigator.of(ctx).pop();
                                },
                              ),
                              SizedBox(height: 10 * yFact),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: appTheme.onBackground,
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18 * xFact,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                },
                                child: Text(translate('cancel', lang)),
                              ),
                              SizedBox(height: 8 * yFact),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 10 * yFact,
                      left: 10 * xFact,
                      child: Material(
                        color: Colors.transparent,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          color: appTheme.onBackground,
                          tooltip: 'Close',
                          onPressed: () {
                            Navigator.of(ctx).pop();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _deleteCustomTheme(BuildContext ctx, Map<String, dynamic> toDelete) {
    final lang = ref.read(languageProvider);
    final name = (toDelete['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) return;

    _deleteDialog(
      ctx,
      lang: lang,
      onSecondary: () async {
        await ref
            .read(themesViewModelProvider.notifier)
            .deleteCustomThemeEverywhereWithRef(ref, toDelete);
      },
    );
  }

  Future<void> _applyOutcome(ThemesOutcome outcome) async {
    if (outcome is ThemesOutcomeNone) return;

    if (outcome is ThemesOutcomeOpenPaywall) {
      _showPaywall();
      return;
    }

    if (outcome is ThemesOutcomeOpenQuoteEditor) {
      Navigator.push(
        context,
        PageRouteBuilder(pageBuilder: (_, __, ___) => const QuoteEditorPage()),
      );
      return;
    }

    if (outcome is ThemesOutcomeShowSnack) {
      final lang = ref.read(languageProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate(outcome.translationKey, lang))),
      );
      return;
    }

    if (outcome is ThemesOutcomeOpenCropForWidget) {
      final Uint8List? croppedData = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (_) => CropImagePage(imagePath: outcome.imagePath),
        ),
      );
      if (croppedData == null) return;

      final next = await ref
          .read(themesViewModelProvider.notifier)
          .applyCroppedWidgetImageForCustomTheme(
            ref: ref,
            customIndex: outcome.customIndex,
            croppedBytes: croppedData,
          );
      await _applyOutcome(next);
      return;
    }

    if (outcome is ThemesOutcomePop) {
      if (!mounted) return;
      Navigator.pop(context, outcome.modified);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(premiumProvider);
    final lang = ref.watch(languageProvider);
    final customTheme = ref.watch(themeCustomListProvider);
    final uiState = ref.watch(themesViewModelProvider);
    final vm = ref.read(themesViewModelProvider.notifier);

    // apply & clear outcome
    Future.microtask(() async {
      await _applyOutcome(uiState.lastOutcome);
      vm.clearOutcome();
    });

    return PopScope(
      canPop: _handleBackNavigation(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _handleBackNavigation()) {
          Navigator.pop(context);
        }
      },
      child: Material(
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(color: appTheme.background),
            child: SafeArea(
              top: true,
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_handleBackNavigation()) {
                              Navigator.pop(context);
                            }
                          },
                          child: Icon(Icons.arrow_back_ios,
                              color: appTheme.onBackground, size: 40 * xFact),
                        ),
                        SizedBox(width: 10 * xFact),
                        Text(
                          translate('Themes', lang),
                          style: TextStyle(
                            fontFamily: 'YesevaOne',
                            color: appTheme.onBackground,
                            fontSize: 35 * xFact,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30 * xFact),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SecondaryButton(
                              text: translate('createtheme', lang),
                              onTap: () {
                                final out =
                                    vm.onCreateThemeTap(premium: premium);
                                vm.setOutcome(out);
                              },
                            ),
                            SizedBox(height: 30 * xFact),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                translate('yourtheme', lang),
                                style: TextStyle(
                                  color: appTheme.onBackground,
                                  fontFamily: 'YesevaOne',
                                  fontSize: 24 * xFact,
                                ),
                              ),
                            ),
                            SizedBox(height: 20 * xFact),
                            customTheme.isEmpty
                                ? Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      translate('notanythem', lang),
                                      style: TextStyle(
                                        color: appTheme.onBackgroundSub,
                                        fontFamily: 'InterTight',
                                        fontSize: 18 * xFact,
                                      ),
                                    ),
                                  )
                                : GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: customTheme.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 14 * yFact,
                                      crossAxisSpacing: 14 * xFact,
                                      childAspectRatio: 0.50,
                                    ),
                                    itemBuilder: (context, i) {
                                      final isSelected =
                                          i == uiState.selectedCustomIndex;

                                      return ThemeCard(
                                        selected: isSelected,
                                        onTap: () async {
                                          final out = await vm.onCustomThemeTap(
                                            ref: ref,
                                            customIndex: i,
                                            premium: premium,
                                            fromWidget: widget.fromWidget,
                                          );
                                          if (mounted) {
                                            await _applyOutcome(out);
                                          }
                                        },
                                        isCustom: true,
                                        currentTheme: customTheme[i],
                                        onDelete: () => _deleteCustomTheme(
                                          context,
                                          customTheme[i],
                                        ),
                                        isPremium: premium,
                                      );
                                    },
                                  ),
                            SizedBox(height: 30 * xFact),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                translate('apptheme', lang),
                                style: TextStyle(
                                  color: appTheme.onBackground,
                                  fontFamily: 'YesevaOne',
                                  fontSize: 24 * xFact,
                                ),
                              ),
                            ),
                            SizedBox(height: 20 * xFact),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: allAppThemes.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 14 * yFact,
                                crossAxisSpacing: 14 * xFact,
                                childAspectRatio: 0.50,
                              ),
                              itemBuilder: (context, i) {
                                final originalIndex =
                                    ThemesCatalog.shuffledAppThemeIndices[i];
                                final isSelected =
                                    originalIndex == uiState.selectedAppIndex;
                                final isFree =
                                    ThemesCatalog.isThemeFree(originalIndex);
                                final isLocked = !premium && !isFree;

                                return ThemeCard(
                                  selected: isSelected,
                                  onTap: () async {
                                    if (isLocked) {
                                      _showPaywall();
                                      return;
                                    }
                                    final out = await vm.onAppThemeTap(
                                      uiIndex: i,
                                      premium: premium,
                                      fromWidget: widget.fromWidget,
                                    );
                                    if (mounted) {
                                      await _applyOutcome(out);
                                    }
                                  },
                                  isCustom: false,
                                  currentTheme: allAppThemes[originalIndex],
                                  onDelete: () {},
                                  isPremium: premium || isFree,
                                  isFree: isFree,
                                  language: lang,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20 * yFact),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

