import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/favorites/view_model/favorites_provider.dart';
import 'package:businessmindset/models/topics.dart';
import 'package:businessmindset/features/onboarding/pages/onboarding20bis.dart';
import 'package:businessmindset/providers/habits_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/features/paywall/view/paywallb_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  late final ScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();
    Future.microtask(() {
      final premium = ref.read(premiumProvider);
      ref.read(favoritesViewModelProvider.notifier).loadSelectedTopics(
            premium: premium,
          );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<bool> _handleBackNavigation() async {
    final premium = ref.read(premiumProvider);
    final habits = ref.read(habitsStateProvider);
    final lang = ref.read(languageProvider);
    final modified = await ref
        .read(favoritesViewModelProvider.notifier)
        .persistSelectionAndReschedule(
          premium: premium,
          habits: habits,
          languageCode: lang,
        );

    if (!mounted) return false;
    Navigator.pop(context, modified);
    return false;
  }

  void _openPaywall() {
    final lang = ref.read(languageProvider);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Paywallb(
          pageStyle: 'notdeclare',
          backIcon: true,
          skipLink: false,
          backward: () {},
          forward1: () {
            _purchaseOk();
          },
          forward2: () {},
          title: translate('onboardingtitle3', lang),
          subTitle: translate('onboardingsubtitle3', lang),
          choiceList: [],
          buttonText: 'letsgo',
        ),
      ),
    );
  }

  void _purchaseOk() {
    final lang = ref.read(languageProvider);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => OnBoarding20bis(
          backIcon: false,
          skipLink: false,
          backward: () {},
          forward: () {
            final modified = ref.read(favoritesViewModelProvider).favoritesModified;
            Navigator.pop(context, modified);
          },
          title: translate('onboardingtitle20bis', lang),
          subTitle: translate('onboardingsubtitle20bis', lang),
          choiceList: [],
          buttonText: 'letsbegin',
        ),
      ),
    );
  }

  Widget _buildTopicButton({
    required String topicId,
    required String label,
    required String iconName,
    required bool premium,
  }) {
    final state = ref.watch(favoritesViewModelProvider);
    final vm = ref.read(favoritesViewModelProvider.notifier);
    final isSelected = state.selectedTopics.contains(topicId);
    final isLocked = vm.isTopicLocked(topicId, premium: premium);

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          _openPaywall();
        } else {
          vm.toggleTopic(topicId);
        }
      },
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20 * xFact,
              vertical: 15 * yFact,
            ),
            margin: EdgeInsets.only(right: 10 * xFact),
            decoration: BoxDecoration(
              color: isLocked
                  ? appTheme.settingsButton
                  : isSelected
                      ? appTheme.onBackground
                      : appTheme.background,
              borderRadius: BorderRadius.circular(10 * xFact),
              border: Border.all(
                color: appTheme.onBackground,
                width: 1 * xFact,
              ),
            ),
            child: Opacity(
              opacity: isLocked ? 0.5 : 1.0,
              child: Row(
                children: [
                  SizedBox(
                    width: 35 * xFact,
                    height: 35 * yFact,
                    child: Image.asset('assets/images/$iconName.png'),
                  ),
                  SizedBox(width: 15 * xFact),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isLocked
                            ? appTheme.onBackground.withValues(alpha: 0.5)
                            : isSelected
                                ? appTheme.background
                                : appTheme.onBackground,
                        fontFamily: 'InterTight',
                        fontSize: 19 * xFact,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLocked)
            Positioned(
              top: 8 * yFact,
              right: 18 * xFact,
              child: Opacity(
                opacity: 0.5,
                child: SizedBox(
                  width: 20 * xFact,
                  height: 20 * yFact,
                  child: Image.asset('assets/images/cadenas.png'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(premiumProvider);
    final lang = ref.watch(languageProvider);
    final state = ref.watch(favoritesViewModelProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Material(
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(color: appTheme.background),
            child: SafeArea(
              top: true,
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: _handleBackNavigation,
                        child: Icon(
                          Icons.check_circle,
                          color: appTheme.onBackground,
                          size: 40 * xFact,
                        ),
                      ),
                    ),
                    Text(
                      translate('topics_title', lang),
                      style: TextStyle(
                        fontFamily: 'YesevaOne',
                        color: appTheme.onBackground,
                        fontSize: 30 * xFact,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10 * yFact),
                    Text(
                      translate('topics_subtitle', lang),
                      style: TextStyle(
                        fontFamily: 'InterTight',
                        color: appTheme.onBackgroundSub,
                        fontSize: 18 * xFact,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30 * yFact),
                    Expanded(
                      child: RawScrollbar(
                        controller: _ctrl,
                        thumbVisibility: true,
                        thumbColor: appTheme.onBackgroundSub,
                        trackColor: appTheme.background,
                        radius: Radius.circular(10 * xFact),
                        thickness: 4 * xFact,
                        child: ListView.separated(
                          controller: _ctrl,
                          physics: const BouncingScrollPhysics(),
                          itemCount: state.topics.length,
                          separatorBuilder: (_, __) => SizedBox(height: 15 * yFact),
                          itemBuilder: (context, index) {
                            final topic = state.topics[index];
                            final label = translate(topic.labelKey, lang);
                            final iconName = topicIconMap[topic.id] ?? 'mypersfeed';
                            return _buildTopicButton(
                              topicId: topic.id,
                              label: label,
                              iconName: iconName,
                              premium: premium,
                            );
                          },
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
    );
  }
}
