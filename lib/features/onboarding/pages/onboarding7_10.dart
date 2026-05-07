import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/models/onboarding_quotes_model.dart';
import 'package:businessmindset/services/mindset_points_service.dart';
import 'package:businessmindset/services/mixpanel_service.dart';
import 'package:businessmindset/features/mindset_points/view/mindset_points_page.dart';
import 'package:businessmindset/utils/favorite_management.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnBoarding710 extends ConsumerStatefulWidget {
  const OnBoarding710({
    super.key,
    this.forward,
  });
  final VoidCallback? forward;

  @override
  ConsumerState<OnBoarding710> createState() => _OnBoarding710State();
}

class _OnBoarding710State extends ConsumerState<OnBoarding710> with TickerProviderStateMixin {
  static const String _kLikeCount = 'onboarding710_like_count';
  static const String _kLikesRewardApplied = 'onboarding710_likes_reward_applied';

  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  
  // Swipe
  static const double kMinVel = 650; // inertie (px/s)
  final List<String> _history = [];
  final List<Map<String, dynamic>> _historyData = [];
  int current = 0;
  double _offsetY = 0.0;
  late AnimationController _animCtrl;
  Animation<double>? _anim;
  bool _animating = false;
  
  // Onboarding quotes: the first 16 in order, then the rest randomly
  static const int _first16Count = 16;
  /// After the intro: 30 "cards" per cycle (29 quotes + 1 closing message), then loops back to the 1st quote.
  static const int _kMaxQuotesPerCycle = 30;
  int _first16Index = 0; // Index pour suivre les 16 premières citations
  
  // Likes: `likedCount` is a persisted int (0–3), independent of per-card favorites/hearts
  int likedCount = 0;
  List<bool> likedQuotes = []; // État du cœur par carte (session courante)
  
  // Arrow animation
  late AnimationController _arrowsAnimCtrl;
  
  // Reward mask
  bool _showRewardMask = false;
  late AnimationController _rewardMaskAnimCtrl;
  late AnimationController _plus3AnimCtrl;
  bool _showPlus3 = false; // Contrôle la visibilité du "+3"
  bool _showTapHere = false;
  late AnimationController _tapHereAnimCtrl;
  
