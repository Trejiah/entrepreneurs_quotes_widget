import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:businessmindset/features/paywall/model/paywall_models.dart';
import 'package:businessmindset/features/paywall/view/paywallb_legacy.dart' as legacy;
import 'package:businessmindset/features/paywall/view_model/paywallb_provider.dart';

/// Point d’entrée MVVM : initialise [paywallbViewModelProvider] et délègue l’UI à la vue legacy.
class Paywallb extends ConsumerStatefulWidget {
  const Paywallb({
    super.key,
    required this.pageStyle,
    required this.backIcon,
    required this.skipLink,
    required this.title,
    required this.subTitle,
    required this.choiceList,
    this.backward,
    this.buttonText,
    this.forward1,
    this.forward2,
    this.variable,
    this.hardPaywallMode = false,
    this.onHardPaywallUnlocked,
  });

  final String pageStyle;
  final bool backIcon;
  final bool skipLink;
  final String title;
  final String subTitle;
  final List<String> choiceList;
  final VoidCallback? backward;
  final String? buttonText;
  final VoidCallback? forward1;
  final VoidCallback? forward2;
  final String? variable;

  final bool hardPaywallMode;
  final VoidCallback? onHardPaywallUnlocked;

  @override
  ConsumerState<Paywallb> createState() => _PaywallbPageState();
}

class _PaywallbPageState extends ConsumerState<Paywallb> {
  late final PaywallbInput _input;

  @override
  void initState() {
    super.initState();
    _input = PaywallbInput(
      pageStyle: widget.pageStyle,
      title: widget.title,
      subTitle: widget.subTitle,
      choiceList: widget.choiceList,
      backIcon: widget.backIcon,
      skipLink: widget.skipLink,
      hardPaywallMode: widget.hardPaywallMode,
      variable: widget.variable,
      buttonText: widget.buttonText,
    );

    Future.microtask(() async {
      await ref.read(paywallbViewModelProvider(_input).notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pour le moment, on délègue l'intégralité de l'UI existante à Paywallb.
    return legacy.Paywallb(
      paywallInput: _input,
      pageStyle: widget.pageStyle,
      backIcon: widget.backIcon,
      skipLink: widget.skipLink,
      title: widget.title,
      subTitle: widget.subTitle,
      choiceList: widget.choiceList,
      backward: widget.backward,
      buttonText: widget.buttonText,
      forward1: widget.forward1,
      forward2: widget.forward2,
      variable: widget.variable,
      hardPaywallMode: widget.hardPaywallMode,
      onHardPaywallUnlocked: widget.onHardPaywallUnlocked,
    );
  }
}

