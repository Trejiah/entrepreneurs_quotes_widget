import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/onboarding/pages/improvement_step/view_model/improvement_step_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/widgets/app_button.dart';

class OnBoarding4 extends ConsumerStatefulWidget {
  const OnBoarding4({
    super.key,
    this.forward,
  });
  final VoidCallback? forward;

  @override
  ConsumerState<OnBoarding4> createState() => _OnBoarding4State();
}

class _OnBoarding4State extends ConsumerState<OnBoarding4> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  
  // Choices list based on the image
  final List<String> choiceList = const [
    "myconsistency",
    "myfocus",
    "myambition",
    "myconfidence",
    "mygoals",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(improvementStepProvider(choiceList).notifier)
          .loadSavedSelections();
    });
  }

  handleTap() async {
    await ref.read(improvementStepProvider(choiceList).notifier).saveSelections();
    if (widget.forward != null) {
      widget.forward!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final userName = ref.watch(userNameStateProvider);
    final uiState = ref.watch(improvementStepProvider(choiceList));
    
    // Replace %NAME% in the title
    String greetingText = translate("onboarding4_greeting", lang);
    greetingText = greetingText.replaceAll("%NAME%", userName);

    return Container(
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
            
            final content = Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              Column(
                children: [
                  SizedBox(
                    height: 150 * yFact,
                    child: Image.asset(
                      'assets/images/flamy/flamy_happy.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(
                    height: 15 * yFact,
                  ),
                  // Title with %NAME%
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40 * xFact),
                    child: Text(
                      greetingText,
                      style: TextStyle(
                        fontFamily: "YesevaOne",
                        fontSize: 28 * xFact,
                        color: Color(0xFFfff9ee),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    height: 15 * yFact,
                  ),
                  // Question
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40 * xFact),
                    child: Text(
                      translate("onboarding4_question", lang),
                      style: TextStyle(
                        fontFamily: "YesevaOne",
                        fontSize: 20 * xFact,
                        color: Color(0xFFfff9ee),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    height: 10 * yFact,
                  ),
                  // Subtitle
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 50 * xFact),
                    child: Text(
                      translate("onboarding4_subtitle", lang),
                      style: TextStyle(
                        fontFamily: "InterTight",
                        fontSize: 16 * xFact,
                        color: Color(0xFFb4ac9c),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30*yFact,),
              // Choices list
              Column(
                children: [
                  ...choiceList.asMap().entries.map((entry) {
                    final index = entry.key;
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
                      child: Column(
                        children: [
                          TertiaryCheckButton(
                            text: translate(entry.value, lang),
                            checked: uiState.isChecked[index],
                            onChanged: (v) {
                              ref
                                  .read(improvementStepProvider(choiceList).notifier)
                                  .toggleAt(index, v);
                            },
                          ),
                          if (index < choiceList.length - 1) SizedBox(height: 10 * yFact),
                        ],
                      ),
                    );
                  }),
                ],
              ),
              SizedBox(height: 10*yFact,),
              Padding(
                padding: EdgeInsets.only(
                  left: 20 * xFact,
                  right: 20 * xFact,
                  bottom: 30 * yFact,
                ),
                child: Opacity(
                  opacity: uiState.hasSelection ? 1.0 : 0.5,
                  child: IgnorePointer(
                    ignoring: !uiState.hasSelection,
                    child: SecondaryButton(
                      text: translate("continue", lang),
                      onTap: () => handleTap(),
                    ),
                  ),
                ),
              ),
              ],
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
    );
  }
}

