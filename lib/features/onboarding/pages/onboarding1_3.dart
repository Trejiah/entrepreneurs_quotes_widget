import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/services/widget_subscription_sync.dart';
import 'package:businessmindset/widgets/app_button.dart';

class OnBoarding13 extends ConsumerStatefulWidget {
  const OnBoarding13({
    super.key,
    this.forward,
  });
  final VoidCallback? forward;

  @override
  ConsumerState<OnBoarding13> createState() => _OnBoarding13State();
}

class _OnBoarding13State extends ConsumerState<OnBoarding13> {
  static const MethodChannel _widgetChannel = MethodChannel('businessmindset/deeplink');
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  String inputText = "";
  bool showInput = false;
  bool isPageTappable = true;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _maskTextController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showKeyboardMask = false;

  @override
  void initState() {
    super.initState();
    _maskTextController.text = _textController.text;
    _textController.addListener(() {
      setState(() {
        inputText = _textController.text;
      });
      // Sync the mask controller
      if (_maskTextController.text != _textController.text) {
        _maskTextController.text = _textController.text;
      }
    });
    _maskTextController.addListener(() {
      // Sync the other way
      if (_textController.text != _maskTextController.text) {
        _textController.text = _maskTextController.text;
      }
    });
    void onFocusChange() {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("🔍 [OnBoarding13] FocusNode listener triggered");
      debugPrint("   - hasFocus: ${_focusNode.hasFocus}");
      debugPrint("   - _showKeyboardMask (avant): $_showKeyboardMask");
      // Avoid flickering: only change state when necessary
      if (_showKeyboardMask != _focusNode.hasFocus) {
      setState(() {
        _showKeyboardMask = _focusNode.hasFocus;
      });
      }
      debugPrint("   - _showKeyboardMask (after): $_showKeyboardMask");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
    _focusNode.addListener(onFocusChange);
    debugPrint("🔍 [OnBoarding13] initState() - FocusNode listener attached, initial state: hasFocus=${_focusNode.hasFocus}");
    
    // Periodically check the focus state in case the listener doesn't fire
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentFocus = _focusNode.hasFocus;
        if (currentFocus != _showKeyboardMask) {
          debugPrint("🔍 [OnBoarding13] PostFrameCallback - Correction de l'état: hasFocus=$currentFocus, _showKeyboardMask=$_showKeyboardMask");
          setState(() {
            _showKeyboardMask = currentFocus;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _maskTextController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void handleFirstTap() {
    if (isPageTappable) {
      setState(() {
        showInput = true;
        isPageTappable = false;
      });
    }
  }

  saveInput(String value) async {
    final prefs = await SharedPreferences.getInstance();
    // Remove trailing whitespace
    inputText = value.trimRight();
    await prefs.setString("name", inputText);
    // Also save in "userName" for consistency
    await prefs.setString("userName", inputText);
    
    // Also save to the widget's shared UserDefaults
    try {
      final premiumExpirationEpochMs = await fetchWidgetPremiumExpirationEpochMs();
      await _widgetChannel.invokeMethod('updateWidgetData', {
        'userName': inputText,
        'premiumExpirationEpochMs': premiumExpirationEpochMs,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint("⚠️ [OnBoarding13] Error while saving userName to the widget: $e");
      }
    }
    
    // Update the provider only if the widget is still mounted
    if (mounted) {
      ref.read(userNameStateProvider.notifier).state = inputText;
    }
  }

  handleTap() async {
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("Input saved! : $inputText");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
    // Remove trailing whitespace before checking
    if (inputText.trimRight().isNotEmpty) {
      // Make sure the save is complete before navigating
      await saveInput(inputText);
      // Verify the widget is still mounted after the save
      if (mounted) {
        widget.forward!();
      }
    }
  }

  void _handleSwipeLeft(BuildContext context, DragEndDetails details) {
    // Do not handle swipe if the keyboard is open
    if (_showKeyboardMask) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final double kMinDx = screenWidth * 0.2; // Minimum 20% de la largeur de l'écran
    final vx = details.velocity.pixelsPerSecond.dx;
    final bool flingLeft = vx <= -300; // Vitesse minimale pour un swipe rapide
    final bool farLeft = details.primaryVelocity != null && details.primaryVelocity! < -kMinDx;

    if (flingLeft || farLeft) {
      // If we're in the initial phase (before input), trigger handleFirstTap
      if (isPageTappable && !showInput) {
        handleFirstTap();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isButtonEnabled = inputText.trimRight().isNotEmpty;
    final currentFocus = _focusNode.hasFocus;
    debugPrint("🔍 [OnBoarding13] build() - _showKeyboardMask: $_showKeyboardMask, hasFocus: $currentFocus");
    
    // Sync state if needed (in case the listener doesn't fire)
    if (currentFocus != _showKeyboardMask) {
      debugPrint("🔍 [OnBoarding13] build() - Desync detected, correcting...");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNode.hasFocus != _showKeyboardMask) {
          setState(() {
            _showKeyboardMask = _focusNode.hasFocus;
          });
        }
      });
    }

    return GestureDetector(
      onTap: isPageTappable ? handleFirstTap : null,
      onHorizontalDragEnd: (details) => _handleSwipeLeft(context, details),
      behavior: isPageTappable ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
      child: Container(
        height: double.maxFinite,
        width: double.maxFinite,
        color: appTheme.background,
        child: SafeArea(
          bottom: false,
          child: Builder(
            builder: (context) {
              // Enable scroll only if text scale > 1.0
              final textScale = MediaQuery.of(context).textScaler.scale(1.0);
              final shouldEnableScroll = textScale > 1.0;
              
              final content = Align(
                alignment: Alignment.center,
                child: Stack(
                  children: [
                  // Contenu principal (image + textes)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                          Column(
                            children: [
                              SizedBox(height: 60*yFact,),
                              SizedBox(
                                height: 300 * yFact,
                                child: Image.asset(
                                  'assets/images/flamy/flamy_hi.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              SizedBox(height: 15 * yFact),
                              // Conditional texts based on state
                              if (!showInput) ...[
                                // Before tap
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 40 * xFact),
                                  child: Text(
                                    translate("onboarding13_greeting", lang),
                                    style: TextStyle(
                                      fontFamily: "YesevaOne",
                                      fontSize: 28 * xFact,
                                      color: appTheme.onBackground,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: 10 * yFact),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 40 * xFact),
                                  child: Text(
                                    translate("onboarding13_flamy_intro", lang),
                                    style: TextStyle(
                                      fontFamily: "YesevaOne",
                                      fontSize: 28 * xFact,
                                      color: appTheme.onBackground,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ] else ...[
                                // After tap
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 40 * xFact),
                                  child: Text(
                                    translate("onboarding13_title", lang),
                                    style: TextStyle(
                                      fontFamily: "YesevaOne",
                                      fontSize: 28 * xFact,
                                      color: appTheme.onBackground,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: 15 * yFact),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 55 * xFact),
                                  child: Text(
                                    translate("onboarding13_subtitle", lang),
                                    style: TextStyle(
                                      fontFamily: "InterTight",
                                      fontSize: 18 * xFact,
                                      color: Color(0xFFb4ac9c),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 0*yFact,),
                          if (showInput)
                            Padding(
                              padding: EdgeInsetsGeometry.only(
                                right: 20 * xFact,
                                left: 20 * xFact,
                                bottom: 30 * yFact,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                       CustomTextField(
                                         focusNode: _focusNode,
                                         controller: _textController,
                                         onTap: () async {
                                           _focusNode.requestFocus();
                                           await SystemChannels.textInput
                                               .invokeMethod<void>('TextInput.show');
                                         },
                                         height: 50,
                                         maxLength: 20,
                                         inputStyle: "input1",
                                         textInputAction: TextInputAction.done,
                                         fontFamily: "InterTight",
                                         fontSize: 18 * xFact,
                                         backgroundColor: Color(0xFF504b41),
                                         borderColor: Color(0xFFfff9ee),
                                         textColor: Color(0xFFb4ac9c),
                                         hintText: translate("your name", lang),
                                         onChanged: (String value) {
                                           setState(() {
                                             inputText = value;
                                           });
                                         },
                                       ),
                                      // Counter positioned just below, right-aligned
                                      Padding(
                                        padding: EdgeInsets.only(
                                          right: 12 * xFact,
                                          top: 4 * yFact,
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: ValueListenableBuilder<TextEditingValue>(
                                            valueListenable: _textController,
                                            builder: (context, value, child) {
                                              return Text(
                                                '${value.text.length}/20',
                                                style: TextStyle(
                                                  fontFamily: "InterTight",
                                                  fontSize: 18 * xFact * 0.8,
                                                  color: appTheme.onBackground,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 50*yFact,),
                                  Opacity(
                                    opacity: isButtonEnabled ? 1.0 : 0.5,
                                    child: IgnorePointer(
                                      ignoring: !isButtonEnabled,
                                      child: SecondaryButton(
                                        text: translate("continue", lang),
                                        onTap: () => handleTap(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                  // Opaque container with centered CustomTextField when focus is active
                  if (_showKeyboardMask)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () {
                          // If we tap the mask, unfocus the main field
                          _focusNode.unfocus();
                        },
                      child: Container(
                        color: appTheme.background.withValues(alpha: 0.5),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
                            child: IgnorePointer(
                              child: CustomTextField(
                                controller: _textController,
                                height: 50,
                                maxLength: 20,
                                inputStyle: "input1",
                                fontFamily: "InterTight",
                                fontSize: 18 * xFact,
                                backgroundColor: Color(0xFF504b41),
                                borderColor: Color(0xFFfff9ee),
                                textColor: Color(0xFFb4ac9c),
                                hintText: translate("your name", lang),
                                onChanged: (String value) {
                                  // Sync with the main controller
                                  if (_textController.text != value) {
                                    _textController.text = value;
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      ),
                    ),
                  ],
                ),
              );
              
              // Return with or without scroll depending on textScale
              if (shouldEnableScroll) {
                return SingleChildScrollView(child: content);
              } else {
                return content;
              }
            },
          ),
        ),
      ),
    );
  }
}

