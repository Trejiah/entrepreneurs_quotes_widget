import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/settings/pages/notifications_choice/view_model/notifications_choice_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsChoicePage extends ConsumerStatefulWidget {
  const NotificationsChoicePage({super.key});

  @override
  ConsumerState<NotificationsChoicePage> createState() =>
      _NotificationsChoicePageState();
}

class _NotificationsChoicePageState extends ConsumerState<NotificationsChoicePage> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationsChoiceViewModelProvider.notifier).init();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final state = ref.watch(notificationsChoiceViewModelProvider);
    final vm = ref.read(notificationsChoiceViewModelProvider.notifier);
    final filteredQuotes = state.filteredQuotes;

    return Scaffold(
      backgroundColor: appTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20 * xFact),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back,
                      color: appTheme.onBackground,
                      size: 30 * xFact,
                    ),
                  ),
                  SizedBox(width: 15 * xFact),
                  Expanded(
                    child: Text(
                      'Choix Notifications',
                      style: TextStyle(
                        fontFamily: 'YesevaOne',
                        color: appTheme.onBackground,
                        fontSize: 24 * xFact,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
              child: Text(
                'Citations cochees apparaitront EN PREMIER dans les notifications\nLes suivantes seront generees automatiquement',
                style: TextStyle(
                  fontFamily: 'InterTight',
                  color: appTheme.onBackground.withValues(alpha: 0.7),
                  fontSize: 14 * xFact,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20 * yFact),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
              child: LoupeTextField(
                hintText: translate('search', lang),
                onChanged: vm.onSearchChanged,
              ),
            ),
            SizedBox(height: 20 * yFact),
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
                  itemCount: filteredQuotes.length,
                  itemBuilder: (context, index) {
                    final quote = filteredQuotes[index];
                    final text = quote.text;
                    final isSelected = state.selectedQuotes.contains(text);
                    final selectedIndex =
                        isSelected ? state.selectedQuotes.indexOf(text) + 1 : null;

                    return Card(
                      color: appTheme.textField,
                      margin: EdgeInsets.only(bottom: 10 * yFact),
                      child: Padding(
                        padding: EdgeInsets.all(10 * xFact),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                text,
                                style: TextStyle(
                                  fontFamily: 'InterTight',
                                  color: appTheme.onBackground,
                                  fontSize: 16 * xFact,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 10 * xFact),
                            GestureDetector(
                              onTap: () => vm.toggleQuote(text),
                              child: Container(
                                width: 24 * xFact,
                                height: 24 * xFact,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? appTheme.containerPrimButton
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: appTheme.onBackground,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Text(
                                          '$selectedIndex',
                                          style: TextStyle(
                                            color: appTheme.onPrimButton,
                                            fontSize: 12 * xFact,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20 * xFact),
              child: SecondaryButton(
                text: translate('save', lang),
                onTap: () async {
                  await vm.saveChoices();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(translate('save', lang)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

