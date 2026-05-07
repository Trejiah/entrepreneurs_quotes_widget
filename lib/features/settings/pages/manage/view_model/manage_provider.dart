import 'package:businessmindset/features/settings/pages/manage/view_model/manage_ui_state.dart';
import 'package:businessmindset/features/settings/pages/manage/view_model/manage_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final manageViewModelProvider =
    StateNotifierProvider.autoDispose<ManageViewModel, ManageUiState>(
  (ref) => ManageViewModel(ref),
);

