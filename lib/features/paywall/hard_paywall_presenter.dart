import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/root_navigator.dart';
import 'package:businessmindset/features/paywall/view/paywallb_page.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/services/hard_paywall_service.dart';

/// Shows [Paywallb] in "hard paywall" mode (no back, no close button).
class HardPaywallPresenter {
  HardPaywallPresenter._();

  static void resetSessionFlag() => HardPaywallService.resetPresentScheduleFlag();

  static Future<bool> shouldEnforceNow(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final premium = ref.read(premiumProvider);
    return HardPaywallService.shouldEnforce(prefs, premium);
  }

  /// [homePageWidget]: main screen after unlock (avoids circular import with [HomePage]).
  /// Returns `true` if the forced paywall was scheduled.
  static Future<bool> presentIfEnforced(WidgetRef ref, Widget homePageWidget) async {
    if (HardPaywallService.isPresentScheduledThisSession) return false;
    final prefs = await SharedPreferences.getInstance();
    final premium = ref.read(premiumProvider);
    if (!HardPaywallService.shouldEnforce(prefs, premium)) return false;
    HardPaywallService.markPresentScheduled();
    await HardPaywallService.applyBlockingLayer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = rootNavigatorKey.currentState;
      if (nav == null) return;
      final lang = ref.read(languageProvider);
      nav.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/hardPaywall'),
          builder: (ctx) => Paywallb(
            hardPaywallMode: true,
            onHardPaywallUnlocked: () {
              HardPaywallService.resetPresentScheduleFlag();
              Navigator.of(ctx).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => homePageWidget),
                (_) => false,
              );
            },
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
            choiceList: const [],
            buttonText: 'letsgo',
          ),
        ),
        (_) => false,
      );
    });
    return true;
  }
}
