import 'package:businessmindset/features/settings/pages/leave_message/view_model/leave_message_ui_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaveMessageViewModel extends StateNotifier<LeaveMessageUiState> {
  LeaveMessageViewModel() : super(const LeaveMessageUiState());

  void onMessageChanged(String value) {
    state = state.copyWith(message: value);
  }

  Future<void> sendMessage() async {
    // Placeholder volontaire: l'ancienne vue ne persistait pas encore le message.
  }
}

