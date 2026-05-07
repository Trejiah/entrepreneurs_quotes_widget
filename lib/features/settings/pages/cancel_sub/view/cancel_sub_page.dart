import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/settings/pages/cancel_sub/model/cancel_sub_models.dart';
import 'package:businessmindset/features/settings/pages/cancel_sub/view_model/cancel_sub_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CancelSubPage extends ConsumerWidget {
  const CancelSubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xFact = ScreenScale.x;
    final yFact = ScreenScale.y;
    final lang = ref.watch(languageProvider);
    final state = ref.watch(cancelSubViewModelProvider);
    final vm = ref.read(cancelSubViewModelProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: appTheme.background),
        child: SafeArea(
          top: true,
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10 * xFact),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
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
                      translate('back', lang),
                      style: TextStyle(
                        fontFamily: 'YesevaOne',
                        color: appTheme.onBackground,
                        fontSize: 35 * xFact,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15 * yFact),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 10 * xFact, right: 10 * xFact),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            translate('cancelsub', lang),
                            style: TextStyle(
                              fontFamily: 'YesevaOne',
                              color: appTheme.onBackground,
                              fontSize: 24 * xFact,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 20 * yFact),
                        Center(
                          child: SizedBox(
                            height: 150 * yFact,
                            child: Image.asset('assets/images/flamy/flamy_sad2.png'),
                          ),
                        ),
                        SizedBox(height: 20 * yFact),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            translate('sorryleave', lang),
                            style: TextStyle(
                              fontFamily: 'InterTight',
                              color: appTheme.onBackground,
                              fontSize: 18 * xFact,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 35 * yFact),
                        Expanded(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: kCancelReasonKeys.length,
                            separatorBuilder: (context, index) => Divider(
                              color: appTheme.onBackground,
                              thickness: 1 * yFact,
                              height: 20 * yFact,
                            ),
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10 * xFact),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      translate(kCancelReasonKeys[index], lang),
                                      style: TextStyle(
                                        color: appTheme.onBackground,
                                        fontFamily: 'InterTight',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16 * xFact,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => vm.toggleReason(index),
                                      child: RoundCheck(
                                        checked: state.isChecked[index],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    right: 20 * xFact,
                    left: 20 * xFact,
                    bottom: 30 * yFact,
                  ),
                  child: Column(
                    children: [
                      SecondaryButton(
                        text: translate('cancelsub', lang),
                        onTap: () async {
                          final result = await vm.handleCancel();
                          if (!context.mounted) return;
                          if (result.success) {
                            Navigator.pop(context, true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(translate('restore_error', lang)),
                              ),
                            );
                            Navigator.pop(context, false);
                          }
                        },
                      ),
                    ],
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

