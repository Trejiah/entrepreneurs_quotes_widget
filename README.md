# Business Mindset

A Flutter app that delivers a daily curated quote about entrepreneurship,
discipline, and growth — with notification scheduling, a custom iOS Home /
Lock-screen widget, in-app paywall (RevenueCat), analytics (Mixpanel), and
attribution (TikTok Events SDK).

Published on the App Store and the Play Store as **Business Mindset Quotes**.

> This repository is shared as a portfolio. The source code is published
> under an [All Rights Reserved](LICENSE) license — see the LICENSE file
> before doing anything with it.

## Screenshots

Add 4 – 6 PNGs in `docs/screenshots/` and reference them here. See
[`docs/screenshots/README.md`](docs/screenshots/README.md) for the
recommended set and naming convention.

<!--
| Home | Themes | Widget | Paywall |
|---|---|---|---|
| ![Home](docs/screenshots/01-home.png) | ![Themes](docs/screenshots/02-themes.png) | ![Widget](docs/screenshots/03-widget-config.png) | ![Paywall](docs/screenshots/04-paywall.png) |
-->

## Tech stack

- **Flutter 3.9 / Dart 3** — single codebase, iOS + Android.
- **Riverpod** — app-wide state management (themes, language, premium flag,
  habits, daily quote pipeline).
- **Firebase** — Authentication, Realtime Database, Crashlytics,
  Remote Config.
- **RevenueCat** — subscription and trial management, A/B-tested paywalls.
- **Mixpanel** — product analytics (funnel events, paywall conversion,
  retention).
- **TikTok Events SDK** — install / trial / purchase attribution, with
  per-storefront account routing (US vs. ROW) and event persistence
  across cold starts.
- **WidgetKit (Swift)** — native iOS Home / Lock-screen widget that pulls
  quotes from the Flutter app via App Groups and a `MethodChannel`.
- **flutter_local_notifications** — daily quote scheduling with
  per-language content and timezone awareness.

## Project structure

```
lib/
├── app/                      # App-level glue (deep links, …)
├── bootstrap/                # Firebase + service init helpers
├── config/                   # Env class (flutter_dotenv) + product IDs
├── core/                     # Theming, scaler, root navigator, i18n
├── models/                   # Quotes / motivation / habit data models
├── onboarding/               # Onboarding flow
├── providers/                # Riverpod providers
├── services/                 # Notifications, RevenueCat, Mixpanel,
│                             # TikTok, share, mindset points, …
├── theme/                    # AppColors / theme registry
├── utils/                    # Image, favorite, time helpers
├── views/
│   ├── home_page.dart        # Main screen (audited – see docs/audit/)
│   ├── home/                 # Extracted home sub-widgets
│   ├── paywall/              # Paywall variants + presenter
│   └── settings_pages/       # Themes, widget config, notifications, …
├── widgets/                  # Reusable UI atoms
└── main.dart                 # Bootstrap

ios/
├── Runner/                   # Flutter host app + native channels
└── BusinessMindsetWidget/    # WidgetKit extension (Swift)

docs/
├── audit/                    # Written audits of the largest files
├── notes/                    # How-to notes (fonts, widget integration…)
└── screenshots/              # README screenshots

scripts/                      # Standalone helper scripts
```

## Setup

You need:

- **Flutter** ≥ 3.9 (`fvm use 3.9.x` or system Flutter).
- **Xcode** ≥ 16 + a recent CocoaPods (`sudo gem install cocoapods`).
- **Android Studio** with the Android SDK + NDK installed.
- A **Firebase project** of your own.
- A **RevenueCat project** with the same product IDs the app references
  (`premium_annual`, `premium_monthly`, plus the A/B variants — see
  `.env.example`).

### 1. Clone and install dependencies

```bash
git clone https://github.com/<your-org>/businessmindset.git
cd businessmindset
flutter pub get
```

### 2. Provide your Firebase configuration

