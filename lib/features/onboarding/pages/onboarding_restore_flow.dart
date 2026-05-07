import 'package:businessmindset/services/save_cloud.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/services/auth_sign.dart';
import 'package:businessmindset/services/mindset_points_service.dart';
import 'package:businessmindset/services/revenuecat_service.dart';
import 'package:businessmindset/widgets/app_button.dart';

/// Statut de restore :
/// - restored: active entitlement found/restored
/// - notFound: restore done, nothing to restore (SnackBar)
/// - other: user cancelled / indeterminate state -> no SnackBar, no popup
enum RestorePurchaseStatus { restored, notFound, other }

class OnboardingRestoreFlow {
  static bool _isCancelledPlatformException(PlatformException e) {
    final rc = PurchasesErrorHelper.getErrorCode(e);
    if (rc == PurchasesErrorCode.purchaseCancelledError) return true;

    // iOS fallback: sometimes the RC code isn't purchaseCancelledError.
    final rawCode = e.code.toLowerCase();
    final msg = (e.message ?? '').toLowerCase();
    final details = (e.details ?? '').toString().toLowerCase();
    return rawCode.contains('cancel') ||
        msg.contains('cancel') ||
        msg.contains('canceled') ||
        msg.contains('cancelled') ||
        msg.contains('annul') ||
        details.contains('cancel') ||
        details.contains('canceled') ||
        details.contains('cancelled') ||
        details.contains('annul');
  }

  static bool _looksLikeUserCancelledStoreLogin({
    required CustomerInfo before,
    required CustomerInfo after,
    required Duration elapsed,
  }) {
    // iOS heuristic: Apple login cancellation during restorePurchases()
    // may not throw and return an unchanged CustomerInfo.
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;

    final unchangedUser = before.originalAppUserId == after.originalAppUserId;
    final beforePurchases = before.allPurchasedProductIdentifiers.toSet();
    final afterPurchases = after.allPurchasedProductIdentifiers.toSet();
    final unchangedPurchases = beforePurchases.length == afterPurchases.length && beforePurchases.containsAll(afterPurchases);

    final beforeSubs = before.activeSubscriptions.toSet();
    final afterSubs = after.activeSubscriptions.toSet();
    final unchangedSubs = beforeSubs.length == afterSubs.length && beforeSubs.containsAll(afterSubs);

    // Low threshold: the user can cancel quickly.
    final tookLongEnough = elapsed.inMilliseconds >= 250;

    return unchangedUser && unchangedPurchases && unchangedSubs && tookLongEnough;
  }

  static Future<RestorePurchaseStatus> _restoreStatus({
    required WidgetRef ref,
  }) async {
    // Configure RevenueCat without userId (anonymous)
    await RevenueCatService.instance.ensureConfigured(appUserId: null);

    final before = await RevenueCatService.instance.getCustomerInfo(forceRefresh: true);
    if (RevenueCatService.instance.hasActiveEntitlement(before)) {
      return RestorePurchaseStatus.restored;
    }

    final sw = Stopwatch()..start();
    try {
      final after = await RevenueCatService.instance.restorePurchases();
      sw.stop();

      if (RevenueCatService.instance.hasActiveEntitlement(after)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('premiumState', true);
        ref.read(premiumProvider.notifier).state = true;
        return RestorePurchaseStatus.restored;
      }

      if (_looksLikeUserCancelledStoreLogin(before: before, after: after, elapsed: sw.elapsed)) {
        return RestorePurchaseStatus.other;
      }

      return RestorePurchaseStatus.notFound;
    } on PlatformException catch (e) {
      sw.stop();
      if (_isCancelledPlatformException(e)) {
        return RestorePurchaseStatus.other;
      }
      rethrow;
    }
  }

  /// Restore seul (utilisable si besoin).
  /// - notFound -> SnackBar
  /// - other -> rien
  static Future<RestorePurchaseStatus> restoreOnly({
    required BuildContext context,
    required WidgetRef ref,
    required String lang,
  }) async {
    try {
      final status = await _restoreStatus(ref: ref);
      if (!context.mounted) return status;

      if (status == RestorePurchaseStatus.notFound) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              translate("restore_not_found", lang),
              style: const TextStyle(fontFamily: "InterTight"),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return status;
    } catch (e) {
      if (!context.mounted) return RestorePurchaseStatus.other;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            translate("restore_error", lang),
            style: const TextStyle(fontFamily: "InterTight"),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return RestorePurchaseStatus.other;
    }
  }

