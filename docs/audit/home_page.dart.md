# Audit — `lib/views/home_page.dart`

> Snapshot date: April 2026 · current length ≈ 4 716 lines.

## 1. Snapshot

`Home_Page` is the central screen. A single `ConsumerStatefulWidget` mixes a
`TickerProviderStateMixin` (animations) and a `WidgetsBindingObserver`
(lifecycle), and ships **~50 private methods** plus the `build` method.

Approximate breakdown of `_Home_PageState`:

| Theme | Method group |
|---|---|
| Subscription / premium | `_listenToSubscriptionEvents`, `_startPeriodicSubscriptionCheck`, `_checkSubscriptionStatePeriodically`, `_updatePremiumStateToFalse`, `_handleSubscriptionExpired`, `_checkSubscriptionStateOnResume`, `_onBecamePremium` |
| Topics / content | `_loadDebugTopic`, `_validateAndFixSelectedTopics`, `_validateAndFixWidgetTopics`, `_loadAppOrderedQuotes`, `_appendUniqueQuote`, `_findQuoteDataByText`, `_getAvailableQuotesForTopic`, `_getAvailableQuotesAsync`, `_getAllQuotesForLang` |
| Widget bridge (iOS) | `_refreshWidgetiOS`, `_loadWidgetQuote`, `_checkPendingWidgetShare`, `_checkWidgetQuoteOnResume`, `_forceWidgetNewQuoteOnResume`, `_listenToWidgetDeepLink`, `_checkIfOpenedFromWidget` |
| Notifications | `_listenToNotificationPayloads`, `_applyNotificationPayload`, `_consumePendingNotificationPayloadIfAny`, `_scheduleNotificationsIfNeeded` |
| Tutorial / onboarding overlay | `_completeTutorial`, `_nextTutorialPhase`, `_buildTutorialPhase1..4`, `_buildTutorialStep`, `_buildTutorialArrowsAnimation` |
| Daily limit (free tier) | `_checkDailyQuoteLimit`, `_incrementDailyQuoteCount`, `_buildDailyLimitOverlay` |
| Review / promo | `_checkAndShowReviewPopup`, `_onReviewPopupDismissed`, `_onReviewPopupAccepted`, `_checkAndShowPromoPaywall` |
| Navigation gestures | `_onDragEnd`, `_goNext`, `_goPrev`, `_animateOffset`, `_listenToPointsIncrements`, `_initTikTokAfterDelay` |
| Bootstrap | `_loadPrefs`, `_trackNewQuoteViewed`, `_trimToLastN` |
| Build helpers | `_buildBackgroundWidget`, `build` (very large) |

Plus three small private classes glued at the bottom:
`_PointIncrementAnimation`, `_PointIncrementWidget`, `_UnderlinePainter`,
and one public widget (`TrueUnderlineText`) that should also be its own file.

## 2. Pain points

1. **God-object widget**: a single `State<Home_Page>` owns the entire app's
   business logic that reacts to user gestures. Every change carries the risk
   of breaking an unrelated concern.
2. **Naming**: `Home_Page` and `_Home_PageState` violate
   `camel_case_types`. Should be `HomePage` / `_HomePageState`.
3. **Async-gap unsafety**: many `await` calls are followed by
   `Navigator.of(context)...` or `setState(...)` without a robust mounted
   check, leading to occasional `setState after dispose` crashes when the
   user backgrounds the app mid-await.
4. **Direct `SharedPreferences` reads** scattered everywhere — should go
   through a provider that exposes typed reads.
5. **iOS widget bridge** is half here, half in `services/`. The
   `MethodChannel('businessmindset/widget')` plumbing belongs to a single
   `WidgetBridge` service.
6. **Tutorial UI** (5 widget builders + state machine) is large enough to
   live in its own file (`views/home/tutorial/`).
7. **Daily-limit overlay** mixes business rules ("how many free quotes
   today?") with UI. The rules should move to a `DailyLimitController`.
8. **Background painter / point increment widget**: pure presentation code
   that has nothing to do with the home screen. Should live under
   `views/home/widgets/`.

## 3. Refactor plan

### Tier 1 — Low risk · *next step* (`s7`)

- [ ] Rename the type to `HomePage` / `_HomePageState`
      (`camel_case_types`). Single global rename, mechanically safe.
- [ ] Replace remaining `print(...)` with `debugPrint(...)`.
- [ ] Extract `_PointIncrementAnimation`, `_PointIncrementWidget`,
      `_UnderlinePainter` and `TrueUnderlineText` into
      `lib/views/home/widgets/`.
- [ ] Move tutorial overlay (`_buildTutorialPhase*`, `_buildTutorialStep`,
      `_buildTutorialArrowsAnimation`, `_nextTutorialPhase`,
      `_completeTutorial`) into `lib/views/home/tutorial/`.
- [ ] Translate remaining French comments / log strings to English
      (covered by step `s8`).

### Tier 2 — Medium risk · separate branch

- [ ] Extract iOS widget bridge into `services/widget_bridge.dart`
      (`_refreshWidgetiOS`, `_loadWidgetQuote`, `_checkPendingWidgetShare`,
      `_checkWidgetQuoteOnResume`, `_forceWidgetNewQuoteOnResume`,
      `_listenToWidgetDeepLink`, `_checkIfOpenedFromWidget`).
- [ ] Extract notification glue into a small
      `NotificationPayloadHandler` class.
- [ ] Replace direct `SharedPreferences` reads with typed providers.
- [ ] Wrap every `BuildContext` post-await usage in a `if (!mounted) return;`
      guard (or use `context.mounted`).

### Tier 3 — High risk · dedicated PR

- [ ] Introduce a `HomeController` (Riverpod `AsyncNotifier`) that exposes:
      `currentQuote`, `nextQuote`, `dailyLimitState`, `subscriptionState`,
      `widgetState`. The widget then becomes a thin
      `ConsumerWidget` reading slices.
- [ ] Split the screen into feature folders:
      `views/home/`, `views/home/tutorial/`, `views/home/widgets/`,
      `views/home/daily_limit/`, `views/home/promo/`.
- [ ] Replace the mixed `TickerProviderStateMixin` + observer pattern with
      hooks (or `riverpod_annotation`) so animation / lifecycle become
      composable.
