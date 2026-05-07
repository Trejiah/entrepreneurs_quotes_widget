import 'package:businessmindset/app/globals/app_theme_globals.dart';
import 'package:businessmindset/core/global_scaler.dart';
import 'package:businessmindset/features/settings/pages/notification_debug/view_model/notification_debug_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationDebugPage extends ConsumerWidget {
  const NotificationDebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xFact = ScreenScale.x;
    final yFact = ScreenScale.y;
    final ui = ref.watch(notificationDebugViewModelProvider);
    final vm = ref.read(notificationDebugViewModelProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: appTheme.background),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20 * xFact),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      'Debug Notifications',
                      style: TextStyle(
                        fontFamily: 'YesevaOne',
                        color: appTheme.onBackground,
                        fontSize: 28 * xFact,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30 * yFact),
                ElevatedButton(
                  onPressed: vm.checkNotifications,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.secButton,
                    padding: EdgeInsets.symmetric(
                      horizontal: 30 * xFact,
                      vertical: 15 * yFact,
                    ),
                  ),
                  child: Text(
                    'Verifier les notifications',
                    style: TextStyle(
                      color: appTheme.onBackground,
                      fontSize: 16 * xFact,
                      fontFamily: 'InterTight',
                    ),
                  ),
                ),
                SizedBox(height: 10 * yFact),
                ElevatedButton(
                  onPressed: vm.testNotificationNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.onPrimButton,
                    padding: EdgeInsets.symmetric(
                      horizontal: 30 * xFact,
                      vertical: 15 * yFact,
                    ),
                  ),
                  child: Text(
                    'Test notification (dans 1 min)',
                    style: TextStyle(
                      color: appTheme.onPrimButton,
                      fontSize: 16 * xFact,
                      fontFamily: 'InterTight',
                    ),
                  ),
                ),
                SizedBox(height: 30 * yFact),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(15 * xFact),
                    decoration: BoxDecoration(
                      color: appTheme.secButton.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10 * xFact),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        ui.debugInfo,
                        style: TextStyle(
                          color: appTheme.onBackground,
                          fontSize: 14 * xFact,
                          fontFamily: 'Courier',
                          height: 1.5,
                        ),
                      ),
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

