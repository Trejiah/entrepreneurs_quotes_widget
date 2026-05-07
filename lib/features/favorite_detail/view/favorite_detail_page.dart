import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/favorite_detail/model/favorite_detail_models.dart';
import 'package:businessmindset/features/favorite_detail/view_model/favorite_detail_provider.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding20bis.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/services/share_quotes.dart';
import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/utils/favorite_management.dart';
import 'package:businessmindset/features/paywall/view/paywallb_page.dart';
import 'package:businessmindset/widgets/app_button.dart';

/// Vue MVVM pour `FavoriteDetail`.
///
/// Note : on garde l'API de l'ancien widget (même constructeur) pour éviter de casser les imports.
class FavoriteDetail extends ConsumerStatefulWidget {
  const FavoriteDetail({
    super.key,
    required this.boxHeight,
    required this.inputMaxCarac,
    required this.pageStyle,
    required this.title,
    required this.subTitle,
    required this.choiceList,
    required this.inputStyle,
    required this.hintText,
    this.backward,
    this.buttonText,
    this.forward,
    this.variable,
  });

  final String pageStyle;
  final String title;
  final String hintText;
  final double boxHeight;
  final int inputMaxCarac;
  final String subTitle;
  final String? variable;
  final String? buttonText;
  final String? inputStyle;
  final VoidCallback? backward;
  final VoidCallback? forward;
  final List<String> choiceList;

  @override
  ConsumerState<FavoriteDetail> createState() => _FavoriteDetailPageState();
}

