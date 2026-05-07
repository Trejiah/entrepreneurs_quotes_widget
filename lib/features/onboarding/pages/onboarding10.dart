import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/services/widget_subscription_sync.dart';
import 'package:businessmindset/theme/themecard.dart';
import 'package:businessmindset/theme/themedatas.dart';
import 'package:businessmindset/widgets/app_button.dart';

class OnBoarding10 extends ConsumerStatefulWidget {
  const OnBoarding10({
    super.key,
    required this.backIcon,
    required this.skipLink,
    required this.title,
    required this.subTitle,
    this.backward,
    this.buttonText,
    this.forward,
    this.variable,
  });
  final bool backIcon;
  final bool skipLink;
  final String title;
  final String subTitle;
  final String? variable;
  final String? buttonText;
  final VoidCallback? backward;
  final VoidCallback? forward;

  @override
  ConsumerState<OnBoarding10> createState() => _OnBoarding10State();
}

class _OnBoarding10State extends ConsumerState<OnBoarding10> {
  String pageStyle = "";
  List<String> choiceList=[];
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  double opacityButton = 0.6;
  int? selectedIndex; // pour check visuel
  static const MethodChannel _widgetChannel = MethodChannel('businessmindset/deeplink');
  
  // Free theme indices (Black, LittleSkin, SkinRed, Skyline New York, Sunny Beach, Mountain Path)
  static const List<int> _freeThemeIndices = [0, 9, 20, 24, 29, 26];

  @override
  void initState() {
    super.initState();
    _loadPref();
  }

  handleTap() async {
    if(kDebugMode){
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("selected index: $selectedIndex");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
    await ref.read(themeIndexProvider.notifier).setTheme(selectedIndex!, isCustom: false);//sauvegarde le thème pour l'app
    ref.read(isCustomThemeProvider.notifier).setValue(false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("${widget.variable}",selectedIndex!);
    // Also save as the default widget theme (before any opening of the Widget page)
    await prefs.setInt("widgetThemeIndex", selectedIndex!);
    await prefs.setBool("widgetIsCustomTheme", false);
    
    // Sync the theme (and language) with the widget to initialize its config
    try {
      final lang = ref.read(languageProvider);
      final premiumExpirationEpochMs = await fetchWidgetPremiumExpirationEpochMs();
      await _widgetChannel.invokeMethod('updateWidgetData', {
        'themeIndex': selectedIndex!,
        'isCustomTheme': false,
        'language': lang,
        'premiumExpirationEpochMs': premiumExpirationEpochMs,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to sync theme to widget: $e');
      }
    }
    
    widget.forward!();
  }

  _loadPref() async {
    final prefs = await SharedPreferences.getInstance();
    selectedIndex = prefs.getInt("${widget.variable}") ?? 0;
    if(selectedIndex != null){
      opacityButton = 1.0;
    }
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    if(kDebugMode) debugPrint("yfact  : $yFact");
    // Determine the number of columns based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    // iPhone : ~390-430px → 3 colonnes
    // iPad: ~768-1024px → 4 or 5 columns
    final crossAxisCount = screenWidth > 600 ? 4 : 3;
    
    // "button zone" height to leave room at the bottom of the scroll
    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      color: appTheme.background,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Builder(
              builder: (context) {
                // Enable scroll only if text scale > 1.0
                final textScale = MediaQuery.of(context).textScaler.scale(1.0);
                final shouldEnableScroll = textScale > 1.0;
                
                final content = Padding(
                  padding: EdgeInsets.only(top : 25*yFact,bottom: 30*yFact),
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      SizedBox(
                        height: 120*yFact,
                        child: Image.asset(
                          'assets/images/flamy/flamy_glasses.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsGeometry.only(left: 30*xFact,right: 30*xFact),
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontFamily: "YesevaOne",
                            fontSize: 28*xFact,
                            color: Color(0xFFfff9ee),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        height: 15*yFact,
                      ),
                      Padding(
                        padding: EdgeInsetsGeometry.only(left: 40*xFact,right: 40*xFact),
                        child: Text(
                          widget.subTitle,
                          style: TextStyle(
                            fontFamily: "InterTight",
                            fontSize: 18*xFact,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFb4ac9c),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20*yFact,
                  ),
                  // --- Theme grid ---
                  // Use Expanded if no scroll, Container with fixed height otherwise
                  shouldEnableScroll
                    ? Container(
                        height: 400*yFact, // Hauteur fixe pour le scroll
                        decoration: BoxDecoration(
                          color: appTheme.background
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30 * xFact),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _freeThemeIndices.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 14*yFact,
                              crossAxisSpacing: 14*xFact,
                              childAspectRatio: 0.60, // cartes un peu verticales
                            ),
                            itemBuilder: (context, i) {
                              final themeIndex = _freeThemeIndices[i];
                              final isSelected = themeIndex == selectedIndex;
                              return ThemeCard(
                                selected: isSelected,
                                onTap: () async {
                                  opacityButton = 1.0;
                                  setState(() => selectedIndex = themeIndex);
                                },
                                currentTheme: allAppThemes[themeIndex],
                                isCustom: false,
                                onDelete: () {  },
                                isPremium: true,
                                isFree: true,
                                language: lang,
                              );
                            },
                          ),
                        ),
                      )
                    : Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: appTheme.background
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 30 * xFact),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _freeThemeIndices.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 14*yFact,
                                crossAxisSpacing: 14*xFact,
                                childAspectRatio: 0.60, // cartes un peu verticales
                              ),
                              itemBuilder: (context, i) {
                                final themeIndex = _freeThemeIndices[i];
                                final isSelected = themeIndex == selectedIndex;
                                return ThemeCard(
                                  selected: isSelected,
                                  onTap: () async {
                                    opacityButton = 1.0;
                                    setState(() => selectedIndex = themeIndex);
                                  },
                                  currentTheme: allAppThemes[themeIndex],
                                  isCustom: false,
                                  onDelete: () {  },
                                  isPremium: true,
                                  isFree: true,
                                  language: lang,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                  SizedBox(
                    height: 0*yFact,
                  ),
                  Padding(
                    padding: EdgeInsetsGeometry.only(right: 20*xFact,left: 20*xFact),
                    child: Opacity(
                      opacity: opacityButton,
                      child: SecondaryButton(
                        text: translate(widget.buttonText!,lang),
                        onTap: () {
                          if(opacityButton == 1.0) handleTap();
                        },
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
            Column(
              children: [
                SizedBox(
                  height: 15*yFact,
                ),
                (widget.backIcon || widget.skipLink) ? Padding(
                  padding: EdgeInsets.only(left: 20*xFact,right: 20*xFact),
                  child: SizedBox(
                    height: 26*yFact,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        widget.backIcon ? GestureDetector(
                          onTap: widget.backward,
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Color(0xFFfff9ee),
                          ),
                        ) : SizedBox(
                          width: 25*xFact,
                        ),
                        widget.skipLink ? GestureDetector(
                          onTap: widget.forward,
                          child: Text(
                            translate("skip",lang),
                            style: TextStyle(
                              fontFamily: "InterTight",
                              fontSize: 18*xFact,
                              color: Color(0xFFb4ac9c),
                            ),
                          ),
                        ) : SizedBox(
                          width: 25*xFact,
                        ),
                      ],
                    ),
                  ),
                ) : SizedBox(
                  height: 26*yFact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}