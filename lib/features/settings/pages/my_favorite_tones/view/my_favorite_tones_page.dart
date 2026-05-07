import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/services/save_cloud.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyFavoriteTones extends ConsumerStatefulWidget {
  const MyFavoriteTones({super.key});

  @override
  ConsumerState<MyFavoriteTones> createState() => _MyFavoriteTonesState();
}

class _MyFavoriteTonesState extends ConsumerState<MyFavoriteTones> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  int _currentIndex = 0;
  final List<int?> _selectedToneValues = [null, null];

  final List<Map<String, String>> _tones = [
    {
      'word': 'NO MERCY',
      'quote': 'You don\'t need more time - you need fewer excuses.',
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

  int _sliderPositionToPercentage(int position) {
    const percentages = [-75, -30, 0, 30, 50];
    return percentages[position.clamp(0, 4)];
  }

  int? _percentageToSliderPosition(int? percentage) {
    if (percentage == null) return null;
    const percentages = [-75, -30, 0, 30, 50];
    final index = percentages.indexOf(percentage);
    return index >= 0 ? index : null;
  }

  void _loadSavedTones() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final noMercyPercentage = prefs.getInt('tone_value_NO MERCY');
      final affirmationPercentage = prefs.getInt('tone_value_AFFIRMATION');

      if (kDebugMode) {
        final premium = ref.read(premiumProvider);
        debugPrint('📋 [MyFavoriteTones] Loading premium: $premium');
      }

      setState(() {
        _selectedToneValues[0] = _percentageToSliderPosition(noMercyPercentage);
        _selectedToneValues[1] =
            _percentageToSliderPosition(affirmationPercentage);
      });
    });
  }

  void _previousTone() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _nextTone() {
    if (_currentIndex < _tones.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _updateSliderValue(double value, int index) {
    final intValue = value.round().clamp(0, 4);
    setState(() {
      _selectedToneValues[index] = intValue;
    });
  }

  void _handleSliderChange(double value, int index) {
    _updateSliderValue(value, index);
  }

  void _handleSliderEnd(double value, int index) {
    _updateSliderValue(value, index);
    _saveTones();
  }

  Future<void> _saveTones() async {
    final prefs = await SharedPreferences.getInstance();

    final savedTones = <String, int>{};
    for (int i = 0; i < _tones.length; i++) {
      final toneWord = _tones[i]['word']!;
      final sliderPosition = _selectedToneValues[i];
      if (sliderPosition != null) {
        final percentage = _sliderPositionToPercentage(sliderPosition);
        await prefs.setInt('tone_value_$toneWord', percentage);
        savedTones[toneWord] = percentage;
        saveOneToCloud('tones', 'tone_value_$toneWord', percentage);
      }
    }

    if (kDebugMode && savedTones.isNotEmpty) {
      final premium = ref.read(premiumProvider);
      debugPrint('📋 [MyFavoriteTones] Sauvegarde premium: $premium');
    }
  }

  Future<void> _handleBackNavigation() async {
    await _saveTones();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Widget _buildSlider(int index, {bool autoSave = true}) {
    final lang = ref.watch(languageProvider);
    final currentValue = _selectedToneValues[index] ?? 2;
    final sliderWidth = MediaQuery.of(context).size.width - 80 * xFact;
    final dotSize = 14.0 * xFact;
    final goldDotSize = 22.0 * xFact;
    final totalDotsWidth = 4 * dotSize + goldDotSize;
    final availableWidth = sliderWidth - totalDotsWidth - 2 * xFact;
    final spacing = (availableWidth / 4) - 5 * xFact;
    final sliderKey = GlobalKey();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20.0, right: 20 * xFact),
          child: GestureDetector(
            onTapDown: (details) {
              if (sliderKey.currentContext == null) return;
              final box =
                  sliderKey.currentContext!.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              final newValue = ((localPosition.dx - dotSize / 2) /
                      (dotSize + spacing))
                  .round()
                  .clamp(0, 4);
              if (autoSave) {
                _handleSliderEnd(newValue.toDouble(), index);
              } else {
                _handleSliderChange(newValue.toDouble(), index);
              }
            },
            onPanUpdate: (details) {
              if (sliderKey.currentContext == null) return;
              final box =
                  sliderKey.currentContext!.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              final newValue = ((localPosition.dx - dotSize / 2) /
                      (dotSize + spacing))
                  .round()
                  .clamp(0, 4);
              _handleSliderChange(newValue.toDouble(), index);
            },
            onPanEnd: (details) {
              if (autoSave) _saveTones();
            },
            child: Container(
              key: sliderKey,
              width: sliderWidth - 20 * xFact,
              color: Colors.transparent,
              height: 45 * yFact,
              child: Stack(
                children: [
                  Positioned(
                    top: (goldDotSize / 2) - 1 + 12.5 * yFact,
                    left: dotSize / 2 + dotSize / 4,
                    right: dotSize / 2 + dotSize / 4 + 7.5 * xFact,
                    child: Container(height: 2, color: appTheme.textField),
                  ),
                  ...List.generate(5, (i) {
                    return Positioned(
                      left: i * (dotSize + spacing) + dotSize / 4,
                      top: (goldDotSize / 2) - (dotSize / 2) + 12.5 * yFact,
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
                  Positioned(
                    left: currentValue * (dotSize + spacing),
                    top: (goldDotSize / 2) - (goldDotSize / 2) + 12.5 * yFact,
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
        SizedBox(
          width: sliderWidth - 5 * xFact,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final key in [
                'tone_slider_dislike',
                'tone_slider_not_my_vibe',
                'tone_slider_ok',
                'tone_slider_like',
                'tone_slider_love'
              ])
                SizedBox(
                  width: 45 * xFact,
                  child: Text(
                    translate(key, lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'InterTight',
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

  Widget _buildContent(BuildContext context, String lang) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 400 * yFact,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity > 0 && _currentIndex > 0) {
                    _previousTone();
                  } else if (velocity < 0 && _currentIndex < _tones.length - 1) {
                    _nextTone();
                  }
                },
                child: Column(
                  children: [
                    Text(
                      translate(_tones[_currentIndex]['word']!, lang),
                      style: TextStyle(
                        fontFamily: 'InterTight',
                        fontSize: 28 * xFact,
                        fontWeight: FontWeight.w600,
                        color: appTheme.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20 * yFact),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (_currentIndex > 0) ...[
                            GestureDetector(
                              onTap: _previousTone,
                              child: Icon(
                                Icons.arrow_back_ios,
                                color: appTheme.onBackground,
                                size: 24 * xFact,
                              ),
                            ),
                            SizedBox(width: 15 * xFact),
                          ] else
                            SizedBox(width: 24 * xFact + 15 * xFact),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(20 * xFact),
                              height: MediaQuery.of(context).textScaler.scale(1.0) > 1.3
                                  ? 140 * yFact
                                  : 130 * yFact,
                              decoration: BoxDecoration(
                                color: const Color(0xFF504b41).withAlpha(90),
                                borderRadius: BorderRadius.circular(12 * xFact),
                              ),
                              child: Center(
                                child: Text(
                                  translate(
                                    'tone_quote_${_tones[_currentIndex]['word']!.toLowerCase()}',
                                    lang,
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'InterTight',
                                    fontSize: 18 * xFact,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFFfff9ee),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          if (_currentIndex < _tones.length - 1) ...[
                            SizedBox(width: 15 * xFact),
                            GestureDetector(
                              onTap: _nextTone,
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: appTheme.onBackground,
                                size: 24 * xFact,
                              ),
                            ),
                          ] else
                            SizedBox(width: 24 * xFact + 15 * xFact),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50 * yFact),
              _buildSlider(_currentIndex, autoSave: true),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await _handleBackNavigation();
        }
      },
      child: Scaffold(
        body: Container(
          height: double.maxFinite,
          width: double.maxFinite,
          color: appTheme.background,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10 * xFact),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      SizedBox(width: 10 * xFact),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: appTheme.onBackground,
                          size: 30 * xFact,
                        ),
                      ),
                      SizedBox(width: 5 * xFact),
                      Text(
                        translate('my_favorite_tones', lang),
                        style: TextStyle(
                          fontFamily: 'YesevaOne',
                          color: appTheme.onBackground,
                          fontSize: 35 * xFact,
                        ),
                      ),
                    ],
                  ),
                  _buildContent(context, lang),
                  SizedBox(height: 20 * yFact),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

