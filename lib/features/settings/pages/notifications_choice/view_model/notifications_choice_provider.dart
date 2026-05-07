import 'package:businessmindset/features/settings/pages/notifications_choice/view_model/notifications_choice_ui_state.dart';
import 'package:businessmindset/features/settings/pages/notifications_choice/view_model/notifications_choice_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationsChoiceViewModelProvider = StateNotifierProvider.autoDispose<
    NotificationsChoiceViewModel, NotificationsChoiceUiState>(
  (ref) => NotificationsChoiceViewModel(ref),
);

