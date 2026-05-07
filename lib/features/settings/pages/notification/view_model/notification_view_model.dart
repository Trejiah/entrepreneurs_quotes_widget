import 'package:businessmindset/features/settings/pages/notification/view_model/notification_ui_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationViewModel extends StateNotifier<NotificationUiState> {
  NotificationViewModel(Ref ref) : super(const NotificationUiState());

  void setManyCount(int value) {
    state = state.copyWith(manyCount: value);
  }
}

