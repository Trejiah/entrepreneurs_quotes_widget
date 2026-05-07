import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/settings/pages/gender/model/gender_models.dart';
import 'package:businessmindset/features/settings/pages/gender/view_model/gender_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GenderPage extends ConsumerStatefulWidget {
  const GenderPage({super.key});

  @override
  ConsumerState<GenderPage> createState() => _GenderPageState();
}

class _GenderPageState extends ConsumerState<GenderPage> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(genderViewModelProvider.notifier).loadPref();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final uiState = ref.watch(genderViewModelProvider);
    final vm = ref.read(genderViewModelProvider.notifier);

    Widget genderButton(GenderChoice gender) {
      final isActive = uiState.selected == gender;
      return Padding(
        padding: EdgeInsets.only(right: 20 * xFact, left: 20 * xFact),
        child: TertiaryButton(
          isChecked: isActive,
          checked: true,
          center: false,
          text: translate(kGenderLabels[gender]!, lang),
          onTap: () => vm.selectGender(gender),
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
                          translate('Gender', lang),
                          style: TextStyle(
                            fontFamily: 'YesevaOne',
                            color: appTheme.onBackground,
                            fontSize: 35 * xFact,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10 * yFact),
                    Padding(
                      padding: EdgeInsets.only(left: 20 * xFact, right: 20 * xFact),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          translate('genderusedto', lang),
                          style: TextStyle(
                            fontFamily: 'InterTight',
                            fontSize: 20 * xFact,
                            color: appTheme.onBackgroundSub,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30 * yFact),
                    genderButton(GenderChoice.female),
                    SizedBox(height: 15 * yFact),
                    genderButton(GenderChoice.male),
                    SizedBox(height: 15 * yFact),
                    genderButton(GenderChoice.other),
                    SizedBox(height: 15 * yFact),
                    genderButton(GenderChoice.notToSay),
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