The repository ships **template** Firebase configuration files. The real
ones are gitignored. The recommended way is to regenerate them with the
[FlutterFire CLI](https://firebase.flutter.dev/docs/cli/):

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

…which will create / overwrite:

- `firebase.json` (mapping FlutterFire — **ne pas committer** ; voir `.gitignore`)
- `lib/firebase_options.dart`
- `ios/Runner/GoogleService-Info.plist`
- `ios/firebase_app_id_file.json`
- `android/app/google-services.json`

If you prefer to copy the templates manually:

```bash
cp firebase.json.example                       firebase.json
cp lib/firebase_options.example.dart           lib/firebase_options.dart
cp ios/Runner/GoogleService-Info.example.plist ios/Runner/GoogleService-Info.plist
cp ios/firebase_app_id_file.example.json       ios/firebase_app_id_file.json
cp android/app/google-services.example.json    android/app/google-services.json
```

…and fill in your own values (or prefer `flutterfire configure`, which génère aussi `firebase.json`).

### 3. Provide the runtime secrets (`.env`)

```bash
cp .env.example .env
$EDITOR .env
```

`.env` is gitignored. It carries the RevenueCat public SDK keys, the
Mixpanel project token, the TikTok Events SDK identifiers, and the
subscription product IDs. The `Env` class
([`lib/config/env.dart`](lib/config/env.dart)) reads them with this
priority:

```
--dart-define=KEY=value   >   .env (asset)   >   hard-coded fallback
```

So in CI you can keep `.env` empty and inject every secret with
`--dart-define`.

### 4. Run

```bash
flutter run                                           # default device
flutter run -d "iPhone 15 Pro"                        # specific simulator
flutter run --release --dart-define=MIXPANEL_TOKEN=…  # release with overrides
```

## iOS Widget

The Home / Lock-screen widget lives in
`ios/BusinessMindsetWidget/`. Integration notes live in
[`docs/notes/`](docs/notes/) (font registration, widget cropping, button
recap, store localisation verification, etc.).

## Architecture notes

### Bootstrap pipeline

`main()` is intentionally tiny:

1. Initialize the Flutter binding and lock orientation.
2. Load `.env` via `Env.load()`.
3. Hand control to `AppBootstrapper`, which initialises Firebase (with a
   small retry loop because Pigeon channels are not always ready on the
   first frame), wires Crashlytics as the global error sink, loads
   `SharedPreferences`, builds the theme list, decides between onboarding
   and home, and finally renders `MyApp`.

The bootstrap is being progressively split into
`lib/bootstrap/firebase_bootstrap.dart` and `lib/app/deep_link_handler.dart`
— see [`docs/audit/main.dart.md`](docs/audit/main.dart.md).

### Home screen

`lib/views/home_page.dart` is the single largest file in the project (~4.7k
lines). It is the screen that handles quote navigation, daily limit, native
widget bridging, deep links, notifications, tutorial overlay, paywalls, and
review prompts. It is being progressively split into feature folders under
`lib/views/home/` — see [`docs/audit/home_page.dart.md`](docs/audit/home_page.dart.md).

### Secrets and configuration

- **No secret is committed.** The real Firebase config files,
  `lib/firebase_options.dart`, `firebase.json` (IDs projet / apps), and `.env`
  are gitignored.
- **Google Sign-In Android** : le Web client ID (`GOOGLE_ANDROID_SERVER_CLIENT_ID`)
  est lu depuis `.env` / `--dart-define`, pas en dur dans le code.
- The code refers to runtime configuration only through
  `Env` / typed getters, not through embedded third-party credentials.
- Templates live next to the real files with the `.example` suffix so a
  fresh contributor sees what is expected.

### Analytics & attribution

`MixpanelService.instance` is a thin wrapper that no-ops gracefully when
`MIXPANEL_TOKEN` is missing, so opening the project without secrets
still runs.

`TikTokService.instance` selects the correct TikTok Ads account at runtime
based on the App Store storefront country (US vs. ROW), persists critical
attribution events (`StartTrial`, `CompletePayment`) in
`SharedPreferences` so they survive a kill before the SDK is initialised,
and replays them on the next launch.

## Quality

```bash
flutter analyze
```

Project status today:

- 0 errors.
- A backlog of warnings / infos (mostly `withOpacity` deprecations,
  `print` → `debugPrint` rewrites and a few `use_build_context_synchronously`
  — tracked alongside the audits).

## License

[All Rights Reserved](LICENSE). Read the LICENSE file before doing
anything with this code.
