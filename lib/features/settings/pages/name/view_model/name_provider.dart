import 'package:businessmindset/features/settings/pages/name/view_model/name_ui_state.dart';
import 'package:businessmindset/features/settings/pages/name/view_model/name_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nameViewModelProvider =
    StateNotifierProvider.autoDispose<NameViewModel, NameUiState>(
  (ref) => NameViewModel(ref),
);

