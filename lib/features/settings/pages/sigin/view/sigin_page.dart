import 'dart:io' show Platform;

import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/settings/pages/sigin/view_model/sigin_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SyncPage extends ConsumerStatefulWidget {
  const SyncPage({super.key});

  @override
  ConsumerState<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends ConsumerState<SyncPage> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  Widget _buildGoogleSignInButton(String lang) {
    final vm = ref.read(siginViewModelProvider.notifier);
    return SizedBox(
      width: double.maxFinite,
      height: 50 * yFact,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * xFact),
        child: InkWell(
          borderRadius: BorderRadius.circular(20 * xFact),
          onTap: () async => vm.logIn(ref),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14 * xFact),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 22 * xFact,
                  height: 22 * xFact,
                  child: Image.asset(
                    "assets/images/google_logo.png",
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(width: 10 * xFact),
                Flexible(
                  child: Text(
                    translate("googlelogin", lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF1F1F1F),
                      fontFamily: "InterTight",
                      fontWeight: FontWeight.w600,
                      fontSize: 18 * xFact,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(siginViewModelProvider.notifier).refreshAuthState();
    });
  }

  void showCancelPremiumDialog(
      BuildContext context, {
        // 🅰️ Typo
        String titleFont = "YesevaOne",
        String bodyFont = "InterTight",

        // ⚙️ Actions // "I've changed my mind"
        VoidCallback? onSecondary, // "I'm sure"

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
                width: MediaQuery.of(ctx).size.width*9/10,
                height: MediaQuery.of(ctx).size.height*6/10,
                decoration: BoxDecoration(
                  color: Color(0xFF575757),
                  borderRadius: BorderRadius.circular(18*xFact),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 25*xFact,right: 25*xFact,bottom: 5*yFact),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              SizedBox(height: 20*yFact),
                              SizedBox(
                                height: 100*yFact,
                                child: Image.asset("assets/images/warning.png"),
                              ),
                              Text(
                                translate("aresure", lang),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: titleFont,
                                  fontSize: 28*xFact,
                                  height: 1.2*yFact,
                                  color: appTheme.onBackground,
                                ),
                              ),
                              SizedBox(height: 30*yFact),
                              // Corps
                              Text(
                                translate("deleteAc", lang),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: bodyFont,
                                  fontSize: 18*xFact,
                                  height: 1.35*yFact,
                                  color: appTheme.onBackground,
                                ),
                              ),
                              SizedBox(height: 18*yFact),
                            ],
                          ),

                          // Primary button (gold, filled)
                          Column(
                            children: [
                              PrimaryButton(
                                text: translate("changemind", lang),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                },
                              ),
                              SizedBox(
                                height: 10*yFact,
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: appTheme.onBackground,
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18*xFact,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  onSecondary?.call();
                                },
                                child: Text(
                                    translate("deleteaccount", lang)
                                ),
                              ),
                              SizedBox(height: 8*yFact),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Close button (top left, as in the screenshot)
                    Positioned(
                      top: 10*yFact,
                      left: 10*xFact,
                      child: Material(
                        color: Colors.transparent,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          color: appTheme.onBackground,
                          tooltip: "Close",
                          onPressed: () {
                            Navigator.of(ctx).pop();
                          },
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


  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final ui = ref.watch(siginViewModelProvider);
    final vm = ref.read(siginViewModelProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: appTheme.background),
        child: SafeArea(
          top: true,
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
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 10*xFact,
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.arrow_back_ios, color: appTheme.onBackground, size: 30 * xFact),
                          ),
                          SizedBox(width: 5 * xFact),
                          Text(
                            translate("cloudsync", lang),
                            style: TextStyle(
                              fontFamily: "YesevaOne",
                              color: appTheme.onBackground,
                              fontSize: 35 * xFact,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 40*yFact,
                    ),
                    Padding(
                      padding: EdgeInsetsGeometry.only(left: 20*xFact,right: 20*xFact),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          translate("savedata2", lang),
                          style: TextStyle(
                            fontFamily: "InterTight",
                            fontSize: 20*xFact,
                            color: appTheme.onBackgroundSub,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                        height: 35 * yFact
                    ),
                  ],
                ),
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsetsGeometry.only(right: 20*xFact,left: 20*xFact,bottom: 20*yFact),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Stack(
                          children: [
                            // If the user is signed in, show the custom sign-out button
                            if (ui.signedIn)
                              SecondaryButton(
                                text: translate("logout",lang),
                                onTap: () => vm.logOut(),
                              )
                            // If the user is not signed in
                            else
                              Platform.isIOS
                                  // On iOS: use the official Apple button
                                  ? SizedBox(
                                      width: double.maxFinite,
                                      height: 50 * yFact,
                                      child: SignInWithAppleButton(
                                        onPressed: () async => vm.logIn(ref),
                                        height: 50 * yFact,
                                        text: translate("applelogin", lang),
                                        style: SignInWithAppleButtonStyle.white,
                                      ),
                                    )
                                  // On Android: use the custom button
                                  : _buildGoogleSignInButton(lang),
                            // Lock icon positioned in the top-right corner if !premium and on the login button
                          ],
                        ),
                      ),
                    ),
                    ui.userSign ? GestureDetector(
                      onTap: () {
                        showCancelPremiumDialog(
                          lang: lang,
                          context,
                          onSecondary: () => vm.deleteAccount(),
                        );
                      },
                      child: SizedBox(
                        height: 50*yFact,
                        child: Text(
                          translate("deleteaccount", lang),
                          style: TextStyle(
                            fontFamily: "InterTight",
                            fontSize: 20*xFact,
                            color: appTheme.onBackground,
                          ),
                        ),
                      ),
                    ) : SizedBox(
                      height: 50*yFact,
                    )
                  ],
                )

              ],
            ),
          ),
        ),
      ),
    );
  }
}
