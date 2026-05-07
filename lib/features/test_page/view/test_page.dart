// ignore_for_file: camel_case_types

import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/features/test_page/model/test_page_models.dart';
import 'package:businessmindset/features/test_page/view_model/test_page_provider.dart';
import 'package:businessmindset/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Test_page extends ConsumerStatefulWidget {
  const Test_page({super.key});

  @override
  ConsumerState<Test_page> createState() => _TestPageState();
}

class _TestPageState extends ConsumerState<Test_page> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      ref
          .read(testPageViewModelProvider.notifier)
          .onTextChanged(_textController.text);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(testPageViewModelProvider);

    return Scaffold(
      body: Container(
        height: double.maxFinite,
        width: double.maxFinite,
        color: appTheme.background,
        child: Column(
          children: [
            const SizedBox(height: 25),
            Text(
              TestPageLabels.title,
              style: TextStyle(color: appTheme.onBackground),
            ),
            const SizedBox(height: 25),
            const Padding(
              padding: EdgeInsets.only(right: 10, left: 10, bottom: 10),
              child: _ButtonsSection(),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10, left: 10, bottom: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: _textController,
                    onChanged: (_) {},
                    fontFamily: 'InterTight',
                    fontWeight: FontWeight.w400,
                    fontSize: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${uiState.characterCount}',
                        style: TextStyle(
                          fontFamily: 'InterTight',
                          fontSize: 16,
                          color: appTheme.onBackground,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ButtonsSection extends StatelessWidget {
  const _ButtonsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(height: 10),
        PrimaryButton(
          text: TestPageLabels.primaryButton,
          icon: Icons.arrow_right_alt,
          iconSize: 40,
          onTap: () {},
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          text: TestPageLabels.secondaryButton,
          onTap: () {},
        ),
        const SizedBox(height: 10),
        TertiaryButton(
          text: TestPageLabels.tertiaryButton,
          center: false,
          onTap: () {},
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

