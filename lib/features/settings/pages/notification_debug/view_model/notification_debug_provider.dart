import 'package:businessmindset/features/settings/pages/notification_debug/view_model/notification_debug_ui_state.dart';
import 'package:businessmindset/features/settings/pages/notification_debug/view_model/notification_debug_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationDebugViewModelProvider = StateNotifierProvider.autoDispose<
    NotificationDebugViewModel, NotificationDebugUiState>(
  (ref) => NotificationDebugViewModel(ref),
);

