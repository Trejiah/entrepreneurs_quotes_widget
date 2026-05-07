import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/widgets/app_button.dart';

class OnBoarding27 extends ConsumerStatefulWidget {
  const OnBoarding27({
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
  ConsumerState<OnBoarding27> createState() => _OnBoarding27State();
}

class _OnBoarding27State extends ConsumerState<OnBoarding27> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  String inputText = "";
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _textFieldKey = GlobalKey();

  void _scrollToTextField() {
    if (!_focusNode.hasFocus || _textFieldKey.currentContext == null) return;
    
    // Wait for the keyboard to open
    Future.delayed(Duration(milliseconds: 500), () {
      if (!mounted || _textFieldKey.currentContext == null) return;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _textFieldKey.currentContext == null) return;
        
        // Use Scrollable.ensureVisible simply
        try {
          Scrollable.ensureVisible(
            _textFieldKey.currentContext!,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.0,
          );
        } catch (e) {
          // If that doesn't work, try with the ScrollController
          if (_scrollController.hasClients) {
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            if (keyboardHeight > 0) {
              // Scroll by an amount based on the keyboard height
              final currentScroll = _scrollController.position.pixels;
              final targetScroll = currentScroll + (keyboardHeight * 0.5);
              _scrollController.animateTo(
                targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSavedInput();
    _textController.addListener(() {
      setState(() {
        inputText = _textController.text;
      });
    });
    // Scroll to the field only when it gains focus (keyboard opens)
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _scrollToTextField();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadSavedInput() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString("goals");
      if (saved != null) {
        _textController.text = saved;
        setState(() {
          inputText = saved;
        });
      }
    });
  }

  handleTap() async {
    // Save only when Continue is clicked
    final prefs = await SharedPreferences.getInstance();
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("Input saved! : $inputText");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
      await prefs.setString("goals", inputText);
      await prefs.reload();
      if (widget.forward != null) {
        widget.forward!();
      }
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
        child: Stack(
          children: [
            // Main content with scroll to stay visible when the keyboard opens
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Header with progress bar and back icon
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        // Barre de progression
                        Padding(
                          padding: EdgeInsets.only(top: 9, left: 0, right: 0),
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
                        // Back icon
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
                      ],
                    ),
                  ),
                  // Contenu principal
                  SliverPadding(
                    padding: EdgeInsets.only(
                      top: 40 * yFact,
                      bottom: 100 * yFact,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
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
                          SizedBox(
                            height: 30 * yFact,
                          ),
                          Padding(
                            padding: EdgeInsetsGeometry.only(right: 35 * xFact, left: 35 * xFact),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  key: _textFieldKey,
                                  child: CustomTextField(
                                    minLines: 8,
                                    maxLines: 8,
                                    maxLength: 250,
                                    inputStyle: "input2",
                                    fontFamily: "InterTight",
                                    fontSize: 18 * xFact,
                                    backgroundColor: Color(0xFF504b41).withAlpha(90),
                                    borderColor: Color(0xFF504b41),
                                    textColor: appTheme.onBackground,
                                    hintText: translate("Iwantto", lang),
                                    controller: _textController,
                                    focusNode: _focusNode,
                                    textInputAction: TextInputAction.done,
                                    onChanged: (String value) {
                                      // Update only the local state, no save
                                      setState(() {
                                        inputText = value;
                                      });
                                    },
                                    onSubmitted: () {
                                      // Close the keyboard when validating with the Enter key
                                      _focusNode.unfocus();
                                    },
                                  ),
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
                                          '${value.text.length}/250',
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bouton Continue en bas
            Positioned(
              bottom: 30 * yFact,
              left: 20 * xFact,
              right: 20 * xFact,
              child: SecondaryButton(
                text: translate("continue", lang),
                onTap: () => handleTap(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

