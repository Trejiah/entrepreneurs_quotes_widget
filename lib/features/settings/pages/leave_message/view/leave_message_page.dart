import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/settings/pages/leave_message/model/leave_message_models.dart';
import 'package:businessmindset/features/settings/pages/leave_message/view_model/leave_message_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessagePage extends ConsumerStatefulWidget {
  const MessagePage({super.key});

  @override
  ConsumerState<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends ConsumerState<MessagePage> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      ref.read(leaveMessageViewModelProvider.notifier).onMessageChanged(
            _textController.text,
          );
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
    final state = ref.watch(leaveMessageViewModelProvider);

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
                          translate('contactus', lang),
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
                          translate('contactus2', lang),
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
                            height: MediaQuery.of(context).size.height / 2,
                            maxLength: LeaveMessageConfig.maxLength,
                            inputStyle: 'input1',
                            fontFamily: 'InterTight',
                            fontSize: 18 * xFact,
                            backgroundColor: appTheme.textField,
                            borderColor: appTheme.containerTextField,
                            textColor: appTheme.onBackgroundSub,
                            hintText: 'leavemess',
                            controller: _textController,
                            onChanged: (String value) {
                              ref
                                  .read(leaveMessageViewModelProvider.notifier)
                                  .onMessageChanged(value);
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
                                '${state.characterCount}/${LeaveMessageConfig.maxLength}',
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
                    child: SecondaryButton(
                      text: translate('send', lang),
                      onTap: () async {
                        await ref.read(leaveMessageViewModelProvider.notifier).sendMessage();
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

