import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/paywall/view/paywallb_page.dart';
import 'package:businessmindset/features/settings/pages/widget_topics/view_model/widget_topics_provider.dart';
import 'package:businessmindset/models/topics.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WidgetTopicsPage extends ConsumerStatefulWidget {
  const WidgetTopicsPage({super.key});

  @override
  ConsumerState<WidgetTopicsPage> createState() => _WidgetTopicsPageState();
}

class _WidgetTopicsPageState extends ConsumerState<WidgetTopicsPage> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(widgetTopicsViewModelProvider.notifier).loadInitialSelection(),
    );
  }

  Future<void> _showPremiumDialog() async {
    final lang = ref.read(languageProvider);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Paywallb(
          pageStyle: 'check2',
          backIcon: true,
          skipLink: false,
          title: translate('Premium', lang),
          subTitle: translate('unlocktopics', lang),
          choiceList: const [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final premium = ref.watch(premiumProvider);
    final ui = ref.watch(widgetTopicsViewModelProvider);
    final vm = ref.read(widgetTopicsViewModelProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: appTheme.background),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10 * yFact),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: appTheme.onBackground,
                        size: 30 * xFact,
                      ),
                    ),
                    SizedBox(width: 10 * xFact),
                    Text(
                      translate('Topics', lang),
                      style: TextStyle(
                        fontFamily: 'YesevaOne',
                        color: appTheme.onBackground,
                        fontSize: 32 * xFact,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8 * yFact),
                Text(
                  translate('topics_widget_subtitle', lang),
                  style: TextStyle(
                    fontFamily: 'InterTight',
                    color: appTheme.onBackground,
                    fontSize: 18 * xFact,
                  ),
                ),
                SizedBox(height: 20 * yFact),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12 * xFact),
                    child: Container(
                      color: appTheme.settingsButton,
                      child: ui.loading
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(appTheme.lowButtonGold),
                              ),
                            )
                          : ListView.separated(
                              itemCount: widgetTopicDefinitions.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: appTheme.onBackground.withValues(alpha: 0.08),
                              ),
                              itemBuilder: (context, index) {
                                final topic = widgetTopicDefinitions[index];
                                final selected = ui.selected.contains(topic.id);
                                final locked = vm.isTopicLocked(topic.id, premium);
                                return InkWell(
                                  onTap: () async {
                                    final ok = vm.toggleTopic(topic);
                                    if (!ok && locked) {
                                      await _showPremiumDialog();
                                    }
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20 * xFact,
                                      vertical: 14 * yFact,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.circle_rounded,
                                              size: 12 * xFact,
                                              color: const Color(0xFFfff9ee),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              translate(topic.localizationKey, lang),
                                              style: TextStyle(
                                                fontFamily: 'InterTight',
                                                fontSize: 18 * xFact,
                                                color: appTheme.onBackground,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Icon(
                                          selected ? Icons.check : Icons.add,
                                          color: selected
                                              ? appTheme.lowButtonGold
                                              : appTheme.onBackground,
                                          size: 22 * xFact,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 20 * yFact),
                SecondaryButton(
                  text: translate('save', lang),
                  onTap: () async {
                    final result = await vm.saveAndSync();
                    if (!context.mounted || result == null) return;
                    Navigator.of(context).pop(result);
                  },
                ),
                SizedBox(height: 20 * yFact),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

