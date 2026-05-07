import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/settings/pages/language/model/language_models.dart';
import 'package:businessmindset/features/settings/pages/language/view_model/language_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguagePage extends ConsumerStatefulWidget {
  const LanguagePage({super.key});

  @override
  ConsumerState<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends ConsumerState<LanguagePage> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(languagePageViewModelProvider.notifier).loadPref();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final state = ref.watch(languagePageViewModelProvider);
    final vm = ref.read(languagePageViewModelProvider.notifier);

    Widget languageButton(LanguageUsed language) {
      final isActive = state.selected == language;
      return GestureDetector(
        onTap: () => vm.selectLanguage(language),
        child: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            color: isActive ? appTheme.lowButtonGold : appTheme.settingsButton,
          ),
          child: Padding(
            padding: EdgeInsets.only(top: 12 * yFact, bottom: 12 * yFact),
            child: Center(
              child: Text(
                translate(kLanguageLabels[language]!, lang),
                style: TextStyle(
                  color: isActive ? appTheme.onSecButton : appTheme.onBackground,
                  fontFamily: 'InterTight',
                  fontSize: 18 * xFact,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: appTheme.background),
        child: SafeArea(
          top: true,
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10 * xFact),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 10 * xFact),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: appTheme.onBackground,
                            size: 30 * xFact,
                          ),
                        ),
                        SizedBox(width: 5 * xFact),
                        Text(
                          translate('Language', lang),
                          style: TextStyle(
                            fontFamily: 'YesevaOne',
                            color: appTheme.onBackground,
                            fontSize: 35 * xFact,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30 * yFact),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10 * xFact),
                      child: Column(
                        children: [
                          languageButton(LanguageUsed.en),
                          SizedBox(height: 2 * yFact),
                          languageButton(LanguageUsed.fr),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(
                    right: 20 * xFact,
                    left: 20 * xFact,
                    bottom: 30 * yFact,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SecondaryButton(
                      text: translate('save', lang),
                      onTap: () async {
                        await vm.saveInput();
                        if (!context.mounted) return;
                        Navigator.pop(context);
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
  }
}

