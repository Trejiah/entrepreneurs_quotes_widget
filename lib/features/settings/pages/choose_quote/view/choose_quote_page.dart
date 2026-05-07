import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/app_localizations.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/settings/pages/choose_quote/view_model/choose_quote_provider.dart';
import 'package:businessmindset/providers/language_provider.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChooseQuotePage extends ConsumerStatefulWidget {
  const ChooseQuotePage({super.key});

  @override
  ConsumerState<ChooseQuotePage> createState() => _ChooseQuotePageState();
}

class _ChooseQuotePageState extends ConsumerState<ChooseQuotePage> {
  final xFact = ScreenScale.x;
  final yFact = ScreenScale.y;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chooseQuoteViewModelProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final ui = ref.watch(chooseQuoteViewModelProvider);
    final vm = ref.read(chooseQuoteViewModelProvider.notifier);

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
                  Text(
                    translate('Choix Citation', lang),
                    style: TextStyle(
                      fontFamily: 'YesevaOne',
                      color: appTheme.onBackground,
                      fontSize: 24 * xFact,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
              child: LoupeTextField(
                hintText: translate('search', lang),
                onChanged: vm.onSearchChanged,
              ),
            ),
            SizedBox(height: 20 * yFact),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20 * xFact),
                itemCount: ui.filteredQuotes.length,
                itemBuilder: (context, index) {
                  final quote = ui.filteredQuotes[index];
                  return Card(
                    color: appTheme.textField,
                    margin: EdgeInsets.only(bottom: 10 * yFact),
                    child: ListTile(
                      title: Text(
                        quote.text,
                        style: TextStyle(
                          fontFamily: 'InterTight',
                          color: appTheme.onBackground,
                          fontSize: 16 * xFact,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () async {
                        await vm.selectQuote(quote);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

