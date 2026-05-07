import 'package:businessmindset/features/settings/pages/cancel_sub/view_model/cancel_sub_ui_state.dart';
import 'package:businessmindset/features/settings/pages/cancel_sub/view_model/cancel_sub_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cancelSubViewModelProvider =
    StateNotifierProvider.autoDispose<CancelSubViewModel, CancelSubUiState>(
  (ref) => CancelSubViewModel(),
);

