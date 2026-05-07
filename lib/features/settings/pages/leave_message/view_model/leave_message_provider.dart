import 'package:businessmindset/features/settings/pages/leave_message/view_model/leave_message_ui_state.dart';
import 'package:businessmindset/features/settings/pages/leave_message/view_model/leave_message_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final leaveMessageViewModelProvider = StateNotifierProvider.autoDispose<
    LeaveMessageViewModel, LeaveMessageUiState>(
  (ref) => LeaveMessageViewModel(),
);

