# Android — release & Play Store checklist

End-to-end runbook to ship Business Mindset on Google Play. Everything that
the agent already wired (Gradle, manifest, ProGuard, native bridge, Glance
widget, splash, launcher icons, notifications) is **done**. What remains is
the manual / account-bound work below.

---

## 0. One-shot: prerequisites

* JDK 17 (the project pins every module on JVM target 17).
* Flutter stable on the same channel as iOS (run `flutter --version`).
* Android Studio (Hedgehog or newer) with the Play Publishing plugin.
* `google-services.json` for the Android Firebase app placed at
  `android/app/google-services.json` — file is `.gitignore`d. An example is
  available at `android/app/google-services.example.json`.

---

## 1. Generate the upload keystore (once, NEVER commit it)

```bash
keytool -genkey -v \
  -keystore ~/keys/businessmindset-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Back up the resulting `.jks` somewhere safe (encrypted drive / 1Password).
**Losing this keystore = you can no longer publish updates** (Play App
Signing can replace it, but only if you opted in upfront — see Play Console
> Setup > App signing).

Then create the local credentials file Gradle reads:

```bash
cp android/key.properties.example android/key.properties
$EDITOR android/key.properties
```

Fill in:

```properties
storePassword=<the password you set with keytool>
keyPassword=<usually identical>
keyAlias=upload
storeFile=/Users/<you>/keys/businessmindset-upload-keystore.jks
```

`android/key.properties` is `.gitignore`d. The Gradle script falls back to
the debug keystore if the file is missing, so you can keep working without
it locally.

---

## 2. Pre-flight checks

```bash
flutter clean
flutter pub get
flutter analyze
flutter build apk --debug      # smoke test
flutter build apk --release    # validate R8 / ProGuard
```

If `--release` fails, the most likely culprit is a missing `-keep` rule in
`android/app/proguard-rules.pro`. Look at the stack trace, pick the package
that R8 stripped, add `-keep class <package>.** { *; }` at the bottom of
the file, and rebuild.

Bump the version before shipping:

```yaml
# pubspec.yaml
version: 1.10.0+11   # +<X> → versionCode (must strictly increase per upload)
```

---

## 3. Build the AAB (Android App Bundle)

Play Store requires AAB since Aug 2021. Two equivalent options.

### 3a. CLI

```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

### 3b. Android Studio

