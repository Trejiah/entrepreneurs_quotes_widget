import 'dart:async';

import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/settings/model/settings_models.dart';
import 'package:businessmindset/features/settings/model/settings_outcome.dart';
import 'package:businessmindset/features/settings/view_model/settings_provider.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/features/paywall/view/paywallb_page.dart';
import 'package:businessmindset/features/settings/pages/app_ordered_quotes/view/app_ordered_quotes_page.dart';
import 'package:businessmindset/features/settings/pages/choose_quote/view/choose_quote_page.dart';
import 'package:businessmindset/features/settings/pages/gender/view/gender_page.dart';
import 'package:businessmindset/features/settings/pages/language/view/language_page.dart';
import 'package:businessmindset/features/settings/pages/lockscreen_choice/view/lockscreen_choice_page.dart';
import 'package:businessmindset/features/settings/pages/manage/view/manage_page.dart';
import 'package:businessmindset/features/settings/pages/my_favorite_tones/view/my_favorite_tones_page.dart';
import 'package:businessmindset/features/settings/pages/my_feed/view/my_feed_page.dart';
import 'package:businessmindset/features/settings/pages/name/view/name_page.dart';
import 'package:businessmindset/features/settings/pages/notification/view/notification_page.dart';
import 'package:businessmindset/features/settings/pages/notifications_choice/view/notifications_choice_page.dart';
import 'package:businessmindset/features/settings/pages/sigin/view/sigin_page.dart';
import 'package:businessmindset/features/settings/pages/widget/view/widget_page.dart';
import 'package:businessmindset/animations/transitions.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  late final ScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();
    Future.microtask(
      () => ref.read(settingsViewModelProvider.notifier).loadPackageInfo(),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _handleBackNavigation() => true;

  void _showPaywall(BuildContext context, String lang) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Paywallb(
          pageStyle: 'notdeclare',
          backIcon: true,
          skipLink: false,
          backward: () {},
          forward1: () {
            ref.read(premiumProvider.notifier).state = true;
          },
          forward2: () {},
          title: translate('onboardingtitle3', lang),
          subTitle: translate('onboardingsubtitle3', lang),
          choiceList: [],
          buttonText: 'letsgo',
        ),
      ),
    );
  }

  void _pushDestination(BuildContext context, SettingsNavDestination destination) {
    switch (destination) {
      case SettingsNavDestination.myFeed:
        Navigator.of(context).push(sharedAxisFromRight(const MyFeed()));
        break;
      case SettingsNavDestination.myFavoriteTones:
        Navigator.of(context).push(sharedAxisFromRight(const MyFavoriteTones()));
        break;
      case SettingsNavDestination.notifications:
        Navigator.of(context).push(sharedAxisFromRight(NotificationPage()));
        break;
      case SettingsNavDestination.widgetPage:
        Navigator.of(context).push(sharedAxisFromRight(WidgetPage()));
        break;
      case SettingsNavDestination.namePage:
        Navigator.of(context).push(sharedAxisFromRight(NamePage()));
        break;
      case SettingsNavDestination.genderPage:
        Navigator.of(context).push(sharedAxisFromRight(GenderPage()));
        break;
      case SettingsNavDestination.languagePage:
        Navigator.of(context).push(sharedAxisFromRight(LanguagePage()));
        break;
      case SettingsNavDestination.managePage:
        Navigator.of(context).push(sharedAxisFromRight(ManagePage()));
        break;
      case SettingsNavDestination.signInPage:
        Navigator.of(context).push(sharedAxisFromRight(SyncPage()));
        break;
      case SettingsNavDestination.chooseQuote:
        Navigator.of(context).push(sharedAxisFromRight(const ChooseQuotePage()));
        break;
      case SettingsNavDestination.lockscreenChoice:
        Navigator.of(context).push(sharedAxisFromRight(const LockscreenChoicePage()));
        break;
      case SettingsNavDestination.notificationsChoice:
        Navigator.of(context)
            .push(sharedAxisFromRight(const NotificationsChoicePage()));
        break;
      case SettingsNavDestination.appOrderedQuotes:
        Navigator.of(context).push(sharedAxisFromRight(const AppOrderedQuotesPage()));
        break;
    }
  }

  Future<void> _applyOutcome(
    BuildContext tapContext,
    SettingsOutcome outcome,
    String lang,
  ) async {
    final notifier = ref.read(settingsViewModelProvider.notifier);
    switch (outcome) {
      case SettingsOutcomePaywall():
        _showPaywall(tapContext, lang);
        break;
      case SettingsOutcomeNavigate(:final destination):
        _pushDestination(tapContext, destination);
        break;
      case SettingsOutcomeShare():
        final box = tapContext.findRenderObject() as RenderBox?;
        final origin =
            box != null ? box.localToGlobal(Offset.zero) & box.size : null;
        await notifier.shareApp(lang: lang, sharePositionOrigin: origin);
        break;
      case SettingsOutcomeOpenStoreReview():
        await notifier.openStoreForReview();
        break;
      case SettingsOutcomeOpenMail():
        await notifier.openContactMail();
        break;
      case SettingsOutcomeOpenPrivacy():
        await notifier.openPrivacyPage();
        break;
      case SettingsOutcomeOpenTerms():
        await notifier.openTermsPage();
        break;
    }
  }

  Widget _buildSection({
    required String titleKey,
    required List<SettingItemData> items,
    required String lang,
    required bool premium,
  }) {
    final notifier = ref.read(settingsViewModelProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            translate(titleKey, lang),
            style: TextStyle(
              fontFamily: 'InterTight',
              color: appTheme.onBackground,
              fontSize: 22 * xFact,
            ),
          ),
        ),
        SizedBox(height: 5 * yFact),
        ClipRRect(
          borderRadius: BorderRadius.circular(10 * xFact),
          child: Column(
            children: List.generate(items.length * 2 - 1, (i) {
              if (i.isOdd) {
                return SizedBox(height: 2 * yFact);
              }
              final item = items[i ~/ 2];
              final isLocked = !premium &&
                  (item.action == SettingAction.myFavoriteTones ||
                      item.action == SettingAction.myPersonalizedFeed);
              return Builder(
                builder: (tapContext) {
                  return SettingsButton(
                    icon: item.icon,
                    label: translate(item.labelKey, lang),
                    fontFamily: 'InterTight',
                    fontSize: 22,
                    color: appTheme.onBackground,
                    isLocked: isLocked,
                    onTap: () {
                      final outcome =
                          notifier.outcomeFor(item.action, premium: premium);
                      unawaited(_applyOutcome(tapContext, outcome, lang));
                    },
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(premiumProvider);
    final lang = ref.watch(languageProvider);
    final userName = ref.watch(userNameStateProvider);
    final themeIndex = ref.watch(themeIndexProvider);
    final isCustomTheme = ref.watch(isCustomThemeProvider);
    final settingsUi = ref.watch(settingsViewModelProvider);

    final includeDebugMenu = kDebugMode || kProfileMode;
    final sections = buildSettingsSections(includeDebugMenu: includeDebugMenu);

    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📋 [Settings] Settings page loaded');
      debugPrint('   - premium: $premium');
      debugPrint('   - language: $lang');
      debugPrint('   - userName: $userName');
      debugPrint('   - themeIndex: $themeIndex');
      debugPrint('   - isCustomTheme: $isCustomTheme');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    return PopScope(
      canPop: _handleBackNavigation(),
      onPopInvokedWithResult: (didPop, _) async {
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
                padding: EdgeInsets.symmetric(horizontal: 10 * xFact),
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
                          child: Icon(
                            Icons.close,
                            color: appTheme.onBackground,
                            size: 40 * xFact,
                          ),
                        ),
                        SizedBox(width: 10 * xFact),
                        Text(
                          translate('Settings', lang),
                          style: TextStyle(
                            fontFamily: 'YesevaOne',
                            color: appTheme.onBackground,
                            fontSize: 35 * xFact,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 22 * yFact),
                    Expanded(
                      child: Scrollbar(
                        controller: _ctrl,
                        thumbVisibility: true,
                        child: ListView.separated(
                          controller: _ctrl,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(right: 10 * xFact),
                          itemCount: sections.length + 1,
                          separatorBuilder: (_, __) => SizedBox(height: 35 * yFact),
                          itemBuilder: (context, index) {
                            if (index < sections.length) {
                              final s = sections[index];
                              return _buildSection(
                                titleKey: s.titleKey,
                                items: s.items,
                                lang: lang,
                                premium: premium,
                              );
                            }
                            return Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(right: 10 * xFact),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          style: TextStyle(
                                            fontFamily: 'InterTight',
                                            fontSize: 18 * xFact,
                                            color: appTheme.onBackground,
                                          ),
                                          children: [
                                            TextSpan(text: translate('Version ', lang)),
                                            TextSpan(text: settingsUi.appVersion),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20 * yFact),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
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
