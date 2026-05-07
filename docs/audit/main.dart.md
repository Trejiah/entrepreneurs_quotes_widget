# Audit — `lib/main.dart`

> Snapshot date: April 2026 · current length ≈ 1 175 lines.

## 1. Snapshot

`main.dart` is responsible for:

- bootstrapping Flutter (`WidgetsFlutterBinding`, orientation lock, screen
  scaling),
- loading runtime configuration (`Env.load()` for `flutter_dotenv`),
- initialising Firebase (`Firebase.initializeApp`) with a retry loop because
  native Pigeon channels are not always ready on the very first frame,
- wiring Firebase Crashlytics as the global error sink (both
  `FlutterError.onError` and `PlatformDispatcher.instance.onError`),
- loading initial user state from `SharedPreferences` (theme, language,
  premium flag, onboarding completion),
- deciding the start route (onboarding vs. home),
- listening to native deep links coming through `MethodChannel('businessmindset/deeplink')`,
- holding two top-level globals: `appTheme` (current `AppColors`) and
  `_deepLinkChannel`.

Top-level shape:

| Lines (approx) | Role |
|---|---|
| 1 – 447 | Legacy commented-out implementation kept as reference. |
| 448 – 516 | `main()` + `runZonedGuarded` glue. |
| 521 – ~ 850 | `AppBootstrapper` + `_AppBootstrapperState` (init pipeline). |
| ~ 850 – 1 175 | `MyApp` + lifecycle observer + deep-link plumbing. |

## 2. Pain points

1. **Dead, commented-out implementation** at the top of the file
   (lines 1 – 447). This is historical cruft from a previous refactor and
   should be deleted — the live implementation lives below it.
2. **`AppBootstrapper` does too much**. The initialisation logic mixes:
   - Firebase init (with retry),
   - SharedPreferences load,
   - Theme list build,
   - Onboarding decision,
   - Promo paywall scheduling,
   - TikTok / RevenueCat / Mixpanel kickoff,
   - Notification listener wiring,
   - Deep-link listener wiring.

   Each of these deserves its own helper (or service) so this widget becomes
   a thin coordinator.
3. **Hard global state**: `late AppColors appTheme` is mutated from many
   places. Belongs to a Riverpod provider already (`themeIndexProvider`) —
   the mutable global should die.
4. **Deep-link channel** is declared at the top of `main.dart`, but the
   actual handlers are spread across `MyApp` and `home_page.dart`.
   It should become a small `DeepLinkHandler` class living under
   `lib/app/`.
5. **`print` calls** instead of `debugPrint` in a few spots — they ship in
   release builds and pollute Crashlytics breadcrumbs.

## 3. Refactor plan

### Tier 1 — Low risk · *next step* (`s7`)

- [ ] Delete the 447 lines of commented-out legacy code at the top of the file.
- [ ] Replace remaining `print(...)` with `debugPrint(...)`.
- [ ] Extract `_initializeFirebaseWithRetry` and the Crashlytics wiring into
      `lib/bootstrap/firebase_bootstrap.dart`.
- [ ] Extract the deep-link channel + notifier into
      `lib/app/deep_link_handler.dart` and let `_MyAppState` own a single
      instance instead of inline `MethodChannel` calls.
- [ ] Translate the remaining French comments / log strings to English
      (covered by step `s8`).

### Tier 2 — Medium risk · separate branch

- [ ] Move "decide initial route" logic into a tiny pure function
      (`StartupRoute decideStartRoute({ required bool hasOnboard, ... })`).
- [ ] Replace the mutable global `appTheme` with reads from
      `themeIndexProvider` everywhere.
- [ ] Move TikTok / Mixpanel / RevenueCat init out of the bootstrap widget
      into a dedicated `AppServices.initialize()` orchestrator.

### Tier 3 — High risk · dedicated PR

- [ ] Replace `_AppBootstrapperState` with a Riverpod `AsyncNotifier`
      (`AppStartupController`) and a `Suspense`-style splash screen
      (`AsyncValue.when`).
- [ ] Move splash / loading UI out of `MaterialApp` into a separate
      `AppShell` widget.
- [ ] Promote `MyApp` to a `ConsumerWidget` and remove the mutable
      `WidgetsBindingObserver` boilerplate by listening through providers.
