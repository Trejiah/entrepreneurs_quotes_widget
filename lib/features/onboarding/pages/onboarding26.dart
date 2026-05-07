import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/widgets/app_button.dart';

class OnBoarding26 extends ConsumerStatefulWidget {
  const OnBoarding26({
    super.key,
    required this.backIcon,
    required this.title,
    required this.subTitle,
    this.backward,
    this.forward,
  });
  final bool backIcon;
  final String title;
  final String subTitle;
  final VoidCallback? backward;
  final VoidCallback? forward;

  @override
  ConsumerState<OnBoarding26> createState() => _OnBoarding26State();
}

class _OnBoarding26State extends ConsumerState<OnBoarding26> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  final PageController _whatsIncludedController = PageController();

  // The 3 "What's included" screens - translation keys
  List<List<Map<String, String>>> _getWhatsIncludedScreens(String lang) {
    return [
      [
        {
          'image': 'mockup-widget-lockscreen.png',
          'textKey': 'customized_widgets',
        },
      ],
      [
        {
          'image': 'mockup-capture4v2modif.png',
          'textKey': 'personalized_quote_feed',
        },
      ],
    ];
  }
  int _currentWhatsIncludedPage = 0;

  @override
  void initState() {
    super.initState();
    _whatsIncludedController.addListener(() {
      setState(() {
        _currentWhatsIncludedPage = _whatsIncludedController.page?.round() ?? 0;
      });
    });
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
            final shouldEnableScroll = textScale > 1.5;
            
            final content = Stack(
              children: [
              // Back icon at the top left
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
              // Contenu principal
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: textScale > 1.2 ? 20*yFact : 40 * yFact),
                      // Image flamy_glasses
                      SizedBox(
                        height: 130 * yFact,
                        child: Image.asset(
                          'assets/images/flamy/flamy_glasses_phone.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: 0 * yFact),
                      // Titre
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40 * xFact),
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
                      SizedBox(height: (textScale > 1.1) ? 0 : 10 * yFact),
                      // Image widget_mage.png
                      Container(
                        height:  textScale > 1.2 ? 320*yFact : textScale > 1.1 ? 330*yFact : 350 * yFact,
                        child: PageView.builder(
                          controller: _whatsIncludedController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentWhatsIncludedPage = index;
                            });
                          },
                          itemCount: _getWhatsIncludedScreens(lang).length,
                          itemBuilder: (context, index) {
                            final screen = _getWhatsIncludedScreens(lang)[index];
                            return Stack(
                              children: [
                                for (var item in screen)
                                  Stack(
                                    children: [
                                      Center(
                                        child: SizedBox(
                                          width: 350,
                                          height: double.maxFinite,
                                          child: Image.asset(
                                            'assets/images/${item['image']}',
                                            fit: BoxFit.fitWidth,
                                            alignment: Alignment.topCenter,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.image,
                                                size: 30 * xFact,
                                                color: appTheme.onBackground,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                                colors: [
                                                  appTheme.background.withValues(alpha: 0),
                                                  appTheme.background,
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                stops: [
                                                  0.2,
                                                  0.95
                                                ]
                                            )
                                        ),
                                      )
                                    ],
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < _getWhatsIncludedScreens(lang).length; i++)
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 8 * xFact),
                              width: 10 * xFact,
                              height: 10 * xFact,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == _currentWhatsIncludedPage
                                      ? appTheme.onBackground
                                      : appTheme.background,
                                  border: Border.all(color: appTheme.onBackgroundSub)
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 30*yFact,left: 30*xFact,right: 30*xFact),
                    child: SecondaryButton(
                      text: translate("gotit", lang),
                      onTap: () {
                        if (widget.forward != null) {
                          widget.forward!();
                        }
                      },
                    ),
                  ),
                ],
              ),
              // Bouton Continue en bas
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