class _FavoriteDetailPageState extends ConsumerState<FavoriteDetail> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  late final ScrollController _ctrl;

  late final FavoriteDetailInput _input;

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();

    _input = FavoriteDetailInput(
      pageStyle: widget.pageStyle,
      choiceList: widget.choiceList,
      variable: widget.variable,
    );

    Future.microtask(() async {
      final vm = ref.read(favoriteDetailViewModelProvider(_input).notifier);
      await vm.loadQuotesIntoGlobal();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<DayQuote> _reverseAndLimit(
    List<DayQuote> list,
    bool premium, {
    int limit = 10,
  }) {
    final reversed = List<DayQuote>.from(list.reversed);
    if (premium) return reversed;
    return reversed.take(min(limit, reversed.length)).toList();
  }

  Future<void> _purchaseOk() async {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => OnBoarding20bis(
          backIcon: false,
          skipLink: false,
          backward: () {},
          forward: () {
            final state =
                ref.read(favoriteDetailViewModelProvider(_input)).favoritesModified;
            Navigator.pop(context, state);
          },
          title: translate("onboardingtitle20bis", ref.read(languageProvider)),
          subTitle: translate(
            "onboardingsubtitle20bis",
            ref.read(languageProvider),
          ),
          choiceList: [],
          buttonText: "letsbegin",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final premium = ref.watch(premiumProvider);

    final state = ref.watch(favoriteDetailViewModelProvider(_input));
    final vm = ref.read(favoriteDetailViewModelProvider(_input).notifier);

    final useSearch = state.useSearch;

    return Material(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(color: appTheme.background),
          child: SafeArea(
            top: true,
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10 * xFact),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context, state.favoritesModified),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: appTheme.onBackground,
                          size: 40 * xFact,
                        ),
                      ),
                      SizedBox(width: 10 * xFact),
                      Text(
                        translate("Favorites", lang),
                        style: TextStyle(
                          fontFamily: "YesevaOne",
                          color: appTheme.onBackground,
                          fontSize: 35 * xFact,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 22 * yFact),

                  LoupeTextField(
                    hintText: translate("search", lang),
                    onChanged: (value) {
                      vm.onSearchChanged(value);
                    },
                  ),

                  SizedBox(height: 22 * yFact),

                  Expanded(
                    child: Builder(
                      builder: (context) {
                        bool quoteDisplayed = true;
                        late final List<DayQuote> displayList;

                        if (widget.pageStyle == "search") {
                          displayList = useSearch ? state.results : state.quotesGlobal;
                        } else {
                          displayList = useSearch
                              ? state.results
                              : _reverseAndLimit(state.historyGlobal, premium);
                        }

                        if (useSearch && displayList.isEmpty) {
                          // Zone suggestion
                          if (!state.suggestionAllowed || state.randomQuote.isEmpty) {
                            quoteDisplayed = false;
                          }

                          return Padding(
                            padding: EdgeInsets.only(left: 16 * xFact, right: 16 * xFact),
                            child: Column(
                              children: [
                                SizedBox(height: 40 * yFact),
                                quoteDisplayed
                                    ? Text(
                                        translate("youmightlike", lang),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: "InterTight",
                                          color: appTheme.onBackground,
                                          fontSize: 18 * xFact,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                    : Text(
                                        translate("nomatch", lang),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: "InterTight",
                                          color: appTheme.onBackground,
                                          fontSize: 18 * xFact,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                SizedBox(height: 55 * yFact),
                                if (quoteDisplayed)
                                  Text(
                                    state.randomQuote,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: "InterTight",
                                      color: appTheme.onBackground,
                                      fontSize: 18 * xFact,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                if (quoteDisplayed) SizedBox(height: 60 * yFact),
                                if (quoteDisplayed)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Right arrow button (share)
                                      GestureDetector(
                                        onTap: () async {
                                          final shared =
                                              await shareQuote(state.randomQuote, context: context);
                                          vm.trackShareResult(shared);
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.only(right: 12 * xFact),
                                          child: Image.asset(
                                            "assets/images/share2.png",
                                            width: 28 * xFact,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10 * xFact),
                                      // Heart button (like suggestion)
                                      GestureDetector(
                                        onTap: () async {
                                          await vm.likeRandomSuggestion();
                                        },
                                        child: Image.asset(
                                          "assets/images/favorite.png",
                                          width: 28 * xFact,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        }

                        // List view
                        return Scrollbar(
                          controller: _ctrl,
                          thumbVisibility: true,
                          child: ListView.separated(
                            controller: _ctrl,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.only(right: 10 * xFact),
                            itemCount: displayList.length,
                            separatorBuilder: (_, __) => SizedBox(height: 15 * yFact),
                            itemBuilder: (context, index) {
                              final q = displayList[index];
                              final item = q.quote;

                              int originalIndex;
                              if (widget.pageStyle == "search") {
                                originalIndex = state.quotesGlobal.indexOf(q);
                              } else {
                                originalIndex = state.historyGlobal.indexOf(q);
                              }

                              final isChecked = originalIndex >= 0 &&
                                  originalIndex < state.isChecked.length &&
                                  state.isChecked[originalIndex];

                              final itemDate = lang == "fr"
                                  ? "${q.day} ${q.month} ${q.year}"
                                  : "${q.month} ${q.day},  ${q.year}";

                              return FavoriteButton2(
                                leftIcon: "share2.png",
                                rightIcon: isChecked
                                    ? "favoritegold.png"
                                    : "favorite.png",
                                label: translate(item, lang),
                                fontFamily: "InterTight",
                                fontSize: 18 * xFact,
                                color: appTheme.onBackground,
                                dateLabel: itemDate,
                                onLeftTap: () async {
                                  await vm.onLeftFavoriteTapped(
                                    originalIndex: originalIndex,
                                    quoteText: item,
                                    currentlyChecked: isChecked,
                                  );
                                },
                                onRightTap: () async {
                                  final shared = await shareQuote(item, context: context);
                                  vm.trackShareResult(shared);
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  if (!premium && widget.pageStyle != "search")
                    SizedBox(height: 15 * yFact),

                  if (!premium && widget.pageStyle != "search")
                    Padding(
                      padding: EdgeInsets.only(
                        left: 20 * xFact,
                        right: 20 * xFact,
                        bottom: 15 * yFact,
                      ),
                      child: SecondaryButton(
                        text: "See older quotes",
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => Paywallb(
                                pageStyle: "notdeclare",
                                backIcon: true,
                                skipLink: false,
                                backward: () {},
                                forward1: () {
                                  _purchaseOk();
                                },
                                forward2: () {
                                  // empty: the dialog isn't open in this case
                                },
                                title: translate("onboardingtitle3", lang),
                                subTitle: translate("onboardingsubtitle3", lang),
                                choiceList: [],
                                buttonText: "letsgo",
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
        ),
      ),
    );
  }
}

