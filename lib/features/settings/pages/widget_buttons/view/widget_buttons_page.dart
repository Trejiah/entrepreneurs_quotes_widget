import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/data/widget_buttons.dart';
import 'package:businessmindset/features/settings/pages/widget_buttons/view_model/widget_buttons_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WidgetButtonsPage extends ConsumerStatefulWidget {
  const WidgetButtonsPage({super.key});

  @override
  ConsumerState<WidgetButtonsPage> createState() => _WidgetButtonsPageState();
}

class _WidgetButtonsPageState extends ConsumerState<WidgetButtonsPage> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(widgetButtonsViewModelProvider.notifier).loadInitialSelection(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final ui = ref.watch(widgetButtonsViewModelProvider);
    final vm = ref.read(widgetButtonsViewModelProvider.notifier);

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
                      translate('Buttons', lang),
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
                  translate('widget_buttons_subtitle', lang),
                  style: TextStyle(
                    fontFamily: 'InterTight',
                    color: appTheme.onBackground,
                    fontSize: 18 * xFact,
                  ),
                ),
                SizedBox(height: 20 * yFact),
                Expanded(
                  child: ui.loading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(appTheme.lowButtonGold),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: widgetButtonOptions.length,
                          itemBuilder: (context, index) {
                            final option = widgetButtonOptions[index];
                            final selected = ui.selectedIds.contains(option.id);
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * xFact,
                                vertical: 6 * yFact,
                              ),
                              child: TertiaryCheckButton(
                                text: translate(option.localizationKey, lang),
                                checked: selected,
                                onChanged: (_) => vm.toggleOption(option),
                              ),
                            );
                          },
                        ),
                ),
                SizedBox(height: 20 * yFact),
                SecondaryButton(
                  text: translate('save', lang),
                  onTap: () async {
                    final selected = await vm.saveAndSync();
                    if (!context.mounted || selected == null) return;
                    Navigator.of(context).pop<Set<String>>(selected);
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