  // Track the first swipe
  // Track the first drag (to stop the text bounce animation)
  bool _hasDraggedOnce = false;
  // Text bounce animation (rises then comes back with bounce) while no drag
  late AnimationController _textBounceAnimCtrl;
  late Animation<double> _textBounceOffset;
  
  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 240))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
          _animating = false;
        }
      });
    
    _arrowsAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500), // 500ms animation + 2000ms pause
    )..repeat();
    
    _rewardMaskAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _plus3AnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _tapHereAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    // Text animation: slight rise then bounces back down
    _textBounceAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _textBounceOffset = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -14.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -14.0, end: 0.0).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 65,
      ),
    ]).animate(_textBounceAnimCtrl);
    _textBounceAnimCtrl.repeat();
    
    _loadFirstQuote();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _arrowsAnimCtrl.dispose();
    _rewardMaskAnimCtrl.dispose();
    _plus3AnimCtrl.dispose();
    _tapHereAnimCtrl.dispose();
    _textBounceAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFirstQuote() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      likedCount = (prefs.getInt(_kLikeCount) ?? 0).clamp(0, 3);
    } catch (_) {
      likedCount = 0;
    }

    if (!mounted) return;

    final lang = ref.read(languageProvider);
    // Very first "quote": translated text "Swipe up to see quotes"
    final first = translate("onboarding710_first_quote", lang);
    _history
      ..clear()
      ..add(first);
    _historyData
      ..clear()
      ..add({
        "category": "onboarding",
        "text": first,
        "signature": null,
        "bookTitle": null,
        "isIntroMessage": true,
      });
    likedQuotes = [false];
    current = 0;
    _first16Index = 0; // Aucune vraie citation affichée encore ; la première sera au premier swipe
    setState(() {});

    if (likedCount >= 3) {
      _showRewardMask = true;
      _rewardMaskAnimCtrl.value = 1.0;
      await _applyRewardPointsIfNeeded();
      if (mounted) setState(() {});
    }
  }

  Future<void> _persistLikeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLikeCount, likedCount.clamp(0, 3));
    } catch (_) {}
  }

  /// The 3 Mindset Points are credited only once (avoids duplication after app kill).
  Future<void> _applyRewardPointsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kLikesRewardApplied) ?? false) return;

    for (int i = 0; i < 3; i++) {
      await MindsetPointsService.instance.incrementLike();
    }
    await prefs.setBool(_kLikesRewardApplied, true);

    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _showPlus3 = true;
        });
        _plus3AnimCtrl.forward();
      }
    });
  }

  Future<void> _clearOnboarding710Persistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kLikeCount);
      await prefs.remove(_kLikesRewardApplied);
    } catch (_) {}
  }

  /// Only the intro (isIntroMessage) and the closing message (isClosingMessage) are not likable.
  bool _canLikeQuoteAt(int index) {
    if (index < 0 || index >= _history.length) return false;
    if (index < _historyData.length) {
      final data = _historyData[index];
      if (data['isIntroMessage'] == true) return false;
      if (data['isClosingMessage'] == true) return false;
    }
    return true;
  }

  Map<String, dynamic> _getNextOnboardingQuote(String lang) {
    final quotes = onboardingQuotes["onboarding"] as List;
    
    // If we're within the first 16, show them in order
    if (_first16Index < _first16Count && _first16Index < quotes.length) {
      final quote = quotes[_first16Index] as Map<String, dynamic>;
      final text = quote[lang] ?? quote["en"] ?? "";
      if (text.isNotEmpty) {
        return {
          "category": "onboarding",
          "text": text,
          "signature": quote["signature"] as String?,
          "bookTitle": quote["bookTitle"]?[lang] ?? quote["bookTitle"]?["en"],
        };
      }
    }
    
    // Otherwise, pick a random quote from the others (after the first 16)
    final random = Random();
    final remainingQuotes = quotes.sublist(_first16Count);
    if (remainingQuotes.isEmpty) {
      // If we have fewer than 16 quotes, pick randomly from all
      final randomQuote = quotes[random.nextInt(quotes.length)] as Map<String, dynamic>;
      final text = randomQuote[lang] ?? randomQuote["en"] ?? "";
      return {
        "category": "onboarding",
        "text": text,
        "signature": randomQuote["signature"] as String?,
        "bookTitle": randomQuote["bookTitle"]?[lang] ?? randomQuote["bookTitle"]?["en"],
      };
    }
    
    final randomQuote = remainingQuotes[random.nextInt(remainingQuotes.length)] as Map<String, dynamic>;
    final text = randomQuote[lang] ?? randomQuote["en"] ?? "";
    return {
      "category": "onboarding",
      "text": text,
      "signature": randomQuote["signature"] as String?,
      "bookTitle": randomQuote["bookTitle"]?[lang] ?? randomQuote["bookTitle"]?["en"],
    };
  }


  Map<String, dynamic> _findQuoteDataByText(String text, String lang) {
    // Search only within onboarding quotes
    final quotes = onboardingQuotes["onboarding"] as List;
    for (final raw in quotes) {
      if (raw is! Map) continue;
      final Map<String, dynamic> q = Map<String, dynamic>.from(raw);
      final quoteText = q[lang] ?? q["en"] ?? "";
      if (quoteText == text) {
        return {
          "category": "onboarding",
          "text": text,
          "signature": q["signature"] as String?,
          "bookTitle": q["bookTitle"]?[lang] ?? q["bookTitle"]?["en"],
        };
      }
    }
    return {"category": "onboarding", "text": text};
  }

  List<String> _getAllQuotesForLang(String lang) {
    final List<String> out = [];
    // Use only onboarding quotes
    final quotes = onboardingQuotes["onboarding"] as List;
    for (final raw in quotes) {
      if (raw is! Map) continue;
      final Map<String, dynamic> q = Map<String, dynamic>.from(raw);
      final txt = q[lang] ?? q["en"] ?? "";
      if (txt.isNotEmpty) out.add(txt);
    }
    return out;
  }

  void _appendUniqueQuote(String lang) {
    final n = _history.length - 1; // nombre de cartes après l’intro, avant cet ajout

    // 30th card of the cycle: message (then on the next swipe we restart from the 1st quote)
    if (n % _kMaxQuotesPerCycle == _kMaxQuotesPerCycle - 1) {
      final specialText = translate("onboarding710_thousands_more", lang);
      _history.add(specialText);
      _historyData.add({
        "category": "onboarding",
        "text": specialText,
        "signature": null,
        "bookTitle": null,
        "isClosingMessage": true,
      });
      likedQuotes.add(false);
      return;
    }

    // Right after the closing message: restart on the first quote of the catalog
    if (n > 0 && n % _kMaxQuotesPerCycle == 0) {
      _first16Index = 0;
    }

    // If we haven't shown the first 16 yet, continue in order
    if (_first16Index < _first16Count) {
      final quoteData = _getNextOnboardingQuote(lang);
      final newText = quoteData["text"]!;
      _history.add(newText);
      _historyData.add(quoteData);
      likedQuotes.add(false);
      _first16Index++;
      return;
    }
    
    // Otherwise, pick a random quote from the others
    final all = _getAllQuotesForLang(lang);
    if (all.isEmpty) return;

    // Exclude the first 16 from the random list
    final quotes = onboardingQuotes["onboarding"] as List;
    final first16Texts = quotes.take(_first16Count).map((q) {
      final Map<String, dynamic> quote = Map<String, dynamic>.from(q as Map);
      return quote[lang] ?? quote["en"] ?? "";
    }).where((t) => t.isNotEmpty).toList();
    
    final remainingQuotes = all.where((q) => !first16Texts.contains(q)).toList();
    final unused = remainingQuotes.where((q) => !_history.contains(q)).toList();

    if (unused.isNotEmpty) {
      unused.shuffle();
      final newText = unused.first;
      _history.add(newText);
      final quoteData = _findQuoteDataByText(newText, lang);
      _historyData.add(quoteData);
      likedQuotes.add(false);
    } else {
      // If all remaining quotes have been seen, pick randomly among them
      final pool = remainingQuotes.isNotEmpty ? remainingQuotes : all;
      pool.shuffle();
      final newText = pool.first;
      _history.add(newText);
      final quoteData = _findQuoteDataByText(newText, lang);
      _historyData.add(quoteData);
      likedQuotes.add(false);
    }
  }

  void _goNext() {
    if (likedCount >= 3) return; // Bloqué si 3 likes
    
    final lang = ref.read(languageProvider);
    bool shouldIncrementQuote = false;
    setState(() {
      final atEnd = (current == _history.length - 1);
      final previousHistoryLength = _history.length;
      if (atEnd) {
        _appendUniqueQuote(lang);
        if (_history.length > previousHistoryLength) {
          shouldIncrementQuote = true;
        }
      }
      current = (current + 1).clamp(0, _history.length - 1);
    });
    if (shouldIncrementQuote) {
      final lastData = _historyData.isNotEmpty ? _historyData.last : null;
      if (lastData?['isClosingMessage'] != true) {
        MindsetPointsService.instance.incrementQuote();
      }
    }
  }

  void _goPrev() {
    if (current == 0) return;
    setState(() {
      current = (current - 1).clamp(0, _history.length - 1);
    });
  }

  void _toggleLike() {
    if (!_canLikeQuoteAt(current)) return;
    if (likedCount >= 3 && !likedQuotes[current]) return; // Bloqué si 3 likes et on essaie de like
    
    setState(() {
      final wasLiked = likedQuotes[current];
      likedQuotes[current] = !wasLiked;
      
      if (wasLiked) {
        likedCount--;
        MixpanelService.instance.track('[onboarding] page 4 unlike');
      } else {
        likedCount++;
        MixpanelService.instance.track('[onboarding] page 4 like');
        // Save the quote to favorites when it's liked
        _saveCurrentQuoteToFavorites();
      }
      
      // If we reach 3 likes, show the reward mask
      if (likedCount >= 3 && !_showRewardMask) {
        _showRewardMask = true;
        MixpanelService.instance.track("[onboarding4] vue page 4b.");
        _rewardMaskAnimCtrl.forward().then((_) async {
          await _applyRewardPointsIfNeeded();
        });
      }
    });
    _persistLikeCount();
  }

  /// Force all open values to 1 and save them
  Future<void> _forceOpenTo1() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Force all open values to 1
      await prefs.setInt('openAllPoints', 1);
      await prefs.setInt('openTodayPoints', 1);
      await prefs.setInt('openWeekPoints', 1);
      
      // Save to Firebase if the user is signed in
     // await saveOpenPointsToCloud();
      
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("📋 [OnBoarding710] Open values forced to 1");
        debugPrint("   - openAllPoints: 1");
        debugPrint("   - openTodayPoints: 1");
        debugPrint("   - openWeekPoints: 1");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("❌ [OnBoarding710] Error while forcing open to 1");
        debugPrint("   Message: $e");
        debugPrint("   Stack: $stackTrace");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
    }
  }

  Future<void> _saveCurrentQuoteToFavorites() async {
    if (current < 0 || current >= _history.length || current >= _historyData.length) {
      return;
    }
    
    final lang = ref.read(languageProvider);
    final currentQuoteText = _history[current];
    final quoteData = _historyData[current];
    if (quoteData['isClosingMessage'] == true) return;
    if (quoteData['isIntroMessage'] == true) return;
    
    // Load existing favorites
    final existingFavorites = await loadAllFavorite();
    
    // Check whether the quote isn't already in favorites
    if (existingFavorites.any((fav) => fav.quote == currentQuoteText)) {
      return; // Déjà en favoris
    }
    
    // Create a DayQuote with metadata
    final date = DateTime.now();
    final monthName = monthNames[lang]?[date.month - 1] ?? monthNames["en"]![date.month - 1];
    
    final favoriteQuote = DayQuote(
      day: date.day,
      month: monthName,
      year: date.year,
      quote: currentQuoteText,
      category: quoteData["category"] as String?,
      signature: quoteData["signature"] as String?,
      bookTitle: quoteData["bookTitle"] as String?,
      url: quoteData["url"] as String?,
    );
    
    // Add to favorites and save
    existingFavorites.add(favoriteQuote);
    await saveAllFavorite(existingFavorites);
    
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📋 [OnBoarding710] Quote added to favorites");
      debugPrint("   - Citation: $currentQuoteText");
      debugPrint("   - Category: ${quoteData["category"] ?? "N/A"}");
      debugPrint("   - Signature: ${quoteData["signature"] ?? "N/A"}");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }
  

  void _animateOffset({
    required double from,
    required double to,
    int? ms,
    Curve curve = Curves.easeOutCubic,
    VoidCallback? onEnd,
  }) {
    _animating = true;
    _animCtrl.duration = Duration(milliseconds: ms ?? max(160, (240 * ((to - from).abs() / 400).clamp(0.5, 1.4)).toInt()));
    final tween = Tween<double>(begin: from, end: to).chain(CurveTween(curve: curve));
    _anim = tween.animate(_animCtrl);
    _animCtrl.forward(from: 0).whenCompleteOrCancel(() {
      _offsetY = to;
      _anim = null;
      _animating = false;
      if (onEnd != null) onEnd();
    });
  }

  double get _driveOffsetY => (_anim == null) ? _offsetY : _anim!.value;

  void _onDragEnd(BuildContext context, DragEndDetails details) {
    if (_animating || likedCount >= 3) return; // Bloqué si 3 likes

    final screenH = MediaQuery.of(context).size.height;
    final double kMinDy = (screenH * 0.18).clamp(80.0, 160.0);

    final vy = details.velocity.pixelsPerSecond.dy;
    final bool flingUp = vy <= -kMinVel;
    final bool flingDown = vy >= kMinVel;
    final bool farUp = _offsetY <= -kMinDy;
    final bool farDown = _offsetY >= kMinDy;

    int dir = 0; // -1 = up(next), +1 = down(prev)
    if (flingUp || farUp) dir = -1;
    if (flingDown || farDown) dir = 1;

    if (dir == 0) {
      _animateOffset(from: _offsetY, to: 0);
      return;
    }

    if (dir == 1 && current == 0) {
      _animateOffset(from: _offsetY, to: 0);
      return;
    }

    final double outTarget = (dir == -1) ? -screenH : screenH;

    MixpanelService.instance.track('[onboarding] page 4 swipe');

    _animateOffset(
      from: _offsetY,
      to: outTarget,
      ms: 170,
      onEnd: () {
        if (dir == -1) {
          _goNext();
        } else {
          _goPrev();
        }

        _offsetY = -outTarget;
        setState(() {});

        _animateOffset(from: _offsetY, to: 0, ms: 220);
      },
    );
  }

  /// Compute timeMs (0..500) for the 3-arrow sequence from the [0,1] cycle.
  double _arrowOpacityForIndex(int index, double timeMs) {
    final reversedIndex = 2 - index;
    double startMs, fadeInEndMs, fadeOutStartMs, endMs;
    switch (reversedIndex) {
      case 0:
        startMs = 0.0; fadeInEndMs = 125.0; fadeOutStartMs = 125.0; endMs = 250.0;
        break;
      case 1:
        startMs = 125.0; fadeInEndMs = 250.0; fadeOutStartMs = 250.0; endMs = 375.0;
        break;
      case 2:
        startMs = 250.0; fadeInEndMs = 375.0; fadeOutStartMs = 375.0; endMs = 500.0;
        break;
      default:
        startMs = 0.0; fadeInEndMs = 0.0; fadeOutStartMs = 0.0; endMs = 0.0;
    }
    double opacity = 0.0;
    if (timeMs >= startMs && timeMs < fadeInEndMs) {
      opacity = (timeMs - startMs) / (fadeInEndMs - startMs);
    } else if (timeMs >= fadeInEndMs && timeMs < fadeOutStartMs) {
      opacity = 1.0;
    } else if (timeMs >= fadeOutStartMs && timeMs < endMs) {
      opacity = 1.0 - (timeMs - fadeOutStartMs) / (endMs - fadeOutStartMs);
    }
    return opacity.clamp(0.0, 1.0);
  }

  Widget _buildArrowsAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_arrowsAnimCtrl, _textBounceAnimCtrl]),
      builder: (context, child) {
        double timeMs; // 0..500 pour la séquence des 3 flèches
        if (_hasDraggedOnce) {
          // After first drag: independent cycle (500ms anim, then pause)
          final cycleValue = _arrowsAnimCtrl.value % 1.0;
          if (cycleValue >= 0.2) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (_) => Opacity(
                opacity: 0.0,
                child: SizedBox(width: 50 * xFact, child: Image.asset("assets/images/up_arrow.png", color: appTheme.onBackground)),
              )),
            );
          }
          timeMs = cycleValue * 2500.0;
        } else {
          // Synced with the quote's rise: arrows during the first 35% (rise)
          final v = _textBounceAnimCtrl.value;
          if (v > 0.35) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (_) => Opacity(
                opacity: 0.0,
                child: SizedBox(width: 50 * xFact, child: Image.asset("assets/images/up_arrow.png", color: appTheme.onBackground)),
              )),
            );
          }
          // 0..0.35 mapped to 0..500 ms
          timeMs = (v / 0.35) * 500.0;
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final opacity = _arrowOpacityForIndex(index, timeMs);
            return Opacity(
              opacity: opacity,
              child: SizedBox(
                width: 50 * xFact,
                child: Image.asset("assets/images/up_arrow.png", color: appTheme.onBackground),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    if (_history.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQuote = _history[current];
    final canLikeCurrent = _canLikeQuoteAt(current);
    final isLiked = canLikeCurrent && likedQuotes[current];

    return Scaffold(
      body: Container(
        height: double.maxFinite,
        width: double.maxFinite,
        color: appTheme.background,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Background with gesture
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: (_) {
                    if (!_hasDraggedOnce) {
                      _hasDraggedOnce = true;
                      _textBounceAnimCtrl.stop();
                      _textBounceAnimCtrl.value = 0.0;
                      setState(() {});
                    }
                    if (_animating || _anim != null) {
                      _animCtrl.stop();
                      _anim = null;
                      _animating = false;
                    }
                  },
                  onVerticalDragUpdate: (details) {
                    if (_animating || likedCount >= 3) return;
                    setState(() {
                      _offsetY += details.primaryDelta!;
                    });
                  },
                  onVerticalDragEnd: (details) {
                    if (_animating || likedCount >= 3) return;
                    _onDragEnd(context, details);
                  },
                  child: Container(color: appTheme.background),
                ),
              ),

              // Quote text
              Padding(
                padding: EdgeInsets.only(bottom: 150 * yFact),
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragStart: (_) {
                      if (!_hasDraggedOnce) {
                        _hasDraggedOnce = true;
                        _textBounceAnimCtrl.stop();
                        _textBounceAnimCtrl.value = 0.0;
                        setState(() {});
                      }
                      if (_animating || _anim != null) {
                        _animCtrl.stop();
                        _anim = null;
                        _animating = false;
                      }
                    },
                    onVerticalDragUpdate: (details) {
                      if (_animating || likedCount >= 3) return;
                      setState(() {
                        _offsetY += details.primaryDelta!;
                      });
                    },
                    onVerticalDragEnd: (details) {
                      if (_animating || likedCount >= 3) return;
                      _onDragEnd(context, details);
                    },
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_animCtrl, _textBounceOffset]),
                      builder: (context, child) {
                        final bounceDy = (!_hasDraggedOnce ? _textBounceOffset.value * yFact : 0.0);
                        return Transform.translate(
                          offset: Offset(0, _driveOffsetY + bounceDy),
                          child: child,
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15 * xFact),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentQuote.replaceAll("%NAME%", ref.watch(userNameStateProvider)),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: "YesevaOne",
                                fontSize: 22 * xFact,
                                color: appTheme.onBackground,
                                height: 1.22,
                              ),
                            ),
                            if (likedCount < 3) ...[
                              SizedBox(height: 20 * yFact),
                              _buildArrowsAnimation(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3 cœurs en haut
              Positioned(
                top: 25 * yFact,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 25 * xFact),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(likedCount, (_) {
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10 * xFact),
                            child: Image.asset(
                              "assets/images/favoritegold.png",
                              width: 20 * xFact,
                              height: 20 * yFact,
                            ),
                          );
                        }),
                      ],
                    )
                  ],
                ),
              ),

              // Cœur central en bas
              Positioned(
                bottom: 100*yFact,
                left: 0,
                right: 0,
                 child: Center(
                   child: SizedBox(
                     height: 150*yFact,
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       crossAxisAlignment: CrossAxisAlignment.center,
                       children: [
                         GestureDetector(
                           onTap: canLikeCurrent ? _toggleLike : null,
                           child: Opacity(
                             opacity: canLikeCurrent ? 1.0 : 0.4,
                             child: Image.asset(
                               isLiked
                                   ? "assets/images/favoritegold.png"
                                   : "assets/images/favorite.png",
                               width: 45 * xFact,
                               height: 45 * yFact,
                             ),
                           ),
                         ),
                         SizedBox(height: 15 * yFact),
                         Text(
                           translate("onboarding710_text", lang),
                           textAlign: TextAlign.center,
                           style: TextStyle(
                             fontFamily: "InterTight",
                             fontSize: 18 * xFact,
                             color: appTheme.onBackground,
                           ),
                         ),
                       ],
                     ),
                   ),
                 ),
              ),

              // Reward mask
              if (_showRewardMask)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _rewardMaskAnimCtrl,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _rewardMaskAnimCtrl.value,
                        child: GestureDetector(
                          onTap: () {
                            // Tap on the opaque mask: show "Tap here"
                            setState(() {
                              _showTapHere = true;
                            });
                            _tapHereAnimCtrl.repeat(reverse: true);
                            MixpanelService.instance.track("[onboarding4] vue page 4c.");
                          },
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.8),
                            child: Stack(
                              children: [
                                // Flamy image with glasses
                                Positioned(
                                  top: 25 * yFact,
                                  left: 5 * xFact,
                                  child: GestureDetector(
                                    onTap: () async {
                                      // Force open to 1 and save before opening MindSetPoints
                                      await _forceOpenTo1();
                                      if (!mounted) return;
                                      final nav = Navigator.of(this.context);

                                      // Tap on Flamy: open the Mindset Points page with limitations
                                      MixpanelService.instance.track("[onboarding4] vue page 4d.");
                                      nav.push(
                                        MaterialPageRoute(
                                          builder: (context) => MindSetPoints(
                                            fromOnboarding: true,
                                            onFinalMaskTap: () {
                                              // Pop de mindset_points.dart
                                              nav.pop();
                                              // Call forward() to continue the onboarding
                                              if (widget.forward != null) {
                                                _clearOnboarding710Persistence();
                                                widget.forward!();
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: SizedBox(
                                      width: 100 * xFact,
                                      height: 100 * yFact,
                                      child: Image.asset(
                                        'assets/images/flamy/flamy_glasses.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),

                                // Congratulation text (only if _showRewardMask and not yet _showTapHere)
                                if (!_showTapHere)
                                  Positioned(
                                    top: 140 * yFact,
                                    left: 0,
                                    right: 0,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 40 * xFact),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            translate("onboarding710_reward_title", lang).replaceAll("%NAME%", ref.watch(userNameStateProvider)),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: "YesevaOne",
                                              fontSize: 22 * xFact,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 10 * yFact),
                                          Text(
                                            translate("onboarding710_reward_subtitle", lang),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: "YesevaOne",
                                              fontSize: 22 * xFact,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // "+3" animation (visible only after the delay)
                                if (_showPlus3)
                                  Positioned(
                                    top: 35 * yFact,
                                    left: 90 * xFact,
                                    child: AnimatedBuilder(
                                      animation: _plus3AnimCtrl,
                                      builder: (context, child) {
                                        final progress = _plus3AnimCtrl.value;
                                        // Upward movement (0 -> -60px)
                                        final offsetY = -60 * yFact * progress;
                                        // Fade out (1 -> 0)
                                        final opacity = 1.0 - progress;

                                        return Transform.translate(
                                          offset: Offset(0, offsetY),
                                          child: Opacity(
                                            opacity: opacity,
                                            child: Text(
                                              '+3',
                                              style: TextStyle(
                                                color: appTheme.onPrimButtonGold,
                                                fontSize: 18 * xFact,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'InterTight',
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                // Blinking "Tap here" text with arrow
                                if (_showTapHere)
                                  Positioned(
                                    top: 55 * yFact + 50 * yFact,
                                    left: 100 * xFact,
                                    child: AnimatedBuilder(
                                      animation: _tapHereAnimCtrl,
                                      builder: (context, child) {
                                        return Opacity(
                                          opacity: _tapHereAnimCtrl.value,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.north_west,
                                                size: 16 * xFact,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 5 * xFact),
                                              Text(
                                                translate("onboarding710_tap_here", lang),
                                                style: TextStyle(
                                                  fontFamily: "YesevaOne",
                                                  fontSize: 20 * xFact,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

