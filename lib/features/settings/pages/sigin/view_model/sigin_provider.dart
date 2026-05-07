import 'package:businessmindset/features/settings/pages/sigin/view_model/sigin_ui_state.dart';
import 'package:businessmindset/features/settings/pages/sigin/view_model/sigin_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final siginViewModelProvider =
    StateNotifierProvider.autoDispose<SiginViewModel, SiginUiState>(
  (ref) => SiginViewModel(ref),
);
