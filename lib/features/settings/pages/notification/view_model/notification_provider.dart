import 'package:businessmindset/features/settings/pages/notification/view_model/notification_ui_state.dart';
import 'package:businessmindset/features/settings/pages/notification/view_model/notification_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationViewModelProvider =
    StateNotifierProvider.autoDispose<NotificationViewModel, NotificationUiState>(
  (ref) => NotificationViewModel(ref),
);