  /// Prepare the "go home" state (SharedPrefs + RevenueCat config) without navigating.
  static Future<void> prepareGoHome({required bool skipRevenueCatCheck}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("hasOnboard", true);

    if (!skipRevenueCatCheck) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await RevenueCatService.instance.ensureConfigured(appUserId: user.uid);
        } catch (_) {
          // noop
        }
      }
    }
  }

  /// Flux complet (restore -> (si restored) popup sign-in cloud -> load cloud -> goHome).
  ///
  /// Rules:
  /// - restored: continue vers popup
  /// - notFound: SnackBar "restore_not_found", stop
  /// - other: silent stop (Apple ID cancel / indeterminate)
  static Future<void> runFullFlow({
    required BuildContext context,
    required WidgetRef ref,
    required String lang,
    required Future<void> Function({required bool skipRevenueCatCheck}) goHome,
  }) async {
    MindsetPointsService.instance.disableSave();

    RestorePurchaseStatus status;
    try {
      status = await _restoreStatus(ref: ref);
    } on PlatformException catch (e) {
      // If it's a store cancellation: silent stop
      if (_isCancelledPlatformException(e)) {
      MindsetPointsService.instance.enableSave();
        return;
      }
      status = RestorePurchaseStatus.other;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              translate("restore_error", lang),
              style: const TextStyle(fontFamily: "InterTight"),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      status = RestorePurchaseStatus.other;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              translate("restore_error", lang),
              style: const TextStyle(fontFamily: "InterTight"),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    if (!context.mounted) {
      MindsetPointsService.instance.enableSave();
      return;
    }

    if (status == RestorePurchaseStatus.notFound) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            translate("restore_not_found", lang),
            style: const TextStyle(fontFamily: "InterTight"),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      MindsetPointsService.instance.enableSave();
      return;
    }

    if (status != RestorePurchaseStatus.restored) {
      MindsetPointsService.instance.enableSave();
      return;
    }

    await _askForFirebaseSignIn(
      lang: lang,
      ctx: context,
      ref: ref,
      hasPremium: true,
      goHome: goHome,
    );
  }

  static String? _tryTranslate(String key, String lang) {
    try {
      final result = translate(key, lang);
      if (result == key) return null;
      return result;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _askForFirebaseSignIn({
    required String lang,
    required BuildContext ctx,
    required WidgetRef ref,
    required bool hasPremium,
    required Future<void> Function({required bool skipRevenueCatCheck}) goHome,
  }) async {
    final platformName = (defaultTargetPlatform == TargetPlatform.iOS) ? "Apple" : "Google";

    final title = hasPremium ? translate("restore_success", lang) : (_tryTranslate("sign_in_cloud", lang) ?? "Sign in");
    final rawSubTitle = hasPremium
        ? (_tryTranslate("sign_in_cloud_subtitle", lang) ??
            "Do you want to sign in with Apple to recover your saved data from the cloud?")
        : (_tryTranslate("sign_in_cloud_subtitle_no_premium", lang) ??
            "Sign in with Apple to recover your saved data from the cloud.");
    final subTitle = rawSubTitle.replaceAll("Apple", platformName);

    final buttonText = _tryTranslate("yes_sign_in", lang) ?? translate("sign_in", lang);

    _showLogInDialog(
      ctx,
      lang: lang,
      title: title,
      subTitle: subTitle,
      buttonMessage: buttonText,
      userOk: true,
      onSecondary: () async {
        await _signInAndLoadData(lang: lang, ctx: ctx, ref: ref, hasPremium: hasPremium, goHome: goHome);
      },
      onTertiary: () async {
       MindsetPointsService.instance.enableSave();
        await goHome(skipRevenueCatCheck: false);
      },
    );
  }

  static Future<void> _signInAndLoadData({
    required String lang,
    required BuildContext ctx,
    required WidgetRef ref,
    required bool hasPremium,
    required Future<void> Function({required bool skipRevenueCatCheck}) goHome,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _loadFirebaseData(lang: lang, ctx: ctx, ref: ref, hasPremium: hasPremium, goHome: goHome);
        return;
      }

      final credential = await signInWithPlatform();
      if (!ctx.mounted) return;

      final user = credential.user;
      if (user != null) {
        try {
          await RevenueCatService.instance.ensureConfigured(appUserId: user.uid);
        } catch (_) {}
        if (!ctx.mounted) return;
        await _loadFirebaseData(lang: lang, ctx: ctx, ref: ref, hasPremium: hasPremium, goHome: goHome);
      } else {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(
                translate("sign_in_error", lang),
                style: const TextStyle(fontFamily: "InterTight"),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        // Apple login cancel (Firebase): just close the popup.
        MindsetPointsService.instance.enableSave();
        if (ctx.mounted) Navigator.of(ctx).pop();
        return;
      }
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(
              translate("sign_in_error", lang),
              style: const TextStyle(fontFamily: "InterTight"),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on FirebaseAuthException catch (_) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(
              translate("sign_in_error", lang),
              style: const TextStyle(fontFamily: "InterTight"),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(
              translate("sign_in_error", lang),
              style: const TextStyle(fontFamily: "InterTight"),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  static Future<void> _loadFirebaseData({
    required String lang,
    required BuildContext ctx,
    required WidgetRef ref,
    required bool hasPremium,
    required Future<void> Function({required bool skipRevenueCatCheck}) goHome,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      await goHome(skipRevenueCatCheck: false);
      return;
    }

    final databaseRef = FirebaseDatabase.instance.ref('users/$uid');
    final snapshot = await databaseRef.get();

    try {
      if (!ctx.mounted) return;

      if (snapshot.exists) {
        await loadAllCloud(ref);
        await Future.delayed(const Duration(milliseconds: 100));
        MindsetPointsService.instance.enableSave();
        if (ctx.mounted) Navigator.of(ctx).pop();
        await goHome(skipRevenueCatCheck: false);
      } else {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(
                translate("account_not_found", lang),
                style: const TextStyle(fontFamily: "InterTight"),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        MindsetPointsService.instance.enableSave();
        if (ctx.mounted) Navigator.of(ctx).pop();
        await goHome(skipRevenueCatCheck: false);
      }
    } catch (_) {
      MindsetPointsService.instance.enableSave();
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(
              translate("sign_in_error", lang),
              style: const TextStyle(fontFamily: "InterTight"),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(ctx).pop();
      }
      await goHome(skipRevenueCatCheck: false);
    }
  }

  static void _showLogInDialog(
    BuildContext context, {
    String titleFont = "YesevaOne",
    String bodyFont = "InterTight",
    String title = "",
    String subTitle = "",
    String buttonMessage = "",
    VoidCallback? onSecondary,
    VoidCallback? onTertiary,
    bool userOk = false,
    String lang = "en",
  }) {
    final xFact = ScreenScale.x;
    final yFact = ScreenScale.y;

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
                height: userOk
                    ? MediaQuery.of(ctx).size.height * 4 / 10
                    : MediaQuery.of(ctx).size.height * 3 / 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF575757),
                  borderRadius: BorderRadius.circular(18 * xFact),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: userOk ? 55 * yFact : 75 * yFact,
                        left: 25 * xFact,
                        right: 25 * xFact,
                        bottom: 5 * yFact,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text(
                                translate(title, lang),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: titleFont,
                                  fontSize: 28 * xFact,
                                  height: 1.2 * yFact,
                                  color: appTheme.onBackground,
                                ),
                              ),
                              if (userOk) SizedBox(height: 30 * yFact),
                              if (userOk)
                                Text(
                                  translate(subTitle, lang),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: bodyFont,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 18 * xFact,
                                    height: 1.35 * yFact,
                                    color: appTheme.onBackground,
                                  ),
                                ),
                            ],
                          ),
                          Column(
                            children: [
                              PrimaryButton(
                                text: translate(buttonMessage, lang),
                                onTap: () => onSecondary?.call(),
                              ),
                              SizedBox(height: 10 * yFact),
                              SizedBox(height: 8 * yFact),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 5 * yFact,
                      left: 5 * xFact,
                      child: Material(
                        color: Colors.transparent,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          color: appTheme.onBackground,
                          tooltip: "Close",
                          onPressed: () => onTertiary?.call(),
                        ),
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
}

