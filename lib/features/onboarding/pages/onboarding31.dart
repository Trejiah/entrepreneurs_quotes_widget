import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/data/diagnostic_phrases.dart';
import 'package:businessmindset/features/onboarding/domain/onboarding_diagnostic_domain.dart';

class OnBoarding31 extends ConsumerStatefulWidget {
  const OnBoarding31({
    super.key,
    this.forward,
  });
  final VoidCallback? forward;

  @override
  ConsumerState<OnBoarding31> createState() => _OnBoarding31State();
}

class _OnBoarding31State extends ConsumerState<OnBoarding31> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  
  Map<String, dynamic>? _savedAnswers;
  
  List<PlanCategory> _categories = [];
  
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadSavedAnswers();
  }
  
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom = _scrollController.offset >=
        _scrollController.position.maxScrollExtent - 1;
    if (atBottom && _showScrollIndicator) {
      setState(() => _showScrollIndicator = false);
    } else if (!atBottom && !_showScrollIndicator) {
      setState(() => _showScrollIndicator = true);
    }
  }

  void _checkIfScrollable() {
    if (!mounted || !_scrollController.hasClients) return;
    final scrollable = _scrollController.position.maxScrollExtent > 0;
    if (scrollable != _showScrollIndicator) {
      setState(() => _showScrollIndicator = scrollable);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    
    final situation = prefs.getString("situation");
    final improvement = prefs.getStringList("improvement") ?? [];
    // Data is saved with keys "focus" and "challenge" in onboarding14.dart
    final focus = prefs.getStringList("focus") ?? [];
    final challenge = prefs.getStringList("challenge") ?? [];
    final topics = prefs.getStringList("topics") ?? [];
    
    _savedAnswers = {
      "situation": situation,
      "improvement": improvement,
      "focus": focus,
      "challenge": challenge,
      "topics": topics,
    };
    
    if (kDebugMode) {
      debugPrint("📊 [OnBoarding31] Saved data loaded:");
      debugPrint("  situation: $situation");
      debugPrint("  improvement: $improvement");
      debugPrint("  focus: $focus");
      debugPrint("  challenge: $challenge");
      debugPrint("  topics: $topics");
    }
    
    if (mounted) {
      setState(() {});
      _calculateDiagnostic();
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfScrollable());
    }
  }

  void _calculateDiagnostic() {
    final rebuilt = rebuildOnboardingPlanCategories(_savedAnswers);
    if (rebuilt == null) return;
    _categories = rebuilt;
    if (mounted) {
      setState(() {});
    }
  }


  Future<void> _saveResults() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save totPoints and percentages
    for (var cat in _categories) {
      await prefs.setInt("plan_${cat.key}_points", cat.totPoints);
      await prefs.setDouble("plan_${cat.key}_percentage", cat.percentage);
      await prefs.setStringList("plan_${cat.key}_phrases", cat.phraseIndices.map((i) => i.toString()).toList());
    }
    
    if (kDebugMode) {
      debugPrint("💾 [OnBoarding31] Results saved");
    }
    
    if (widget.forward != null) {
      widget.forward!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final userName = ref.watch(userNameStateProvider);
    
    if (_categories.isEmpty) {
      return Container(
        color: appTheme.background,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Stack(
      children: [
        Container(
          height: double.maxFinite,
          width: double.maxFinite,
          color: appTheme.background,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3 * xFact),
              child: RawScrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                thickness: 6 * xFact,
                radius: Radius.circular(3 * xFact),
                thumbColor: appTheme.onBackground.withValues(alpha: 0.3),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 17 * xFact),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 10 * yFact),
                        Center(
                          child: Text(
                            "$userName's",
                            style: TextStyle(
                              fontFamily: "YesevaOne",
                              fontSize: 28 * xFact,
                              color: appTheme.onBackground,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            translate("plan_profile_title", lang),
                            style: TextStyle(
                              fontFamily: "YesevaOne",
                              fontSize: 28 * xFact,
                              color: appTheme.onBackground,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 30 * yFact),
                        Center(
                          child: SizedBox(
                            width: 100 * xFact,
                            child: Image.asset(
                              'assets/images/flamy/flamy_glasses.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 40 * yFact),
                        for (var cat in _categories)
                          _buildCategorySection(cat, lang),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 30 * yFact),
                            child: PrimaryButton(
                              text: translate("see_personal_plan", lang),
                              icon: Icons.arrow_right_alt,
                              iconSize: 40 * xFact,
                              onTap: _saveResults,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_showScrollIndicator)
          Positioned(
            bottom: 24 * yFact,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Opacity(
                  opacity: 0.5,
                  child: Icon(
                    Icons.arrow_drop_down_sharp,
                    size: 40 * xFact,
                    color: appTheme.onBackground,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategorySection(PlanCategory category, String lang) {
    final phrases = DiagnosticPhrases.getPhrasesForCategory(category.key, lang);
    final categoryPhrases = category.phraseIndices
        .map((index) => index < phrases.length ? phrases[index] : null)
        .where((p) => p != null)
        .cast<String>()
        .toList();
    
    // Icon image
    final iconPath = 'assets/images/${category.key}.png';
    
    return Padding(
      padding: EdgeInsets.only(bottom: 30 * yFact),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and title
          FittedBox(
            child: Row(
              children: [
                SizedBox(
                  width: 40 * xFact,
                  height: 40 * xFact,
                  child: Image.asset(
                    iconPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.circle, size: 40 * xFact, color: appTheme.onPrimButtonGold);
                    },
                  ),
                ),
                SizedBox(width: 15 * xFact),
                Text(
                  translate(category.nameKey, lang),
                  style: TextStyle(
                    fontFamily: "YesevaOne",
                    fontSize: 24 * xFact,
                    color: appTheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 15 * yFact),
          // Phrases
          for (var phrase in categoryPhrases)
            Padding(
              padding: EdgeInsets.only(bottom: 10 * yFact, left: 55 * xFact),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "• ",
                    style: TextStyle(
                      fontSize: 18 * xFact,
                      color: appTheme.onBackground,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      phrase,
                      style: TextStyle(
                        fontFamily: "InterTight",
                        fontSize: 16 * xFact,
                        color: appTheme.onBackground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 10 * yFact),
          // Separator line
          Divider(color: appTheme.onBackground.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}

