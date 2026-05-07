import 'dart:async';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_localizations.dart';
import '../core/global_scaler.dart';
import '../providers/language_provider.dart';
import '../widgets/app_button.dart';
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';

class ReviewPopupWidget extends ConsumerStatefulWidget {
  final String userName;
  final VoidCallback onDismiss;
  final VoidCallback? onAccepted;

  const ReviewPopupWidget({
    super.key,
    required this.userName,
    required this.onDismiss,
    this.onAccepted,
  });

  @override
  ConsumerState<ReviewPopupWidget> createState() => _ReviewPopupWidgetState();
}

class _ReviewPopupWidgetState extends ConsumerState<ReviewPopupWidget> {
  int _selectedStars = 0;
  bool _starTapped = false;

  Future<void> _openStore() async {
    const androidPackage = "com.bakemono.businessmindset";
    const iosAppId = "6754601387";
    final url = Platform.isIOS
        ? "https://apps.apple.com/app/id$iosAppId?action=write-review"
        : "https://play.google.com/store/apps/details?id=$androidPackage";
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _onStarTapped(int starIndex) async {
    if (_starTapped) return;
    setState(() {
      _selectedStars = starIndex;
      _starTapped = true;
    });

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    await _openStore();

    if (widget.onAccepted != null) {
      widget.onAccepted!();
    } else {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.read(languageProvider);
    final xFact = ScreenScale.x;
    final yFact = ScreenScale.y;

    final title = translate("review_popup_title", lang);
    final body = translate("review_popup_body", lang);
    final rateButton = translate("review_popup_rate_button", lang);
    final maybeLater = translate("maybe_later", lang);

    final titleWithName = title.replaceAll("%NAME%", widget.userName);

    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 320 * xFact,
              decoration: BoxDecoration(
                color: const Color(0xFF575757),
                borderRadius: BorderRadius.circular(20 * xFact),
              ),
              padding: EdgeInsets.all(24 * xFact),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image Flamy coeur
                  Image.asset(
                    'assets/images/flamy/flamy_coeur.png',
                    width: 120 * xFact,
                    height: 120 * xFact,
                    fit: BoxFit.contain,
                  ),

                  SizedBox(height: 20 * yFact),

                  // Titre
                  Text(
                    titleWithName,
                    style: TextStyle(
                      fontFamily: "YesevaOne",
                      fontSize: 22 * xFact,
                      fontWeight: FontWeight.bold,
                      color: appTheme.onBackground,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 16 * yFact),

                  // Body text
                  Text(
                    body,
                    style: TextStyle(
                      fontFamily: "InterTight",
                      fontSize: 16 * xFact,
                      color: appTheme.onBackground,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 24 * yFact),

                  // Row of 5 stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final isSelected = i < _selectedStars;
                      return GestureDetector(
                        onTap: _starTapped ? null : () => _onStarTapped(i + 1),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5 * xFact),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              isSelected
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              key: ValueKey(isSelected),
                              size: 42 * xFact,
                              color: isSelected
                                  ? const Color(0xFFeca70b)
                                  : appTheme.onBackground.withOpacity(0.35),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  SizedBox(height: 24 * yFact),

                  // Bouton "Leave a Review"
                  SecondaryButton(
                    text: rateButton,
                    onTap: () async {
                      await _openStore();
                      if (widget.onAccepted != null) {
                        widget.onAccepted!();
                      } else {
                        widget.onDismiss();
                      }
                    },
                    height: 50 * yFact,
                    borderRadius: 12 * xFact,
                  ),

                  SizedBox(height: 16 * yFact),

                  // "Maybe later"
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Text(
                      maybeLater,
                      style: TextStyle(
                        fontFamily: "InterTight",
                        fontSize: 14 * xFact,
                        color: appTheme.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
