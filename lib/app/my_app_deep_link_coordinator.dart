import 'package:businessmindset/app/deep_link_channel.dart';
import 'package:businessmindset/core/root_navigator.dart';
import 'package:businessmindset/providers/cross_provider.dart';
import 'package:businessmindset/providers/habits_provider.dart' show sharedPrefsProvider;
import 'package:businessmindset/providers/user_provider.dart' show premiumProvider;
import 'package:businessmindset/services/hard_paywall_service.dart';
import 'package:businessmindset/services/share_quotes.dart';
import 'package:businessmindset/features/paywall/hard_paywall_presenter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home/view/home_page.dart';

/// Deep links widget / lock screen / partage — extraits de [MyApp] pour lisibilité.
class MyAppDeepLinkCoordinator {
  MyAppDeepLinkCoordinator({
    required this.ref,
    required this.hasOnboard,
    required this.isMounted,
  });

  final WidgetRef ref;
  final bool Function() hasOnboard;
  final bool Function() isMounted;

  String? pendingDeepLink;

  Future<void> handleLink(String? link) async {
    if (link == null) return;
    final lower = link.toLowerCase();

    final blockNavForHardPaywall = hasOnboard() &&
        HardPaywallService.shouldEnforce(
          ref.read(sharedPrefsProvider),
          ref.read(premiumProvider),
        );

    if (kDebugMode) {
      debugPrint(
        '[WidgetTap] _handleDeepLink url=$link blockNavForHardPaywall=$blockNavForHardPaywall',
      );
    }

    if (blockNavForHardPaywall) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isMounted()) return;
        HardPaywallPresenter.presentIfEnforced(ref, const HomePage());
      });
    }

    if (lower.startsWith('businessmindset://home')) {
      final uri = Uri.parse(link);
      final source = uri.queryParameters['source'];
      if (kDebugMode) {
        debugPrint('[WidgetTap] home deep link source=$source');
      }
      if (source == 'lockscreen') {
        await markOpenedFromLockScreen();
      }

      if (!blockNavForHardPaywall) {
        rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
      await markOpenedFromWidget();
      final tickNotifier = ref.read(widgetHomeDeepLinkTickProvider.notifier);
      tickNotifier.state = tickNotifier.state + 1;
      if (kDebugMode) {
        debugPrint(
          '[WidgetTap] openedFromWidget=true tick=${tickNotifier.state} (HomePage re-runs widget check)',
        );
      }
      return;
    }

    if (lower == 'businessmindset://widget/share') {
      if (blockNavForHardPaywall) return;
      scheduleWidgetShare();
      return;
    }

    if (lower.startsWith('businessmindset://widget')) {
      if (blockNavForHardPaywall) {
        pendingDeepLink = null;
        return;
      }
      pendingDeepLink = link;
      scheduleNavigationToWidgetPage();
    }
  }

  Future<void> markOpenedFromWidget() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool('openedFromWidget', true);
  }

  void scheduleNavigationToWidgetPage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isMounted() || pendingDeepLink == null) return;
      final nav = rootNavigatorKey.currentState;
      if (nav == null) return;
      nav.popUntil((route) => route.isFirst);
      nav.pushNamed('/widget');
      pendingDeepLink = null;
    });
  }

  Future<void> scheduleWidgetShare() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool('pendingWidgetShare', true);

    rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await triggerShareFromWidget();
    });
  }

  Future<void> triggerShareFromWidget() async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool('pendingWidgetShare', false);

    final storedQuote = await readWidgetStoredQuote();
    final quote = storedQuote?['quote'] as String? ?? '';

    if (quote.isEmpty) {
      await prefs.reload();
      final fallback = prefs.getString('widgetQuote') ?? '';
      if (fallback.isEmpty) {
        if (kDebugMode) {
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          debugPrint("❌ [Main] No quote available for sharing");
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        }
        return;
      }

      await shareQuote(
        fallback,
        context: context,
        ref: ref,
        signature: prefs.getString('widgetQuoteSignature'),
        bookTitle: prefs.getString('widgetQuoteBook'),
      );
      return;
    }

    await shareQuote(
      quote,
      context: context,
      ref: ref,
      signature: storedQuote?['signature'] as String?,
      bookTitle: storedQuote?['book'] as String?,
    );
  }

  void attachChannel() {
    businessmindsetDeepLinkChannel.setMethodCallHandler((call) async {
      if (call.method == 'initialLink' || call.method == 'deepLink') {
        await handleLink(call.arguments as String?);
      }
    });
  }
}
