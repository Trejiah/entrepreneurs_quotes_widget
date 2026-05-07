import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/settings/pages/widget/view_model/widget_provider.dart';
import 'package:businessmindset/features/settings/pages/widget_buttons/view/widget_buttons_page.dart';
import 'package:businessmindset/features/settings/pages/widget_frequency/view/widget_frequency_page.dart';
import 'package:businessmindset/features/settings/pages/widget_topics/view/widget_topics_page.dart';
import 'package:businessmindset/features/themes/view/themes_page.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WidgetPage extends ConsumerStatefulWidget {
  const WidgetPage({super.key, this.fromWidget = false});

  final bool fromWidget;

  @override
  ConsumerState<WidgetPage> createState() => _WidgetPageState();
}

class _WidgetPageState extends ConsumerState<WidgetPage> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(widgetViewModelProvider.notifier).init());
  }

  void _handleBackPress() {
    if (widget.fromWidget) {
      if (kDebugMode) {
        debugPrint('WidgetPage: Back pressed from widget - returning to previous screen');
      }
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _openTopicsPage() async {
    if (kDebugMode) debugPrint('WidgetPage: Topics button tapped');
    final vm = ref.read(widgetViewModelProvider.notifier);
    final result = await Navigator.push<List<String>?>(
      context,
      MaterialPageRoute(builder: (_) => const WidgetTopicsPage()),
    );
    if (!mounted) return;
    if (result != null) {
      vm.applyTopicsResult(result);
    } else {
      await vm.loadWidgetTopics();
    }
  }

  Future<void> _openFrequencyPage() async {
    if (kDebugMode) debugPrint('WidgetPage: Update frequency button tapped');
    final vm = ref.read(widgetViewModelProvider.notifier);
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const WidgetFrequencyPage()),
    );
    if (!mounted) return;
    if (result != null) {
      vm.applyFrequencyResult(result);
    } else {
      await vm.loadWidgetFrequency();
    }
  }

  Future<void> _openButtonsPage() async {
    if (kDebugMode) debugPrint('WidgetPage: Buttons button tapped');
    final vm = ref.read(widgetViewModelProvider.notifier);
    final result = await Navigator.push<Set<String>?>(
      context,
      MaterialPageRoute(builder: (_) => const WidgetButtonsPage()),
    );
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      vm.applyButtonsResult(result);
    } else {
      await vm.loadWidgetButtons();
    }
  }

  Widget _buildInfoButton(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final lang = ref.watch(languageProvider);
    final maxSubtitleWidth = MediaQuery.of(context).size.width * 0.45;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.maxFinite,
        decoration: BoxDecoration(color: appTheme.settingsButton),
        child: Padding(
          padding: EdgeInsets.only(
            left: 10 * xFact,
            right: 10 * xFact,
            top: 12 * yFact,
            bottom: 12 * yFact,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  translate(title, lang),
                  style: TextStyle(
                    color: appTheme.onBackground,
                    fontFamily: "InterTight",
                    fontSize: 18 * xFact,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 8 * xFact),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxSubtitleWidth),
                child: Text(
                  translate(subtitle, lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: appTheme.onBackgroundSub,
                    fontFamily: "InterTight",
                    fontSize: 18 * xFact,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 5 * xFact),
              Icon(
                Icons.arrow_forward_ios,
                color: appTheme.onBackground,
                size: 18 * xFact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final vm = ref.read(widgetViewModelProvider.notifier);
    final ui = ref.watch(widgetViewModelProvider);
    final topicsLabel = vm.topicsLabel(lang);
    final frequencyLabel = vm.frequencyLabel(lang);
    final buttonsLabel = vm.buttonsLabel(lang);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: appTheme.background),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10 * xFact),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(width: 10 * xFact),
                    GestureDetector(
                      onTap: _handleBackPress,
                      child: Icon(Icons.arrow_back_ios, color: appTheme.onBackground, size: 30 * xFact),
                    ),
                    SizedBox(width: 5 * xFact),
                    Text(
                      translate("Widget", lang),
                      style: TextStyle(
                        fontFamily: "YesevaOne",
                        color: appTheme.onBackground,
                        fontSize: 35 * xFact,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20 * xFact),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      translate("Customize your Business Mindset widget.", lang),
                      style: TextStyle(
                        fontFamily: "InterTight",
                        fontSize: 22 * xFact,
                        color: appTheme.onBackground,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20 * xFact),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10 * xFact),
                    child: Column(
                      children: [
                        _buildInfoButton(context, "Theme", ui.selectedTheme, () async {
                          if (kDebugMode) debugPrint('WidgetPage: Theme button tapped');
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ThemesPage(fromWidget: true),
                            ),
                          );
                          if (!mounted) return;
                          await vm.loadWidgetTheme();
                        }),
                        SizedBox(height: 2 * yFact),
                        _buildInfoButton(context, "Topics", topicsLabel, _openTopicsPage),
                        SizedBox(height: 2 * yFact),
                        _buildInfoButton(
                          context,
                          "update_frequency_title",
                          frequencyLabel,
                          _openFrequencyPage,
                        ),
                        SizedBox(height: 2 * yFact),
                        _buildInfoButton(context, "Buttons", buttonsLabel, _openButtonsPage),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

