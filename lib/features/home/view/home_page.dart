import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/features/mindset_points/view/mindset_points_page.dart';
import 'package:businessmindset/features/settings/view/settings_page.dart';
import 'package:businessmindset/features/themes/view/themes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:businessmindset/animations/transitions.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/features/paywall/view/paywallb_page.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/features/home/view/widgets/home_background.dart';
import 'package:businessmindset/features/home/view_model/home_notifications_coordinator.dart';
import 'package:businessmindset/features/home/view_model/home_premium_coordinator.dart';
import 'package:businessmindset/features/home/view_model/home_theme_coordinator.dart';
import 'package:businessmindset/features/home/view_model/home_topics_coordinator.dart';
import 'package:businessmindset/features/home/view_model/home_quote_provider.dart';
import 'package:businessmindset/features/home/view_model/home_view_model.dart';
import 'package:businessmindset/features/home/view_model/home_widget_coordinator.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/services/share_quotes.dart';
import 'package:businessmindset/features/favorites/view/favorites_page.dart';
import 'package:businessmindset/features/home/widgets/point_increment.dart';
import 'package:businessmindset/services/notification_service.dart';
import 'package:businessmindset/services/mindset_points_service.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/services/tiktok_service.dart';
import 'package:businessmindset/services/revenuecat_service.dart';
import 'package:businessmindset/services/review_popup_service.dart';
import 'package:businessmindset/widgets/review_popup_widget.dart';
import 'package:businessmindset/features/paywall/view/paywall_promo.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:businessmindset/providers/cross_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with TickerProviderStateMixin, WidgetsBindingObserver {
  // Native channel shared with the iOS widget
  static const MethodChannel _widgetChannel = MethodChannel('businessmindset/deeplink');

  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  static const double kMinVel = 650; // inertie (px/s)

  // Drag / anim
  double _offsetY = 0.0;  // suit le doigt ou l'anim
  late AnimationController _animCtrl;
  Animation<double>? _anim;
  bool _animating = false;
  StreamSubscription<NotificationQuotePayload>? _notificationSubscription;

  // Animation "+1"
  final List<PointIncrementAnimation> _activeAnimations = [];
  StreamSubscription<String>? _pointsIncrementSubscription;
  
  // Listener for RevenueCat subscription events
  StreamSubscription<SubscriptionEvent>? _subscriptionEventSubscription;
  
  // Timer for periodic subscription check
  Timer? _subscriptionCheckTimer;
  ProviderSubscription<bool>? _premiumProviderSubscription;

  late AnimationController _tutorialArrowsAnimCtrl;

  // Keys to get positions
  final GlobalKey _quoteKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();

  // Computed position of the signature (below the quote)
  double? _signatureTopPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(homeViewModelProvider.notifier).setReady(false);
    });
    WidgetsBinding.instance.addObserver(this);
    _applyImmersiveSystemUI();
    // Re-hide the bottom nav bar after the user swipes to reveal it.
    SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
      if (systemOverlaysAreVisible && mounted) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _applyImmersiveSystemUI();
        }
      }
    });
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 240))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
          _animating = false;
        }
      });
    
    // Arrow animation for the tutorial
    _tutorialArrowsAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    
    _loadPrefs().catchError((error, stackTrace) {
      // On error, mark as ready anyway to avoid a blank screen
      if (mounted) {
        ref.read(homeViewModelProvider.notifier).setReady(true);
      }
    });
    _listenToNotificationPayloads();
    _listenToWidgetDeepLink();
    _listenToPointsIncrements();
    _listenToSubscriptionEvents();
    _startPeriodicSubscriptionCheck();
    _setupPremiumListener();
    ref.read(homeNotificationsCoordinatorProvider).markAppOpenedForReviewPrompt();
  }

  void _setupPremiumListener() {
    _premiumProviderSubscription?.close();
    _premiumProviderSubscription = ref.listenManual<bool>(premiumProvider, (previous, next) {
      if (previous == next) return;
      if (kDebugMode) {
        debugPrint(
          '[WidgetTap] premiumProvider changed: $previous -> $next, syncing widget now',
        );
      }
      unawaited(
        ref.read(homePremiumCoordinatorProvider).afterPremiumFlagChanged(
              previous: previous,
              next: next,
              refreshWidget: _refreshWidgetiOS,
              onBecamePremium: _onBecamePremium,
            ),
      );
    });
  }

  void _applyImmersiveSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setSystemUIChangeCallback(null);
    _animCtrl.dispose();
    _tutorialArrowsAnimCtrl.dispose();
    _notificationSubscription?.cancel();
    _pointsIncrementSubscription?.cancel();
    _subscriptionEventSubscription?.cancel();
    _subscriptionCheckTimer?.cancel();
    _premiumProviderSubscription?.close();
    super.dispose();
  }
  
  void _listenToPointsIncrements() {
    _pointsIncrementSubscription = MindsetPointsService.instance.onIncrement.listen((type) {
      if (mounted) {
        setState(() {
          _activeAnimations.add(PointIncrementAnimation(
            key: UniqueKey(),
            type: type,
            controller: AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: 1500),
            ),
          ));
          final animKey = _activeAnimations.last.key;
          _activeAnimations.last.controller.forward().then((_) {
            if (mounted) {
              setState(() {
                _activeAnimations.removeWhere((anim) => anim.key == animKey);
              });
            }
          });
        });
      }
    });
  }
  
  void _listenToSubscriptionEvents() {
    _subscriptionEventSubscription = RevenueCatService.instance.onSubscriptionEvent.listen((event) {
      if (!mounted) return;
      unawaited(
        ref.read(homePremiumCoordinatorProvider).onSubscriptionStreamEvent(
              event: event,
              ref: ref,
              isMounted: () => mounted,
              homePageWidget: const HomePage(),
              onPremiumExpiredRepair: _handleSubscriptionExpired,
              onBecamePremiumContent: _onBecamePremium,
            ),
      );
    });
  }
  
  /// Start the periodic subscription state check
  void _startPeriodicSubscriptionCheck() {
    // Cancel the existing timer if any
    _subscriptionCheckTimer?.cancel();
    
    // Check every 5 minutes
    _subscriptionCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkSubscriptionStatePeriodically(),
    );
    
    }
  
  /// Check subscription state periodically.
  /// [Subscription] Cancelled: only when willRenew=false (cancel), not when the subscription ends (expiration).
  Future<void> _checkSubscriptionStatePeriodically() async {
    await ref.read(homePremiumCoordinatorProvider).onPeriodicSubscriptionPoll(
          ref: ref,
          isMounted: () => mounted,
          homePageWidget: const HomePage(),
          onLostPremiumRepair: _handleSubscriptionExpired,
        );
  }

  /// Handle subscription expiration: validate topics and regenerate a quote
  Future<void> _handleSubscriptionExpired() async {
    try {
      if (!mounted) return;
      
      // Validate and fix selected topics (may reset to "general" if needed)
      await _validateAndFixSelectedTopics();
      
      // Regenerate a quote with the new topics
      if (mounted && ref.read(homeViewModelProvider).isReady) {
        final lang = ref.read(languageProvider);
        final newQuoteData =
            await ref.read(homeQuoteViewModelProvider.notifier).getRandomQuoteFromTopics(lang);
        if (mounted) {
          await ref
              .read(homeQuoteViewModelProvider.notifier)
              .applySubscriptionExpiredRegeneration(newQuoteData);
          if (mounted) {
            setState(() => _signatureTopPosition = null);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HomePage] _handleSubscriptionExpired failed: $e');
      }
    }
  }

  /// Validate and fix selected topics based on premium status
  Future<void> _validateAndFixSelectedTopics() async {
    await ref.read(homeQuoteViewModelProvider.notifier).validateAndFixSelectedTopics();
  }

  /// Pushes widget data to native when **widget topics** were corrected on
  /// resume (e.g. premium change) — same idea as iOS. Does **not** set
  /// [widgetConfigured]; that flag is written only when [WidgetPage] opens
  /// (`_markWidgetAsConfigured`), which is also what turns off "Tap to configure".
  Future<void> _refreshWidgetiOS() async {
    try {
      await ref.read(homeWidgetCoordinatorProvider).refreshWidgetData(_widgetChannel);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("❌ [HomePage] Error while updating the widget (topics correction)");
        debugPrint("   - Error: $e");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
    }
  }

  Future<void> _loadPrefs() async {
    final lang = ref.read(languageProvider);
    final prefs = await SharedPreferences.getInstance();
    
    // Initialize day/week resets at app launch
    await ref.read(homeNotificationsCoordinatorProvider).initializePointsDayWeekResets();

    ref.read(homeViewModelProvider.notifier).hydrateTutorialFromPrefs(prefs);
    if (ref.read(homeViewModelProvider).showTutorial) {
      _tutorialArrowsAnimCtrl.repeat();
    } else {
      // User already onboarded: init TikTok after 5s (tutorial already finished)
      _initTikTokAfterDelay();
    }

    // Validate and fix selected topics
    await _validateAndFixSelectedTopics();

    // Summary log of loaded values
    // Load favorites BEFORE first random quote so favoritesGlobal is available
    await ref.read(homeQuoteViewModelProvider.notifier).loadStoredQuotes(updatePersistedHistory: false);

    // Check whether the daily limit is already reached at launch
    final limitAlreadyReached =
        await ref.read(homeViewModelProvider.notifier).checkDailyQuoteLimit();

    final quoteNotifier = ref.read(homeQuoteViewModelProvider.notifier);
    if (!limitAlreadyReached) {
      final firstData = await quoteNotifier.getRandomQuoteFromTopics(lang);
      quoteNotifier.seedFirstQuoteOfSession(firstData);
      _signatureTopPosition = null;
      await quoteNotifier.trackNewQuoteViewed();
    } else {
      // Limit reached: no generation, empty history
      quoteNotifier.clearSessionQuotesForDailyLimit();
      _signatureTopPosition = null;
    }
    
    await ref.read(homeThemeCoordinatorProvider).preloadCustomBackgroundIfNeeded();
    if (limitAlreadyReached) {
      ref.read(homeViewModelProvider.notifier).markDailyLimitAtLaunch();
    }
    ref.read(homeViewModelProvider.notifier).setReady(true);
    _consumePendingNotificationPayloadIfAny();
    
    // Remove the justCompletedOnboarding flag if present
    final justCompletedOnboarding = prefs.getBool("justCompletedOnboarding") ?? false;
    if (justCompletedOnboarding) {
      await prefs.setBool("justCompletedOnboarding", false);
    }

    if (await ref
        .read(homePremiumCoordinatorProvider)
        .presentHardPaywallIfEnforced(ref, const HomePage())) {
      await _checkPendingWidgetShare();
      return;
    }

    // Check whether to show PaywallPromo (4th day since refusal)
    await _checkAndShowPromoPaywall();
    
    // Check whether a quote was selected from ChooseQuotePage
    await ref.read(homeQuoteViewModelProvider.notifier).consumeSelectedQuoteFromChoosePage(
          isMounted: () => mounted,
          onQuoteApplied: _onQuoteLayoutRefreshNeeded,
        );
    
    // Check whether the app was opened from the widget (case where the app starts from the widget)
    if (kDebugMode) {
      debugPrint(
        '[WidgetTap] _loadPrefs end: openedFromWidget=${prefs.getBool('openedFromWidget')} → _checkIfOpenedFromWidget',
      );
    }
    await ref.read(homeQuoteViewModelProvider.notifier).checkIfOpenedFromWidget(
          _widgetChannel,
          isMounted: () => mounted,
          onWidgetQuoteApplied: _onQuoteLayoutRefreshNeeded,
        );
    if (!mounted) return;
    
    // Check whether to trigger share from the widget
    await _checkPendingWidgetShare();
  }
  
  Future<void> _checkPendingWidgetShare() async {
    try {
      final pendingShare =
          await ref.read(homeWidgetCoordinatorProvider).consumePendingWidgetShareFlag();
      if (pendingShare) {
        if (!mounted) return;

        // Trigger share with the current quote
        final qs = ref.read(homeQuoteViewModelProvider);
        final signature = qs.currentQuoteData?["signature"] as String?;
        final bookTitle = qs.currentQuoteData?["bookTitle"] as String?;

        await shareQuote(
          qs.currentQuote,
          context: context,
          ref: ref,
          signature: signature,
          bookTitle: bookTitle,
        );
      }
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("⚠️ [HomePage] Error while checking share from widget");
        debugPrint("   Message: $error");
        debugPrint("   Stack: $stack");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
    }
  }
  
  Future<void> _checkAndShowPromoPaywall() async {
    final eligible = await ref
        .read(homePremiumCoordinatorProvider)
        .preparePromoPaywallNavigationIfEligible();
    if (!eligible || !mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PaywallPromo(),
        opaque: false,
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }
  
  Future<void> _completeTutorial() async {
    await ref.read(homeViewModelProvider.notifier).completeTutorial();
    _initTikTokAfterDelay();
  }

  /// Initialize the TikTok SDK 5s after tutorial end (or after load for already-onboarded users).
  /// On iOS, show the ATT popup BEFORE SDK init to comply with Apple guidelines:
  /// no tracking data is collected before the user's consent.
  void _initTikTokAfterDelay() {
    Future.delayed(const Duration(seconds: 5), () async {
      if (!mounted) return;
      try {
        // On iOS: show the ATT popup BEFORE initializing the TikTok SDK.
        // The popup appears only once (notDetermined status); after that iOS won't show it again.
        if (!kIsWeb && Platform.isIOS) {
          final wasNotDetermined = await TikTokService.instance.getATTStatus() == 'not_determined';
          final attStatus = await TikTokService.instance.requestATT();
          // Mixpanel: only the first time the user makes the choice (popup shown).
          if (mounted && wasNotDetermined) {
            MixpanelService.instance.track('[ATT] Statut', {'status': attStatus});
          }
        }
        if (!mounted) return;
        await TikTokService.instance.init();
        TikTokService.instance.trackLaunchApp();
      } catch (_) {}
    });
  }
  
  void _nextTutorialPhase() {
    ref.read(homeViewModelProvider.notifier).nextTutorialPhase();
  }

  void _onQuoteLayoutRefreshNeeded() {
    if (mounted) {
      setState(() => _signatureTopPosition = null);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check whether a quote was selected when the page becomes visible again
    if (ref.read(homeViewModelProvider).isReady &&
        !ref.read(homeQuoteViewModelProvider.notifier).isCheckingSelectedQuote) {
      ref.read(homeQuoteViewModelProvider.notifier).consumeSelectedQuoteFromChoosePage(
            isMounted: () => mounted,
            onQuoteApplied: _onQuoteLayoutRefreshNeeded,
          );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _consumePendingNotificationPayloadIfAny();
      unawaited(ref.read(homeNotificationsCoordinatorProvider).rescheduleNotificationsFromHabits());

      // MUST be sequential: previously _checkIfOpenedFromWidget and
      // _checkSubscriptionStateOnResume ran in parallel — RevenueCat + topic
      // validation could call setState with a new random quote right after we
      // loaded the widget quote (double "flash" of different citations).
      unawaited(_onHomePageForegroundResume());
    }
  }

  /// Runs after [AppLifecycleState.resumed] in order: widget deep-link handling,
  /// choose-quote page, then subscription/topics (cannot race each other).
  Future<void> _onHomePageForegroundResume() {
    return ref.read(homeQuoteViewModelProvider.notifier).onHomeForegroundResume(
          _widgetChannel,
          isMounted: () => mounted,
          onQuoteLayoutRefreshNeeded: _onQuoteLayoutRefreshNeeded,
          refreshWidgetData: _refreshWidgetiOS,
          presentHardPaywallIfNeeded: () async {
            if (mounted && ref.read(homeViewModelProvider).isReady) {
              await ref
                  .read(homePremiumCoordinatorProvider)
                  .presentHardPaywallIfEnforced(ref, const HomePage());
            }
          },
        );
  }

  Future<void> _handleWidgetDeepLinkTick() {
    return ref.read(homeQuoteViewModelProvider.notifier).handleWidgetDeepLinkTick(
          _widgetChannel,
          isMounted: () => mounted,
          onQuoteLayoutRefreshNeeded: _onQuoteLayoutRefreshNeeded,
          refreshWidgetData: _refreshWidgetiOS,
          presentHardPaywallIfNeeded: () async {
            if (mounted && ref.read(homeViewModelProvider).isReady) {
              await ref
                  .read(homePremiumCoordinatorProvider)
                  .presentHardPaywallIfEnforced(ref, const HomePage());
            }
          },
        );
  }
  
  void _listenToNotificationPayloads() {
    final initial = NotificationService.instance.consumeInitialPayload();
    if (initial != null) {
      ref.read(homeViewModelProvider.notifier).setPendingNotificationPayload(initial);
    }

    _notificationSubscription = NotificationService.instance.onNotificationTap.listen((payload) async {
      if (!mounted) return;
      if (!ref.read(homeViewModelProvider).isReady) {
        ref.read(homeViewModelProvider.notifier).setPendingNotificationPayload(payload);
        return;
      }
      await _applyNotificationPayload(payload);
    });
  }
  
  void _listenToWidgetDeepLink() {
    // The openedFromWidget flag is handled via SharedPreferences in main.dart
    // No handler needed here
  }
  
  Future<void> _applyNotificationPayload(NotificationQuotePayload payload) async {
    await ref.read(homeQuoteViewModelProvider.notifier).applyNotificationQuotePayload(payload);
    if (mounted) {
      setState(() => _signatureTopPosition = null);
    }
  }

  void _consumePendingNotificationPayloadIfAny() {
    NotificationQuotePayload? pending =
        ref.read(homeViewModelProvider).pendingNotificationPayload;
    var consumedFromServiceQueue = false;
    if (pending == null) {
      pending = NotificationService.instance.consumePendingTapPayload();
      if (pending != null) {
        consumedFromServiceQueue = true;
      }
    }

    if (pending == null) return;

    ref.read(homeViewModelProvider.notifier).setPendingNotificationPayload(null);
    final payloadToApply = pending;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _applyNotificationPayload(payloadToApply);
      if (!consumedFromServiceQueue) {
        // Synchronise service queue with locally stored payloads
        final discarded = NotificationService.instance.consumePendingTapPayload();
        if (discarded != null) {
          // Duplicate payload discarded, no log needed
        }
      }
    });
  }

  // ————— Utils anim —————
  void _animateOffset({
    required double from,
    required double to,
    int? ms,
    Curve curve = Curves.easeOutCubic,
    VoidCallback? onEnd,
  }) {
    _animating = true;
    _animCtrl.duration = Duration(milliseconds: ms ?? max(160, (240 * ((to - from).abs() / 400).clamp(0.5, 1.4)).toInt()));
    final tween = Tween<double>(begin: from, end: to).chain(CurveTween(curve: curve));
    _anim = tween.animate(_animCtrl);
    _animCtrl.forward(from: 0).whenCompleteOrCancel(() {
      _offsetY = to;
      _anim = null;
      _animating = false;
      if (onEnd != null) onEnd();
    });
  }

  double get _driveOffsetY => (_anim == null) ? _offsetY : _anim!.value;

  void _onDragEnd(BuildContext context, DragEndDetails details) {
    if (_animating) return;

    final homeVm = ref.read(homeViewModelProvider);

    // If we're in tutorial mode, handle the tutorial swipe
    if (homeVm.showTutorial) {
      final screenH = MediaQuery.of(context).size.height;
      final double kMinDy = (screenH * 0.18).clamp(80.0, 160.0);
      final vy = details.velocity.pixelsPerSecond.dy;
      final bool flingUp = vy <= -kMinVel;
      final bool farUp = _offsetY <= -kMinDy;

      if (flingUp || farUp) {
        if (homeVm.tutorialPhase < 3) {
          // Swipe up: move to the next phase
          _animateOffset(
            from: _offsetY,
            to: -screenH,
            ms: 170,
            onEnd: () {
              _nextTutorialPhase();
              _offsetY = screenH;
              setState(() {});
              _animateOffset(from: _offsetY, to: 0, ms: 220);
            },
          );
        } else {
          // Last phase (phase 3): finish the tutorial on the last swipe
          _animateOffset(
            from: _offsetY,
            to: -screenH,
            ms: 170,
            onEnd: () {
              _completeTutorial();
              // Reset the offset to show the quote correctly
              _offsetY = 0;
              setState(() {});
            },
          );
        }
      } else {
        // Return to the initial position
        _animateOffset(from: _offsetY, to: 0);
      }
      return;
    }

    final screenH = MediaQuery.of(context).size.height;
    // Dynamic distance threshold (about 16–18% of height, bounded 80–160px)
    final double kMinDy = (screenH * 0.18).clamp(80.0, 160.0);

    final vy = details.velocity.pixelsPerSecond.dy;
    final bool flingUp   = vy <= -kMinVel;
    final bool flingDown = vy >=  kMinVel;
    final bool farUp     = _offsetY <= -kMinDy;
    final bool farDown   = _offsetY >=  kMinDy;

    int dir = 0; // -1 = up(next), +1 = down(prev)
    if (flingUp || farUp) dir = -1;
    if (flingDown || farDown) dir =  1;

    // Not far/fast enough -> revert
    if (dir == 0) {
      _animateOffset(from: _offsetY, to: 0);
      return;
    }

    // History edge (start): cannot go "any further down"
    if (dir == 1 && ref.read(homeQuoteViewModelProvider).historyIndex == 0) {
      _animateOffset(from: _offsetY, to: 0);
      return;
    }

    final double outTarget = (dir == -1) ? -screenH : screenH;

    // Sortie
    _animateOffset(
      from: _offsetY,
      to: outTarget,
      ms: 170,
      onEnd: () async {
        if (dir == -1) {
          await ref.read(homeQuoteViewModelProvider.notifier).goNext();
        } else {
          ref.read(homeQuoteViewModelProvider.notifier).goPrev();
        }

        // New quote: starts from the other side
        _offsetY = -outTarget;
        if (mounted) {
          setState(() {}); // met à jour le texte
        }

        // Entry toward center
        _animateOffset(from: _offsetY, to: 0, ms: 220);
      },
    );
  }

  String _getTopicsButtonText(String lang) {
    final topics = ref.read(homeQuoteViewModelProvider).selectedTopics;
    return ref.read(homeTopicsCoordinatorProvider).topicsButtonText(
          lang: lang,
          selectedTopics: topics,
        );
  }
  
  String _replaceNamePlaceholder(String text, String userName) {
    return text.replaceAll("%NAME%", userName);
  }

  /// Check whether the review popup should be shown and show it if needed
  Future<void> _onReviewPopupDismissed() async {
    await ref.read(homeNotificationsCoordinatorProvider).onReviewPopupDismissedByUser();
  }

  Future<void> _onReviewPopupAccepted() async {
    await ref.read(homeNotificationsCoordinatorProvider).onReviewPopupAcceptedByUser();
  }


  /// Called when the user becomes premium: lift blocks and generate a quote if needed.
  Future<void> _onBecamePremium() async {
    if (!mounted) return;
    await ref.read(homeQuoteViewModelProvider.notifier).onBecamePremium();
    if (mounted) {
      setState(() => _signatureTopPosition = null);
    }
  }

  Future<void> _processSettingsReturnFlow() async {
    await ref.read(homeQuoteViewModelProvider.notifier).processSettingsReturnFlow();
    if (mounted) {
      setState(() => _signatureTopPosition = null);
    }
  }
  
  Widget _buildTutorialArrowsAnimation(Map<String, dynamic> theme) {
    return AnimatedBuilder(
      animation: _tutorialArrowsAnimCtrl,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final cycleValue = _tutorialArrowsAnimCtrl.value % 1.0;
            
            if (cycleValue >= 0.2) {
              return Opacity(
                opacity: 0.0,
                child: SizedBox(
                  width: 50 * xFact,
                  child: Image.asset(
                    "assets/images/up_arrow.png",
                    color: Color(theme["fontcolor"]),
                  ),
                ),
              );
            }
            
            final timeMs = cycleValue * 2500.0;
            final reversedIndex = 2 - index;
            
            double startMs, fadeInEndMs, fadeOutStartMs, endMs;
            switch (reversedIndex) {
              case 0:
                startMs = 0.0;
                fadeInEndMs = 125.0;
                fadeOutStartMs = 125.0;
                endMs = 250.0;
                break;
              case 1:
                startMs = 125.0;
                fadeInEndMs = 250.0;
                fadeOutStartMs = 250.0;
                endMs = 375.0;
                break;
              case 2:
                startMs = 250.0;
                fadeInEndMs = 375.0;
                fadeOutStartMs = 375.0;
                endMs = 500.0;
                break;
              default:
                startMs = 0.0;
                fadeInEndMs = 0.0;
                fadeOutStartMs = 0.0;
                endMs = 0.0;
            }
            
            double opacity = 0.0;
            if (timeMs >= startMs && timeMs < fadeInEndMs) {
              opacity = (timeMs - startMs) / (fadeInEndMs - startMs);
            } else if (timeMs >= fadeInEndMs && timeMs < fadeOutStartMs) {
              opacity = 1.0;
            } else if (timeMs >= fadeOutStartMs && timeMs < endMs) {
              opacity = 1.0 - (timeMs - fadeOutStartMs) / (endMs - fadeOutStartMs);
            }
            
            opacity = opacity.clamp(0.0, 1.0);
            
            return Opacity(
              opacity: opacity,
              child: SizedBox(
                width: 50 * xFact,
                child: Image.asset(
                  "assets/images/up_arrow.png",
                  color: Color(theme["fontcolor"]),
                ),
              ),
            );
          }),
        );
      },
    );
  }
  
  Widget _buildTutorialPhase1(String lang, String userName, Map<String, dynamic> theme) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _driveOffsetY),
        child: child,
      ),
      child: Stack(
        children: [
          // Centered content
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 25 * xFact),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Texte "Welcome to Business Mindset"
                  Text(
                    translate("tutorial_welcome_title", lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "InterTight",
                      fontSize: 22 * xFact,
                      fontWeight: FontWeight.w600,
                      color: Color(theme["fontcolor"]),
                    ),
                  ),
                  SizedBox(height: 10 * yFact),
                  // Texte "%NAME%!"
                  Text(
                    "$userName!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "InterTight",
                      fontSize: 22 * xFact,
                      fontWeight: FontWeight.w600,
                      color: Color(theme["fontcolor"]),
                    ),
                  ),
                  SizedBox(height: 10 * yFact),
                  // Texte "Your new mindset environment is ready."
                  Text(
                    translate("tutorial_welcome_subtitle", lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "InterTight",
                      fontSize: 22 * xFact,
                      fontWeight: FontWeight.w600,
                      color: Color(theme["fontcolor"]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Animation swipe en bas
          Positioned(
            bottom: 100 * yFact,
            left: 0,
            right: 0,
            child: _buildTutorialArrowsAnimation(theme),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTutorialPhase2(String lang, String userName, Map<String, dynamic> theme) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _driveOffsetY),
        child: child,
      ),
      child: Stack(
        children: [
          // Content with steps
          Padding(
            padding: EdgeInsets.only(left: 30 * xFact, right: 30 * xFact),
            child: Center(
              child: Text(
                translate("tutorial_step1_description", lang),
                style: TextStyle(
                  fontFamily: "InterTight",
                  fontSize: 22 * xFact,
                  fontWeight: FontWeight.w600,
                  color: Color(theme["fontcolor"]),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Animation swipe en bas
          Positioned(
            bottom: 100 * yFact,
            left: 0,
            right: 0,
            child: _buildTutorialArrowsAnimation(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialPhase3(String lang, String userName, Map<String, dynamic> theme) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _driveOffsetY),
        child: child,
      ),
      child: Stack(
        children: [
          // Content with steps
          Padding(
            padding: EdgeInsets.only(left: 30 * xFact, right: 30 * xFact),
            child: Center(
              child: Text(
                translate("tutorial_step2_description", lang),
                style: TextStyle(
                  fontFamily: "InterTight",
                  fontSize: 22 * xFact,
                  fontWeight: FontWeight.w600,
                  color: Color(theme["fontcolor"]),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Animation swipe en bas
          Positioned(
            bottom: 100 * yFact,
            left: 0,
            right: 0,
            child: _buildTutorialArrowsAnimation(theme),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTutorialPhase4(String lang, String userName, Map<String, dynamic> theme) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _driveOffsetY),
        child: child,
      ),
      child: Stack(
        children: [
          // Centered content
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40 * xFact),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Texte "You're ready, %NAME%!"
                  Text(
                    translate("tutorial_ready_title", lang).replaceAll("%NAME%", userName),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "InterTight",
                      fontSize: 28 * xFact,
                      fontWeight: FontWeight.w700,
                      color: Color(theme["fontcolor"]),
                    ),
                  ),
                  SizedBox(height: 20 * yFact),
                  // Texte "Come back every day to boost your motivation."
                  Text(
                    translate("tutorial_ready_subtitle", lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "InterTight",
                      fontSize: 18 * xFact,
                      color: Color(theme["fontcolor"]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Animation swipe en bas
          Positioned(
            bottom: 100 * yFact,
            left: 0,
            right: 0,
            child: _buildTutorialArrowsAnimation(theme),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final currentTheme = ref.watch(currentThemeProvider);
    final isCustomTheme = ref.watch(isCustomThemeProvider);
    final homeView = ref.watch(homeViewModelProvider);

    ref.listen<int>(widgetHomeDeepLinkTickProvider, (previous, next) {
      if (previous == next) return;
      if (kDebugMode) {
        debugPrint(
          '[WidgetTap] HomePage tick $previous→$next → _checkIfOpenedFromWidget',
        );
      }
      unawaited(_handleWidgetDeepLinkTick());
    });

    if (!homeView.isReady) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, __) {},
        child: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final quote = ref.watch(homeQuoteViewModelProvider);
    final signature = quote.currentQuoteData?["signature"] as String?;
    final bookTitle = quote.currentQuoteData?["bookTitle"] as String?;
    final String? url = quote.currentQuoteData?["url"] as String?;
    
    final userName = ref.watch(userNameStateProvider);

    // If we're in tutorial mode, show the tutorial
    if (homeView.showTutorial) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {},
      child: Scaffold(
        body: Stack(
        children: [
              // Background filling the whole screen (behind the status bar)
              Positioned.fill(
                child: HomeBackground(theme: currentTheme, isCustom: isCustomTheme),
              ),
              // Content with SafeArea to respect the status bar
              SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    // Zone de gestes
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) {
                if (_animating || _anim != null) {
                  _animCtrl.stop();
                  _anim = null;
                  _animating = false;
                }
              },
              onVerticalDragUpdate: (details) {
                if (_animating) return;
                setState(() {
                  _offsetY += details.primaryDelta!;
                });
              },
              onVerticalDragEnd: (details) {
                if (_animating) return;
                _onDragEnd(context, details);
                },
              child: Container(), // Widget vide pour capturer les gestes
            ),
          ), // Icône mindset fixe en haut à gauche (visible mais inactive pendant le tutoriel)
                    if(homeView.tutorialPhase == 3) Positioned(
                      top: 10 * yFact,
                      left: 20 * xFact,
                      width: 70 * xFact,
                      height: 70 * yFact,
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.of(context).push(fadeThroughRoute(const MindSetPoints()));
                        },
                        child: SizedBox(
                          width: 70 * xFact,
                          height: 70 * yFact,
                          child: Image.asset(
                            "assets/images/flamy/flamy_glasses.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    if (!ref.watch(premiumProvider) && homeView.tutorialPhase == 3)
                      Positioned(
                        top: 20 * yFact,
                        right: 30 * xFact,
                        width: 45 * xFact,
                        height: 45 * yFact,
                        child: GestureDetector(
                          onTap: () {
                            final lang = ref.read(languageProvider);
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) => Paywallb(
                                  pageStyle: "notdeclare",
                                  backIcon: true,
                                  skipLink: false,
                                  backward: () {},
                                  forward1: () {
                                    ref.read(premiumProvider.notifier).state = true;
                                    unawaited(_onBecamePremium());
                                  },
                                  forward2: () {},
                                  title: translate("onboardingtitle3", lang),
                                  subTitle: translate("onboardingsubtitle3", lang),
                                  choiceList: [],
                                  buttonText: "letsgo",
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(10 * xFact),
                            decoration: BoxDecoration(
                              color: appTheme.textField,
                              shape: BoxShape.circle,
                              //borderRadius: BorderRadius.circular(10 * xFact),
                            ),
                            child: Image.asset("assets/images/premium.png"),
                          ),
                        ),
                      ),
                    // Bandeau en bas
                    if(homeView.tutorialPhase >= 2)Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        padding: EdgeInsets.only(left: 25 * xFact, right: 25*xFact, bottom: 25 * yFact,top: 15*yFact),
                        decoration: BoxDecoration(
                            color: Color(0xFF2b2b2b).withValues(alpha: 0.7),
                            borderRadius: BorderRadius.all(Radius.circular(8*xFact))
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Palette icon (themes) on the left
                            GestureDetector(
                              onTap: () async {
                                if(homeView.tutorialPhase == 2){
                                  final screenH = MediaQuery.of(context).size.height;
                                  // Swipe up: move to the next phase
                                  _animateOffset(
                                    from: _offsetY,
                                    to: -screenH,
                                    ms: 170,
                                    onEnd: () {
                                      _nextTutorialPhase();
                                      _offsetY = screenH;
                                      setState(() {});
                                      _animateOffset(from: _offsetY, to: 0, ms: 220);
                                    },
                                  );
                                }else{
                                  Navigator.of(context).push(fadeThroughRoute(const ThemesPage()));
                                }
                              },
                              child: SizedBox(
                                width: 30 * xFact,
                                height: 30 * yFact,
                                child: Image.asset("assets/images/themes.png"),
                              ),
                            ),
                            // TertiaryButton "Select topics" centered
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15 * xFact),
                                child: TertiaryButton(
                                  textSize: 16,
                                  backgroundColor: Color(0xFF2b2b2b).withValues(alpha: 0.5),
                                  height: 40*xFact,
                                  text: _getTopicsButtonText(lang),
                                  onTap: () async {
                                    if(homeView.tutorialPhase == 2){
                                      final screenH = MediaQuery.of(context).size.height;
                                      // Swipe up: move to the next phase
                                      _animateOffset(
                                        from: _offsetY,
                                        to: -screenH,
                                        ms: 170,
                                        onEnd: () {
                                          _nextTutorialPhase();
                                          _offsetY = screenH;
                                          setState(() {});
                                          _animateOffset(from: _offsetY, to: 0, ms: 220);
                                        },
                                      );
                                    }else{
                                      final modified = await Navigator.of(context).push<bool>(
                                        fadeThroughRoute(const FavoritesPage()),
                                      );
                                      if (modified == true) {
                                        // Reload selected topics
                                        final prefs = await SharedPreferences.getInstance();
                                        final savedTopics = prefs.getStringList("selectedTopics") ?? [];
                                        final qn = ref.read(homeQuoteViewModelProvider.notifier);
                                        qn.setSelectedTopics(savedTopics);
                                        await qn.loadStoredQuotes(updatePersistedHistory: false);
                                        qn.refreshLikedFromFavorites();
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                            // Settings icon on the right
                            GestureDetector(
                              onTap: () async {
                                if(homeView.tutorialPhase == 2){
                                  final screenH = MediaQuery.of(context).size.height;
                                  // Swipe up: move to the next phase
                                  _animateOffset(
                                    from: _offsetY,
                                    to: -screenH,
                                    ms: 170,
                                    onEnd: () {
                                      _nextTutorialPhase();
                                      _offsetY = screenH;
                                      setState(() {});
                                      _animateOffset(from: _offsetY, to: 0, ms: 220);
                                    },
                                  );
                                }else{
                                  await Navigator.of(context).push(sharedAxisFromBottom(SettingsPage()));
                                  // Check whether a quote was selected from ChooseQuotePage
                                  if (mounted && ref.read(homeViewModelProvider).isReady) {
                                    ref
                                        .read(homeQuoteViewModelProvider.notifier)
                                        .consumeSelectedQuoteFromChoosePage(
                                          isMounted: () => mounted,
                                          onQuoteApplied: _onQuoteLayoutRefreshNeeded,
                                        );
                                  }
                                  await _processSettingsReturnFlow();
                                }
                              },
                              child: SizedBox(
                                width: 30 * xFact,
                                height: 30 * yFact,
                                child: Image.asset("assets/images/settings.png"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Tutorial content based on phase
                    homeView.tutorialPhase == 0
                        ? _buildTutorialPhase1(lang, userName, currentTheme)
                        : homeView.tutorialPhase == 1
                            ? _buildTutorialPhase2(lang, userName, currentTheme)
                            : homeView.tutorialPhase ==  2
                              ? _buildTutorialPhase3(lang, userName, currentTheme)
                              : _buildTutorialPhase4(lang, userName, currentTheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {},
      child: Scaffold(
        body: Stack(
        children: [
          // Background filling the whole screen (behind the status bar)
          Positioned.fill(
              child: HomeBackground(theme: currentTheme, isCustom: isCustomTheme),
          ),
          
          // Content with SafeArea to respect the status bar
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Zone de gestes
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: (_) {
                      // Stop any in-progress animation to avoid "recentering" during drag
                      if (_animating || _anim != null) {
                        _animCtrl.stop();
                        _anim = null;
                        _animating = false;
                      }
                    },

                    onVerticalDragUpdate: (details) {
                      if (_animating) return;
                      setState(() {
                        // *** ACCUMULATES the displacement ***
                        _offsetY += details.primaryDelta!;
                      });
                    },

                    onVerticalDragEnd: (details) {
                      if (_animating) return;
                      _onDragEnd(context, details);
                    },

                    child: Container(), // Widget vide pour capturer les gestes
                  ),
                ),
                // 2) TEXT — also gesturable (to capture even if other widgets intercept)
                Padding(
                  padding: EdgeInsets.only(top: 50*yFact,bottom: 160*yFact),
                  child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragStart: (_) {
                      // Stop any in-progress animation to avoid "recentering" during drag
                      if (_animating || _anim != null) {
                        _animCtrl.stop();
                        _anim = null;
                        _animating = false;
                      }
                      // Optional: memorize, but we no longer need it if we accumulate
                      // _startY = _offsetY;
                    },

                    onVerticalDragUpdate: (details) {
                      if (_animating) return;
                      setState(() {
                        // *** ACCUMULATES the displacement ***
                        _offsetY += details.primaryDelta!;
                        // (and NOT: _offsetY = _startY + details.primaryDelta!)
                      });
                    },

                    onVerticalDragEnd: (details) {
                      if (_animating) return;
                      _onDragEnd(context, details); // ou _finishDrag(screenH: ..., velocityY: ...)
                    },

                    child: AnimatedBuilder(
                      animation: _animCtrl,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _driveOffsetY),
                        child: child,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15 * xFact),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              key: _stackKey,
                              children: [
                                // Quote vertically centered
                                Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8 * xFact),
                                    child: homeView.openedWithDailyLimit && !homeView.showDailyLimit
                                        ? Text(
                                            translate("daily_limit_swipe_to_continue", lang),
                                            key: _quoteKey,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: currentTheme["fontfamily"],
                                              fontSize: currentTheme["fontsize"] * xFact * 0.85,
                                              color: Color(currentTheme["fontcolor"]).withValues(alpha: 0.9),
                                              height: 1.3,
                                            ),
                                          )
                                        : quote.selectedTopics.length == 1 &&
                                                quote.selectedTopics.first == "favoritesquotes" &&
                                                quote.favoritesGlobal.isEmpty
                                            ? Text(
                                                translate("no_favorites", lang),
                                                key: _quoteKey,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: currentTheme["fontfamily"],
                                                  fontSize: currentTheme["fontsize"] * xFact,
                                                  color: Color(currentTheme["fontcolor"]),
                                                  height: 1.22,
                                                ),
                                              )
                                            : Text(
                                                _replaceNamePlaceholder(quote.currentQuote, userName),
                                                key: _quoteKey,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: currentTheme["fontfamily"],
                                                  fontSize: currentTheme["fontsize"] * xFact,
                                                  color: Color(currentTheme["fontcolor"]),
                                                  height: 1.22,
                                                ),
                                              ),
                                  ),
                                ),
                                // Signature and book positioned below the quote
                                if (!(quote.selectedTopics.length == 1 &&
                                        quote.selectedTopics.first == "favoritesquotes" &&
                                        quote.favoritesGlobal.isEmpty) &&
                                    (signature != null && signature.isNotEmpty ||
                                     bookTitle != null && bookTitle.isNotEmpty))
                                  Builder(
                                    builder: (context) {
                                      // Compute the position after layout
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (mounted) {
                                          final RenderBox? quoteBox = _quoteKey.currentContext?.findRenderObject() as RenderBox?;
                                          final RenderBox? stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;

                                          if (quoteBox != null && stackBox != null && quoteBox.hasSize && stackBox.hasSize) {
                                            // Get the quote's position within the Stack
                                            final quotePosition = quoteBox.localToGlobal(Offset.zero);
                                            final stackPosition = stackBox.localToGlobal(Offset.zero);
                                            final relativeY = quotePosition.dy - stackPosition.dy;
                                            final quoteSize = quoteBox.size;
                                            // Bottom position of the quote + spacing
                                            final newTopPosition = relativeY + quoteSize.height + 20 * yFact;

                                            if (_signatureTopPosition != newTopPosition) {
                                              setState(() {
                                                _signatureTopPosition = newTopPosition;
                                              });
                                            }
                                          }
                                        }
                                      });

                                      // Use the computed position or a fallback
                                      final topPosition = _signatureTopPosition ?? (constraints.maxHeight / 2 + 100);

                                      return Positioned(
                                        top: topPosition,
                                        left: 0,
                                        right: 0,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            if (signature != null && signature.isNotEmpty)
                                              Padding(
                                                padding: EdgeInsets.only(right: 15 * xFact),
                                                child: Text(
                                                  signature,
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                    fontFamily: currentTheme["fontfamily"],
                                                    fontSize: currentTheme["fontsize"] * xFact * 0.6,
                                                    color: Color(currentTheme["fontcolor"]),
                                                  ),
                                                ),
                                              ),
                                            if (bookTitle != null && bookTitle.isNotEmpty) ...[
                                              SizedBox(height: 10 * yFact),
                                              Padding(
                                                padding: EdgeInsets.only(right: 15 * xFact),
                                                child: Wrap(
                                                  alignment: WrapAlignment.end,
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: (url != null && url.isNotEmpty)
                                                          ? () async {
                                                              final uri = Uri.parse(url);
                                                              if (await canLaunchUrl(uri)) {
                                                                final host = uri.host.toLowerCase();
                                                                final isAmazonLink =
                                                                    host.contains('amazon.');
                                                                if (isAmazonLink) {
                                                                  MixpanelService.instance.track(
                                                                    '[Quote] Amazon Link Clicked',
                                                                    {
                                                                      'book_title': bookTitle,
                                                                      'signature': signature,
                                                                      'quote': quote.currentQuote,
                                                                      'url': url,
                                                                      'language': lang,
                                                                    },
                                                                  );
                                                                }
                                                                await launchUrl(
                                                                  uri,
                                                                  mode: LaunchMode.externalApplication,
                                                                );
                                                              }
                                                            }
                                                          : null,
                                                      child: (url != null && url.isNotEmpty)
                                                          ? FittedBox(
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.end,
                                                              children: [
                                                                Stack(
                                                                  clipBehavior: Clip.none,
                                                                  children: [
                                                                    // Ligne
                                                                    Positioned(
                                                                  bottom: 7, // ajuste ici la hauteur de la ligne
                                                                  left: 0,
                                                                  right: 0,
                                                                  child: Container(
                                                                    height: 1,
                                                                    color: Color(currentTheme["fontcolor"]),
                                                                  ),
                                                                ),
                                                                // Texte
                                                                Padding(
                                                                  padding: const EdgeInsets.only(bottom: 6), // overlap contrôlé
                                                                  child: Text(
                                                                    bookTitle,
                                                                    textAlign: TextAlign.right,
                                                                    style: TextStyle(
                                                                      fontFamily: currentTheme["fontfamily"],
                                                                      fontSize: currentTheme["fontsize"] * xFact * 0.6,
                                                                      color: Color(currentTheme["fontcolor"]),
                                                                    ),
                                                                  ),
                                                                ),
                                                                // Arrow positioned as superscript
                                                                Positioned(
                                                                  top: 0,
                                                                  right: 0,
                                                                  child: Transform.translate(
                                                                    offset: Offset(13, 4), // Ajustement fin pour positionnement comme exposant
                                                                    child: Icon(
                                                                      Icons.north_east,
                                                                      color: Color(currentTheme["fontcolor"]),
                                                                      size: currentTheme["fontsize"] * xFact * 0.5,
                                                                    ),
                                                                  ),
                                                                ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          )

                                                          : Text(
                                                              bookTitle,
                                                              textAlign: TextAlign.right,
                                                              style: TextStyle(
                                                                fontFamily: currentTheme["fontfamily"],
                                                                fontSize: currentTheme["fontsize"] * xFact * 0.6,
                                                                color:  Color(currentTheme["fontcolor"]),
                                                              ),
                                                            ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                                  ),
                ),
            
            
                // 3) Buttons above (unchanged)
                Positioned(
                  top: 10 * yFact,
                  left: 20 * xFact,
                  width: 70 * xFact,
                  height: 70 * yFact,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          Navigator.of(context).push(fadeThroughRoute(const MindSetPoints()));
                        },
                        child: SizedBox(
                          width: 70 * xFact,
                          height: 70 * yFact,
                          child: Image.asset(
                            "assets/images/flamy/flamy_glasses.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      // Animations "+1"
                      ..._activeAnimations.map((anim) => PointIncrementWidget(
                        animation: anim,
                        xFact: xFact,
                        yFact: yFact,
                      )),
                    ],
                  ),
                ),
                if (!ref.watch(premiumProvider))
                  Positioned(
                    top: 20 * yFact,
                    right: 30 * xFact,
                    width: 45 * xFact,
                    height: 45 * yFact,
                    child: GestureDetector(
                      onTap: () {
                        final lang = ref.read(languageProvider);
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => Paywallb(
                              pageStyle: "notdeclare",
                              backIcon: true,
                              skipLink: false,
                              backward: () {},
                              forward1: () {
                                ref.read(premiumProvider.notifier).state = true;
                                unawaited(_onBecamePremium());
                              },
                              forward2: () {},
                              title: translate("onboardingtitle3", lang),
                              subTitle: translate("onboardingsubtitle3", lang),
                              choiceList: [],
                              buttonText: "letsgo",
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(10 * xFact),
                        decoration: BoxDecoration(
                          color: appTheme.textField,
                          shape: BoxShape.circle,
                          //borderRadius: BorderRadius.circular(10 * xFact),
                        ),
                        child: Image.asset("assets/images/premium.png"),
                      ),
                  ),
                ),
                // Bandeau en bas
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                    child: Container(
                    clipBehavior: Clip.antiAlias,
                    padding: EdgeInsets.only(left: 25 * xFact, right: 25*xFact, bottom: 25 * yFact,top: 15*yFact),
                      decoration: BoxDecoration(
                      color: Color(0xFF2b2b2b).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.all(Radius.circular(8*xFact))
                      ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Palette icon (themes) on the left
                        GestureDetector(
                    onTap: () async {
                      Navigator.of(context).push(fadeThroughRoute(const ThemesPage()));
                    },
                          child: SizedBox(
                            width: 30 * xFact,
                            height: 30 * yFact,
                      child: Image.asset("assets/images/themes.png"),
                    ),
                  ),
                        // TertiaryButton "Select topics" centered
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15 * xFact),
                            child: TertiaryButton(
                              textSize: 16,
                              backgroundColor: Color(0xFF2b2b2b).withValues(alpha: 0.5),
                              height: 40*xFact,
                              text: _getTopicsButtonText(lang),
                              onTap: () async {
                                final modified = await Navigator.of(context).push<bool>(
                                  fadeThroughRoute(const FavoritesPage()),
                                );
                                if (modified == true) {
                                  // Reload selected topics
                                  final prefs = await SharedPreferences.getInstance();
                                  final savedTopics = prefs.getStringList("selectedTopics") ?? [];
                                  final qn = ref.read(homeQuoteViewModelProvider.notifier);
                                  qn.setSelectedTopics(savedTopics);
                                  await qn.loadStoredQuotes(updatePersistedHistory: false);
                                  qn.refreshLikedFromFavorites();
                                 }
                              },
                            ),
                          ),
                        ),
                        // Settings icon on the right
                        GestureDetector(
                          onTap: () async {
                            await Navigator.of(context).push(sharedAxisFromBottom(SettingsPage()));
                            // Check whether a quote was selected from ChooseQuotePage
                            if (mounted && ref.read(homeViewModelProvider).isReady) {
                              ref
                                  .read(homeQuoteViewModelProvider.notifier)
                                  .consumeSelectedQuoteFromChoosePage(
                                    isMounted: () => mounted,
                                    onQuoteApplied: _onQuoteLayoutRefreshNeeded,
                                  );
                            }
                            await _processSettingsReturnFlow();
                          },
                          child: SizedBox(
                            width: 30 * xFact,
                            height: 30 * yFact,
                            child: Image.asset("assets/images/settings.png"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 150 * yFact),
                    child: Builder(
                      builder: (context) {
                        // Check whether we're in the "No favorites" case
                        final isNoFavorites = quote.selectedTopics.length == 1 &&
                            quote.selectedTopics.first == "favoritesquotes" &&
                            quote.favoritesGlobal.isEmpty;
                        
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: isNoFavorites ? null : () async {
                                if (quote.currentQuote.isEmpty) return;
                                final signature = quote.currentQuoteData?["signature"] as String?;
                                final bookTitle = quote.currentQuoteData?["bookTitle"] as String?;
                                final shared = await shareQuote(
                                  quote.currentQuote,
                                  context: context,
                                  ref: ref,
                                  signature: signature,
                                  bookTitle: bookTitle,
                                );
                                // Increment on each share open (callback not available)
                                await MindsetPointsService.instance.incrementShare();
                                // Track the action for the review popup
                                await ReviewPopupService.instance.trackAction();
                                await ref
                                    .read(homeNotificationsCoordinatorProvider)
                                    .maybePresentReviewPopupAfterUserAction();
                                // Track Mixpanel event
                                if (shared) {
                                  MixpanelService.instance.track('[Quote] Share', {'status': 'success'});
                                  } else {
                                  MixpanelService.instance.track('[Quote] Share', {'status': 'cancelled'});
                                  }
                              },
                              child: SizedBox(
                                width: 40 * xFact,
                                height: 40 * yFact,
                                child: Image.asset(
                                    "assets/images/share2.png",
                                  color: Color(currentTheme["fontcolor"]),
                                ),
                              ),
                            ),
                            SizedBox(width: 50 * xFact),
                            GestureDetector(
                              onTap: isNoFavorites ? null : () async {
                                if (quote.currentQuote.isEmpty) return;
                                final qn = ref.read(homeQuoteViewModelProvider.notifier);
                                final nextLiked = !quote.liked;
                                qn.setLiked(nextLiked);
                                // Track the action for the review popup (like)
                                await ReviewPopupService.instance.trackAction();
                                if (nextLiked) {
                                  await ref
                                      .read(homeNotificationsCoordinatorProvider)
                                      .maybePresentReviewPopupAfterUserAction();
                                  await qn.onQuoteLikedFromUser();
                                } else {
                                  await qn.onQuoteUnlikedFromUser();
                                }
                              },
                              child: SizedBox(
                                width: 40 * xFact,
                                height: 40 * yFact,
                                child: quote.liked ? Image.asset("assets/images/favoriteplain.png",color: Color(currentTheme["fontcolor"]),)
                                    : Image.asset("assets/images/favorite.png",color: Color(currentTheme["fontcolor"]),),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Review popup
          if (homeView.showReviewPopup)
            ReviewPopupWidget(
              userName: userName,
              onDismiss: _onReviewPopupDismissed,
              onAccepted: _onReviewPopupAccepted,
            ),
          // Overlay limite quotidienne (utilisateurs non-premium)
          if (homeView.showDailyLimit && !ref.watch(premiumProvider))
            Positioned.fill(
              child: _buildDailyLimitOverlay(lang),
            ),
        ],
    ),
  ),
);
  }

  Widget _buildDailyLimitOverlay(String lang) {
    return GestureDetector(
      onVerticalDragStart: (_) {},
      onVerticalDragUpdate: (_) {},
      onVerticalDragEnd: (_) {},
      child: Container(
        color: Colors.black.withValues(alpha: 0.88),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32 * xFact),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80 * xFact,
                  height: 80 * xFact,
                  padding: EdgeInsets.all(18 * xFact),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    "assets/images/premium.png",
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 28 * yFact),
                Text(
                  translate("daily_limit_title", lang),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22 * xFact,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 14 * yFact),
                Text(
                  translate("daily_limit_body", lang),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15 * xFact,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 36 * yFact),
                PrimaryButton(
                  text: translate("daily_limit_cta", lang),
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => Paywallb(
                          pageStyle: "notdeclare",
                          backIcon: true,
                          skipLink: false,
                          backward: () {},
                          forward1: () {
                            ref.read(premiumProvider.notifier).state = true;
                            unawaited(_onBecamePremium());
                          },
                          forward2: () {},
                          title: translate("onboardingtitle3", lang),
                          subTitle: translate("onboardingsubtitle3", lang),
                          choiceList: [],
                          buttonText: "letsgo",
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 14 * yFact),
                GestureDetector(
                  onTap: () {
                    if (mounted) {
                      ref.read(homeViewModelProvider.notifier).setShowDailyLimit(false);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10 * yFact),
                    child: Text(
                      translate("maybe_later", lang),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14 * xFact,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10 * yFact),
                Text(
                  translate("daily_limit_reset", lang),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 13 * xFact,
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

