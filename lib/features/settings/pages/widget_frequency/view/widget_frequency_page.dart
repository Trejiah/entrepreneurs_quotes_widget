import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/data/widget_frequency.dart';
import 'package:businessmindset/features/paywall/view/paywallb_page.dart';
import 'package:businessmindset/features/settings/pages/widget_frequency/view_model/widget_frequency_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WidgetFrequencyPage extends ConsumerStatefulWidget {
  const WidgetFrequencyPage({super.key});

  @override
  ConsumerState<WidgetFrequencyPage> createState() => _WidgetFrequencyPageState();
}

class _WidgetFrequencyPageState extends ConsumerState<WidgetFrequencyPage> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          ref.read(widgetFrequencyViewModelProvider.notifier).loadInitialSelection(),
    );
  }

  Future<void> _showPremiumDialog() async {
    final lang = ref.read(languageProvider);
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'widget-premium-frequency',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      pageBuilder: (context, _, __) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return Opacity(
          opacity: curved.value,
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF575757),
                    borderRadius: BorderRadius.circular(18 * xFact),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24 * xFact, vertical: 20 * yFact),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            color: appTheme.onBackground,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        SizedBox(
                          height: 130 * yFact,
                          child: Image.asset('assets/images/flamme.png'),
                        ),
                        SizedBox(height: 20 * yFact),
                        Text(
                          translate('premium_frequency_title', lang),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'YesevaOne',
                            fontSize: 26 * xFact,
                            color: appTheme.onBackground,
                          ),
                        ),
                        SizedBox(height: 16 * yFact),
                        Text(
                          translate('premium_frequency_body', lang),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'InterTight',
                            fontSize: 18 * xFact,
                            color: appTheme.onBackground,
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: 24 * yFact),
                        PrimaryButton(
                          text: translate('go_premium', lang),
                          icon: Icons.arrow_right_alt,
                          iconSize: 40 * xFact,
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => Paywallb(
                                  pageStyle: 'check2',
                                  backIcon: true,
                                  skipLink: false,
                                  title: translate('Premium', lang),
                                  subTitle: translate('unlockquotes', lang),
                                  choiceList: const [],
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 12 * yFact),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: appTheme.onBackground,
                            textStyle: TextStyle(
                              fontFamily: 'InterTight',
                              fontSize: 18 * xFact,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(translate('cancel', lang)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final premium = ref.watch(premiumProvider);
    final ui = ref.watch(widgetFrequencyViewModelProvider);
    final vm = ref.read(widgetFrequencyViewModelProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: appTheme.background),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10 * yFact),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: appTheme.onBackground,
                        size: 30 * xFact,
                      ),
                    ),
                    SizedBox(width: 10 * xFact),
                    Text(
                      translate('update_frequency_title', lang),
                      style: TextStyle(
                        fontFamily: 'YesevaOne',
                        color: appTheme.onBackground,
                        fontSize: 32 * xFact,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8 * yFact),
                Text(
                  translate('update_frequency_subtitle', lang),
                  style: TextStyle(
                    fontFamily: 'InterTight',
                    color: appTheme.onBackground,
                    fontSize: 18 * xFact,
                  ),
                ),
                SizedBox(height: 20 * yFact),
                Expanded(
                  child: ui.loading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(appTheme.lowButtonGold),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: widgetFrequencyOptions.length,
                          itemBuilder: (context, index) {
                            final option = widgetFrequencyOptions[index];
                            final selected = option.id == ui.selectedId;
                            final isDisabled = option.requiresPremium && !premium;
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * xFact,
                                vertical: 6 * yFact,
                              ),
                              child: TertiaryCheckButton(
                                text: translate(option.localizationKey, lang),
                                checked: selected,
                                onChanged: (_) async {
                                  if (isDisabled) {
                                    await _showPremiumDialog();
                                  } else {
                                    vm.selectOption(option);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
                SizedBox(height: 20 * yFact),
                SecondaryButton(
                  text: translate('save', lang),
                  onTap: () async {
                    final selected = await vm.saveAndSync();
                    if (!context.mounted || selected == null) return;
                    Navigator.of(context).pop(selected);
                  },
                ),
                SizedBox(height: 20 * yFact),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

