import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/settings/pages/name/view_model/name_provider.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NamePage extends ConsumerStatefulWidget {
  const NamePage({super.key});

  @override
  ConsumerState<NamePage> createState() => _NamePageState();
}

class _NamePageState extends ConsumerState<NamePage> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initialName = ref.read(userNameStateProvider);
    ref.read(nameViewModelProvider.notifier).init(initialName);
    _textController.text = initialName;
    _textController.addListener(() {
      ref.read(nameViewModelProvider.notifier).onNameChanged(_textController.text);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final userName = ref.watch(userNameStateProvider);
    final state = ref.watch(nameViewModelProvider);

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
                          translate('Name', lang),
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
                          translate('nameusedto', lang),
                          style: TextStyle(
                            fontFamily: 'InterTight',
                            fontSize: 20 * xFact,
                            color: appTheme.onBackgroundSub,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 15 * yFact),
                    Padding(
                      padding: EdgeInsets.only(right: 20 * xFact, left: 20 * xFact),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            height: 50 * yFact,
                            maxLength: 20,
                            inputStyle: 'input1',
                            fontFamily: 'InterTight',
                            fontSize: 18 * xFact,
                            backgroundColor: appTheme.textField,
                            borderColor: appTheme.containerTextField,
                            textColor: appTheme.onBackgroundSub,
                            hintText: userName,
                            controller: _textController,
                            onChanged: (String value) {
                              ref.read(nameViewModelProvider.notifier).onNameChanged(value);
                            },
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              right: 12 * xFact,
                              top: 4 * yFact,
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${state.characterCount}/20',
                                style: TextStyle(
                                  fontFamily: 'InterTight',
                                  fontSize: 18 * xFact * 0.8,
                                  color: appTheme.onBackground,
                                ),
                              ),
                            ),
                          ),
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
                    child: Opacity(
                      opacity: state.isButtonEnabled ? 1.0 : 0.5,
                      child: IgnorePointer(
                        ignoring: !state.isButtonEnabled,
                        child: SecondaryButton(
                          text: translate('save', lang),
                          onTap: () async {
                            final ok = await ref.read(nameViewModelProvider.notifier).saveInput();
                            if (!ok || !context.mounted) return;
                            Navigator.pop(context);
                          },
                        ),
                      ),
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