1. Open `android/` in Android Studio.
2. `Build > Generate Signed Bundle / APK… > Android App Bundle`.
3. Pick `~/keys/businessmindset-upload-keystore.jks` + the alias `upload`.
4. Keep both `release` flavours checked, `Generate signed bundle`.
5. Output ends up in `android/app/release/app-release.aab` (or wherever
   Android Studio reports — it'll open the folder for you).

> Either path works because both honour the `signingConfigs.release` block
> we wired in `android/app/build.gradle.kts` (which itself reads
> `key.properties`). No need to fiddle with both.

---

## 4. Play Console upload

1. Login to <https://play.google.com/console>.
2. Pick the existing **Business Mindset** app (you mentioned it's already
   created).
3. **Internal testing** track first (always). `Releases > Create new
   release > Upload AAB`.
4. Fill in the release notes (mirror the App Store notes from
   `docs/notes/CORRECTIONS_APP_STORE.md` if relevant).
5. Submit for **review** — internal builds are usually live within minutes
   to a couple of hours.
6. Test on real devices via the internal testing link (see §6).
7. When happy, promote to **Closed testing** (alpha) or **Production**.

---

## 5. Data Safety form (mandatory)

Play Store > **App content > Data safety**. Declare what each integrated
SDK collects. Below is a starting template based on the SDKs currently
wired in this codebase. **Cross-check each SDK's official Data Safety
docs before submitting** — Google rejects forms that don't match the
SDK's own disclosures.

| Data type                       | Collected | Shared | Optional | Purpose                       | SDK responsible      |
|--------------------------------|-----------|--------|----------|-------------------------------|----------------------|
| Approximate location (country) | Yes       | No     | No       | App functionality (storefront) | Telephony / locale   |
| Email address                  | Yes       | No     | Yes      | Account, support              | Firebase Auth        |
| User-generated content (favs)  | Yes       | No     | Yes      | App functionality             | Local + Firestore    |
| Purchase history               | Yes       | Yes    | No       | App functionality, analytics  | RevenueCat, Mixpanel |
| App interactions               | Yes       | Yes    | No       | Analytics, attribution        | Mixpanel, TikTok     |
| Crash logs, diagnostics        | Yes       | No     | Yes      | App stability                 | Firebase Crashlytics |
| Advertising ID (AAID)          | Yes       | Yes    | No       | Attribution                   | TikTok Events SDK    |

* **No data is sold.**
* **All data in transit is encrypted (HTTPS).**
* **Users can request deletion** — link to the in-app "Delete account"
  flow + the email shown in the support screen.

If you target children (you don't), most of the above must be flipped.
Strip `com.google.android.gms.permission.AD_ID` from the manifest in that
case (see the commented-out `<uses-permission>` line).

---

## 6. Manual smoke tests (Phase 7)

Run **before promoting any track**.

**Cold-launch / lifecycle**
- [ ] Splash screen shows the dark Flamy artwork (no white flash).
- [ ] Home page renders within ~2s on a mid-range device.
- [ ] Background → foreground keeps the same quote / theme.
- [ ] Force-stop + relaunch keeps onboarding state.

**Notifications**
- [ ] First launch onboarding step properly asks for the
      `POST_NOTIFICATIONS` permission (Android 13+).
- [ ] Schedule notifications from settings → check next 3 in
      Settings > App > Notifications > Scheduled.
- [ ] Tap a notification while the app is killed — opens the right quote.
- [ ] Trial reminder notification fires at the chosen date/time.

**Widget**
- [ ] Long-press homescreen > Widgets > Business Mindset > drag onto
      homescreen. Widget renders the latest stored quote.
- [ ] Tap the widget body → app opens via deep link.
- [ ] Tap ↻ refresh / ♥ favorite / ↗ share dots → app opens, deep-link
      handler reacts.
- [ ] Lockscreen widget: stock Android since 5.0 does NOT host third-party
      lockscreen widgets. Test on a Samsung device with One UI's
      lockscreen widget panel if you want that surface.

**Sharing**
- [ ] From a quote → Share → preview screen renders the offscreen
      Flutter card (see `lib/services/share_image_renderer.dart`).
- [ ] Share-to (system sheet) attaches a JPEG.
- [ ] Save-to-gallery saves under `Pictures/BusinessMindset/`.

**Purchases**
- [ ] Internal testing AAB lets RevenueCat see live offerings (you must
      add the tester account to the Internal testing list AND to the
      RevenueCat sandbox testers).
- [ ] Trial start → Trial reminder notification scheduled.
- [ ] Restore purchases works after a fresh install.
- [ ] Hard paywall: when blocked, widget shows the "Subscribe in the
      app" placeholder.

**Deep links**
- [ ] `adb shell am start -a android.intent.action.VIEW \
        -d "businessmindset://widget/refresh" com.bakemono.businessmindset`
      opens the app on the right screen.

**Internationalisation**
- [ ] Force device language to FR / ES / DE → strings update on next
      cold start.

---

## 7. Useful commands

```bash
# Inspect the bundle on disk
unzip -l build/app/outputs/bundle/release/app-release.aab | head

# Tag the release
git tag -a android-v1.10.0 -m "Android Play Store 1.10.0"
git push --tags

# Quickly switch back to debug builds locally
flutter run                    # uses the debug signing
```

---

## 8. Where things live in the repo

| What                              | File                                                                  |
|-----------------------------------|-----------------------------------------------------------------------|
| Release signing config            | `android/app/build.gradle.kts` (`signingConfigs.release`)             |
| Release signing credentials       | `android/key.properties` (gitignored — template at `key.properties.example`) |
| R8 / ProGuard rules               | `android/app/proguard-rules.pro`                                      |
| Permissions, deep link, widget    | `android/app/src/main/AndroidManifest.xml`                            |
| MethodChannel handlers (Kotlin)   | `android/app/src/main/kotlin/com/bakemono/businessmindset/bridge/`    |
| Glance widget                     | `android/app/src/main/kotlin/com/bakemono/businessmindset/widget/`    |
| Notification channels             | `lib/services/notification_service.dart` (`init`)                     |
| Offscreen share-card renderer     | `lib/services/share_image_renderer.dart`                              |
| Launcher icons / splash configs   | `pubspec.yaml` (`flutter_launcher_icons`, `flutter_native_splash`)    |

---

## 9. Known platform gaps (vs iOS)

* **Lockscreen widgets**: stock Android no longer surfaces them. The XML
  declares `keyguard` so OEMs that still support it can host the widget.
* **App Tracking Transparency**: not applicable on Android. The `requestATT`
  / `getATTStatus` channel methods return `not_applicable`.
* **Storefront country code**: derived from `TelephonyManager` + locale
  (best-effort). iOS uses `SKPaymentQueue.storefront`.
* **Native quote regeneration in the widget**: iOS bundles a copy of the
  full quote dataset inside the widget extension so it can refresh
  standalone. On Android the Glance widget reads whatever the app last
  wrote to `SharedPreferences`. The app rotates the stored quote based on
  the user's "frequency" setting.
