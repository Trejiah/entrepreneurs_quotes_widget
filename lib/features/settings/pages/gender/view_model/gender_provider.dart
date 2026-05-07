import 'package:businessmindset/features/settings/pages/gender/view_model/gender_ui_state.dart';
import 'package:businessmindset/features/settings/pages/gender/view_model/gender_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final genderViewModelProvider =
    StateNotifierProvider.autoDispose<GenderViewModel, GenderUiState>(
  (ref) => GenderViewModel(ref),
);

