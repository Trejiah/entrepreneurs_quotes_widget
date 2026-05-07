import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/widgets/app_button.dart';

class OnBoarding25 extends ConsumerStatefulWidget {
  const OnBoarding25({
    super.key,
    required this.backIcon,
    required this.title,
    required this.subTitle,
    required this.progress,
    this.backward,
    this.forward,
  });
  final bool backIcon;
  final String title;
  final String subTitle;
  final double progress;
  final VoidCallback? backward;
  final VoidCallback? forward;

  @override
  ConsumerState<OnBoarding25> createState() => _OnBoarding25State();
}

class _OnBoarding25State extends ConsumerState<OnBoarding25> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  // Slider values: 0 = "Not at all", 1 = "A little", 2 = "Neither", 3 = "A lot", 4 = "Love it"
  final List<int?> _selectedToneValues = [null, null]; // null = non sélectionné, 0-4 = valeur sélectionnée

  // Tone list: only NO MERCY and AFFIRMATION
  final List<Map<String, String>> _tones = [
    {
      'word': 'NO MERCY',
      'quote': 'You don\'t need more time — you need fewer excuses.',
    },
    {
      'word': 'AFFIRMATION',
      'quote': 'I am capable and consistent.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedTones();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Convert a slider position (0-4) to a percentage
  int _sliderPositionToPercentage(int position) {
    const percentages = [-75, -30, 0, 30, 50];
    return percentages[position.clamp(0, 4)];
  }

  // Convert a percentage to a slider position (0-4)
  int? _percentageToSliderPosition(int? percentage) {
    if (percentage == null) return null;
    const percentages = [-75, -30, 0, 30, 50];
    final index = percentages.indexOf(percentage);
    return index >= 0 ? index : null;
  }

  void _loadSavedTones() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      // Load saved values for each tone (format: "tone_value_NO MERCY" = percentage)
      final noMercyPercentage = prefs.getInt("tone_value_NO MERCY");
      final affirmationPercentage = prefs.getInt("tone_value_AFFIRMATION");

      setState(() {
        _selectedToneValues[0] = _percentageToSliderPosition(noMercyPercentage);
        _selectedToneValues[1] = _percentageToSliderPosition(affirmationPercentage);
      });
    });
  }


  void _updateSliderValue(double value, int index) {
    // Convert the slider value (0.0-4.0) to int (0-4)
    final intValue = value.round().clamp(0, 4);
    setState(() {
      _selectedToneValues[index] = intValue;
    });
  }

  void _handleSliderChange(double value, int index) {
    // Update the value without saving (for the drag)
    _updateSliderValue(value, index);
  }

  Future<void> _handleSave() async {
    // Save the current tone
    final prefs = await SharedPreferences.getInstance();
    final toneWord = _tones[_currentIndex]['word']!;
    final sliderPosition = _selectedToneValues[_currentIndex];
    if (sliderPosition != null) {
      final percentage = _sliderPositionToPercentage(sliderPosition);
      await prefs.setInt("tone_value_$toneWord", percentage);
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("Tone $toneWord saved with position: $sliderPosition -> percentage: $percentage");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
    }
    
    // Move to the next or trigger forward if it's the last
    if (_currentIndex < _tones.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // This is the last tone, trigger forward
      if (widget.forward != null) {
        widget.forward!();
      }
    }
  }

  Widget _buildSlider(int index) {
    final lang = ref.watch(languageProvider);
    final currentValue = _selectedToneValues[index] ?? 2; // Valeur par défaut au milieu (2)
    final sliderWidth = MediaQuery.of(context).size.width - 80 * xFact;
    final dotSize = 14.0 * xFact;
    final goldDotSize = 22.0 * xFact;
    final totalDotsWidth = 4 * dotSize + goldDotSize;
    final availableWidth = sliderWidth - totalDotsWidth-0-2*xFact;
    final spacing = (availableWidth / 4) - 5*xFact;
    final sliderKey = GlobalKey();
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);

    return Column(
      children: [
        // Slider with dots
        Padding(
          padding: EdgeInsets.only(left: 20.0,right: 20*xFact),
          child: GestureDetector(
            onTapDown: (details) {
              if (sliderKey.currentContext == null) return;
              final RenderBox box = sliderKey.currentContext!.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              final newValue = ((localPosition.dx - dotSize / 2) / (dotSize + spacing))
                  .round()
                  .clamp(0, 4);
              // For a direct tap, update without saving
              _handleSliderChange(newValue.toDouble(), index);
            },
            onPanUpdate: (details) {
              if (sliderKey.currentContext == null) return;
              final RenderBox box = sliderKey.currentContext!.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              final newValue = ((localPosition.dx - dotSize / 2) / (dotSize + spacing))
                  .round()
                  .clamp(0, 4);
              // During drag, update without saving
              _handleSliderChange(newValue.toDouble(), index);
            },
            onPanEnd: (details) {
              // On release, we do not auto-save in onboarding
              // Saving is done via the Save button
            },
            child: Container(
              key: sliderKey,
              width: sliderWidth-20*xFact,
              decoration: BoxDecoration(color: Colors.transparent),
              padding: EdgeInsets.symmetric(horizontal: 0*xFact),
              height: 45 * yFact,
              child: Stack(
                children: [
                  // Ligne de fond
                  Positioned(
                    top: (goldDotSize / 2) - 1+12.5*yFact,
                    left: dotSize / 2 + dotSize/4,
                    right: dotSize / 2 + dotSize/4+7.5*xFact,
                    child: Container(
                      height: 2,
                      color: appTheme.textField,
                    ),
                  ),
                  // Points gris
                  ...List.generate(5, (i) {
                    return Positioned(
                      left: i * (dotSize + spacing)+ dotSize/4,
                      top: (goldDotSize / 2) - (dotSize / 2)+12.5*yFact,
                      child: Container(
                        width: dotSize,
                        height: dotSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: appTheme.textField,
                        ),
                      ),
                    );
                  }),
                  // Gold dot (position indicator)
                  Positioned(
                    left: currentValue * (dotSize + spacing) ,
                    top: (goldDotSize / 2) - (goldDotSize / 2)+12.5*yFact,
                    child: Container(
                      width: goldDotSize,
                      height: goldDotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: appTheme.onPrimButtonGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if(textScale > 1.3) SizedBox(height: 0 * yFact),
        // Labels under the dots
        SizedBox(
          height:  70*yFact,
          width: sliderWidth-5*xFact,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 45*xFact,
                child: Text(
                  translate("tone_slider_dislike", lang),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "InterTight",
                    fontSize: 12 * xFact,
                    color: appTheme.onBackground,
                  ),
                ),
              ),
              SizedBox(
                width: 45*xFact,
                child: Text(
                  translate("tone_slider_not_my_vibe", lang),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "InterTight",
                    fontSize: 12 * xFact,
                    color: appTheme.onBackground,
                  ),
                ),
              ),
              SizedBox(
                width: 45*xFact,
                child: Text(
                  translate("tone_slider_ok", lang),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "InterTight",
                    fontSize: 12 * xFact,
                    color: appTheme.onBackground,
                  ),
                ),
              ),
              SizedBox(
                width: 45*xFact,
                child: Text(
                  translate("tone_slider_like", lang),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "InterTight",
                    fontSize: 12 * xFact,
                    color: appTheme.onBackground,
                  ),
                ),
              ),
              SizedBox(
                width: 45 *xFact,
                child: Text(
                  translate("tone_slider_love", lang),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "InterTight",
                    fontSize: 12 * xFact,
                    color: appTheme.onBackground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      color: appTheme.background,
      child: SafeArea(
        bottom: false,
        child: Builder(
          builder: (context) {
            // Enable scroll only if text scale > 1.2
            final textScale = MediaQuery.of(context).textScaler.scale(1.0);
            final shouldEnableScroll = textScale > 1.2;
            
            final content = Stack(
              children: [
                if (widget.backIcon)
                Positioned(
                  top: 15 * yFact,
                  left: 20 * xFact,
                  child: GestureDetector(
                    onTap: widget.backward,
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: appTheme.onBackground,
                    ),
                  ),
                ),
                // Progress bar at top center
                Positioned(
                  top: 9,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 55 * xFact, vertical: 15 * yFact),
                    child: Container(
                      height: 4 * yFact,
                      decoration: BoxDecoration(
                        color: Color(0xFFb4ac9c).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2 * yFact),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: widget.progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: appTheme.onPrimButtonGold,
                            borderRadius: BorderRadius.circular(2 * yFact),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        // Contenu principal
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: 40 * yFact),
                              // Image flamy_glasses
                              SizedBox(
                                height: 100 * yFact,
                                child: Image.asset(
                                  'assets/images/flamy/flamy_nerd.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              SizedBox(height: 0 * yFact),
                              // Titre
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 50 * xFact),
                                child: Text(
                                  translate(widget.title, lang),
                                  style: TextStyle(
                                    fontFamily: "YesevaOne",
                                    fontSize: 24 * xFact,
                                    color: Color(0xFFfff9ee),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: 10 * yFact),
                              // Subtitle
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40 * xFact),
                                child: Text(
                                  translate(widget.subTitle, lang),
                                  style: TextStyle(
                                    fontFamily: "InterTight",
                                    fontSize: 16 * xFact,
                                    color: appTheme.onBackgroundSub,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              // Tone navigation area
                              SizedBox(
                                height: (textScale > 1.3) ? 500*yFact : 420 * yFact,
                                child: PageView.builder(
                                  physics: NeverScrollableScrollPhysics(), // Désactiver le swipe
                                  controller: _pageController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentIndex = index;
                                    });
                                  },
                                  itemCount: _tones.length,
                                  itemBuilder: (context, index) {
                                    final tone = _tones[index];
                                    return Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Tone word
                                          Text(
                                            translate(tone['word']!, lang),
                                            style: TextStyle(
                                              fontFamily: "InterTight",
                                              fontSize: 28 * xFact,
                                              fontWeight: FontWeight.w600,
                                              color: appTheme.onBackground,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 20 * yFact),
                                          // Gray frame with quote
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 40 * xFact),
                                            child: Container(
                                              padding: EdgeInsets.all(20 * xFact),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF504b41).withAlpha(90),
                                                borderRadius: BorderRadius.circular(12 * xFact),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  translate("tone_quote_${tone['word']!.toLowerCase()}", lang),
                                                  style: TextStyle(
                                                    fontFamily: "InterTight",
                                                    fontSize: 18 * xFact,
                                                    fontStyle: FontStyle.italic,
                                                    color: Color(0xFFfff9ee),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 50 * yFact),
                                          // 5-position slider
                                          _buildSlider(index),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )

                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 0,
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left : 30*xFact,right : 30*xFact,bottom: 30*yFact),
                          child: SecondaryButton(
                            text: translate("save", lang),
                            onTap: () => _handleSave(),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            );
            
            // Return with or without scroll depending on textScale
            if (shouldEnableScroll) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: content,
                ),
              );
            } else {
              return content;
            }
          },
        ),
      ),
    );
  }
}
