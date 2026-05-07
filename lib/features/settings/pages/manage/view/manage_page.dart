import 'package:businessmindset/animations/transitions.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/core/root_navigator.dart';
import 'package:businessmindset/features/paywall/view/paywallb_page.dart';
import 'package:businessmindset/features/settings/pages/cancel_sub/view/cancel_sub_page.dart';
import 'package:businessmindset/features/settings/pages/manage/view_model/manage_provider.dart';
import 'package:businessmindset/features/settings/pages/manage/view_model/manage_ui_state.dart';
import 'package:businessmindset/features/settings/pages/sigin/view/sigin_page.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManagePage extends ConsumerStatefulWidget {
  const ManagePage({super.key});

  @override
  ConsumerState<ManagePage> createState() => _ManagePagePageState();
}

class _ManagePagePageState extends ConsumerState<ManagePage> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(manageViewModelProvider.notifier).init());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.microtask(() => ref.read(manageViewModelProvider.notifier).maybeRefreshAfterResume());
  }

  Future<void> _handleRestorePurchase() async {
    final lang = ref.read(languageProvider);
    final outcome = await ref.read(manageViewModelProvider.notifier).handleRestorePurchase();
    if (!mounted) return;
    final message = switch (outcome) {
      RestorePurchaseOutcome.success => translate('restore_success', lang),
      RestorePurchaseOutcome.notFound => translate('restore_not_found', lang),
      RestorePurchaseOutcome.error => translate('restore_error', lang),
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void showCancelPremiumDialog(
    BuildContext context, {
    String titleFont = "YesevaOne",
    String bodyFont = "InterTight",
    VoidCallback? onSecondary,
    String lang = "en",
  }) {
    showGeneralDialog(
      context: context,
      barrierLabel: "skip-premium",
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
                      padding: EdgeInsets.only(left: 25 * xFact, right: 25 * xFact, bottom: 5 * yFact),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              SizedBox(height: 50 * yFact),
                              SizedBox(
                                height: 100 * yFact,
                                child: Image.asset("assets/images/flamy/flamy_sad.png"),
                              ),
                              Text(
                                translate("aresure", lang),
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
                                translate("aresuresubtitle", lang),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: bodyFont,
                                  fontSize: 18 * xFact,
                                  color: appTheme.onBackground,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              PrimaryButton(
                                text: translate("keepsub", lang),
                                onTap: () => Navigator.of(ctx).pop(),
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
                                  onSecondary?.call();
                                },
                                child: Text(translate("cancelsub", lang)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 10 * yFact,
                      left: 10 * xFact,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        color: appTheme.onBackground,
                        onPressed: () => Navigator.of(ctx).pop(),
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isPremium = ref.watch(premiumProvider);
    final ui = ref.watch(manageViewModelProvider);
    final vm = ref.read(manageViewModelProvider.notifier);

    Widget infoButton(String title, String subTitle) {
      return Container(
        width: double.maxFinite,
        decoration: BoxDecoration(color: appTheme.settingsButton),
        child: Padding(
          padding: EdgeInsets.only(left: 10 * xFact, right: 10 * xFact, top: 12 * yFact, bottom: 12 * yFact),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                translate(title, lang),
                style: TextStyle(
                  color: appTheme.onBackground,
                  fontFamily: "InterTight",
                  fontSize: 18 * xFact,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                translate(subTitle, lang),
                style: TextStyle(
                  color: appTheme.lowButtonGold,
                  fontFamily: "InterTight",
                  fontSize: 18 * xFact,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: appTheme.background),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10 * xFact),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.arrow_back_ios, color: appTheme.onBackground, size: 30 * xFact),
                          ),
                          SizedBox(width: 5 * xFact),
                          Text(
                            translate("managesub", lang),
                            style: TextStyle(
                              fontFamily: "YesevaOne",
                              color: appTheme.onBackground,
                              fontSize: 35 * xFact,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30 * yFact),
                    if (isPremium)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10 * xFact),
                        child: Column(
                          children: [
                            infoButton("period", ui.currentPeriod),
                            SizedBox(height: 2 * yFact),
                            infoButton("type", ui.currentType),
                            SizedBox(height: 2 * yFact),
                            if (ui.isTrialPeriod) ...[
                              infoButton("tends", ui.currentTEnd),
                              SizedBox(height: 2 * yFact),
                              infoButton("substart", ui.currentSubStart),
                            ] else ...[
                              infoButton("started_on", ui.currentStartedOn),
                              SizedBox(height: 2 * yFact),
                              infoButton(ui.isCancelled ? "subscription_ends" : "next_renewal", ui.currentNextRenewal),
                            ],
                          ],
                        ),
                      )
                    else
                      Text(
                        translate("notpremiumsub", lang),
                        style: TextStyle(
                          fontFamily: "InterTight",
                          color: appTheme.onBackground,
                          fontSize: 16 * xFact,
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(right: 20 * xFact, left: 20 * xFact, bottom: 30 * yFact),
                  child: isPremium
                      ? (ui.isCancelled
                          ? PrimaryButton(
                              text: translate("renew_subscription", lang),
                              onTap: () {
                                Navigator.of(context).push(
                                  sharedAxisFromRight(
                                    Paywallb(
                                      pageStyle: "declare",
                                      backIcon: true,
                                      skipLink: false,
                                      choiceList: const [],
                                      title: translate("onboardingtitle3", lang),
                                      subTitle: translate("onboardingsubtitle3", lang),
                                      buttonText: "letsgo",
                                      forward1: () async {
                                        final rootContext = rootNavigatorKey.currentContext;
                                        if (rootContext != null) Navigator.of(rootContext).pop();
                                        await vm.refreshPremiumState();
                                      },
                                      forward2: () async {
                                        final rootContext = rootNavigatorKey.currentContext;
                                        if (rootContext != null) {
                                          final rootNavigator = Navigator.of(rootContext);
                                          rootNavigator.pop();
                                          await vm.refreshPremiumState();
                                          rootNavigator.push(sharedAxisFromRight(const SyncPage()));
                                        }
                                      },
                                      backward: () {
                                        final rootContext = rootNavigatorKey.currentContext;
                                        if (rootContext != null) Navigator.of(rootContext).pop();
                                      },
                                    ),
                                  ),
                                );
                              },
                            )
                          : SecondaryButton(
                              text: translate("cancelsub", lang),
                              onTap: () {
                                showCancelPremiumDialog(
                                  context,
                                  lang: lang,
                                  onSecondary: () async {
                                    final shouldRefresh = await Navigator.of(context).push<bool>(
                                      sharedAxisFromRight(const CancelSubPage()),
                                    );
                                    if (shouldRefresh == true) {
                                      await vm.pollForCancellationStatus();
                                    }
                                  },
                                );
                              },
                            ))
                      : Column(
                          children: [
                            PrimaryButton(
                              text: translate("upgradeprem", lang),
                              onTap: () {
                                Navigator.of(context).push(
                                  sharedAxisFromRight(
                                    Paywallb(
                                      pageStyle: "declare",
                                      backIcon: true,
                                      skipLink: false,
                                      choiceList: const [],
                                      title: translate("onboardingtitle3", lang),
                                      subTitle: translate("onboardingsubtitle3", lang),
                                      buttonText: "letsgo",
                                      forward1: () async {
                                        final rootContext = rootNavigatorKey.currentContext;
                                        if (rootContext != null) Navigator.of(rootContext).pop();
                                        await vm.refreshPremiumState();
                                      },
                                      forward2: () async {
                                        final rootContext = rootNavigatorKey.currentContext;
                                        if (rootContext != null) {
                                          final rootNavigator = Navigator.of(rootContext);
                                          rootNavigator.pop();
                                          await vm.refreshPremiumState();
                                          rootNavigator.push(sharedAxisFromRight(const SyncPage()));
                                        }
                                      },
                                      backward: () {
                                        final rootContext = rootNavigatorKey.currentContext;
                                        if (rootContext != null) Navigator.of(rootContext).pop();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 10 * yFact),
                            GestureDetector(
                              onTap: _handleRestorePurchase,
                              child: Text(
                                translate("restorep", lang),
                                style: TextStyle(
                                  fontFamily: "InterTight",
                                  color: appTheme.onBackground,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 22 * xFact,
                                ),
                              ),
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

