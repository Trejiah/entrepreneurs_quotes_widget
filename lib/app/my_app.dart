import 'package:businessmindset/app/my_app_deep_link_coordinator.dart';
import 'package:businessmindset/app/my_app_lifecycle.dart';
import 'package:businessmindset/app/my_app_material_shell.dart';
import 'package:businessmindset/providers/cross_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends ConsumerStatefulWidget {
  final bool hasOnboard;
  const MyApp({super.key, required this.hasOnboard});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  late final MyAppDeepLinkCoordinator _deepLinks;

  @override
  void initState() {
    super.initState();
    ref.read(crossShowItemProvider);
    WidgetsBinding.instance.addObserver(this);
    _deepLinks = MyAppDeepLinkCoordinator(
      ref: ref,
      hasOnboard: () => widget.hasOnboard,
      isMounted: () => mounted,
    );
    _deepLinks.attachChannel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    MyAppLifecycle.handle(state, hasOnboard: widget.hasOnboard);
  }

  @override
  Widget build(BuildContext context) {
    return MyAppMaterialShell(hasOnboard: widget.hasOnboard);
  }
}
