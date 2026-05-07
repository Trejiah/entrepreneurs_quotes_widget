import 'package:businessmindset/core/root_navigator.dart';
import 'package:businessmindset/features/onboarding/view/onboarding_shell_page.dart';
import 'package:businessmindset/features/settings/pages/widget/view/widget_page.dart';
import 'package:flutter/material.dart';

import '../features/home/view/home_page.dart';

/// Arborescence Material sous [MyApp] (MediaQuery + routes).
class MyAppMaterialShell extends StatelessWidget {
  final bool hasOnboard;

  const MyAppMaterialShell({super.key, required this.hasOnboard});

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.of(context).textScaler.clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.4,
        );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        debugShowCheckedModeBanner: false,
        home: hasOnboard ? HomePage() : OnboardingShellPage(),
        routes: {
          '/widget': (_) => const WidgetPage(fromWidget: true),
        },
      ),
    );
  }
}
