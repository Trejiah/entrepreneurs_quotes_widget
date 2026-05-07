import 'package:businessmindset/features/settings/pages/lockscreen_choice/view_model/lockscreen_choice_ui_state.dart';
import 'package:businessmindset/features/settings/pages/lockscreen_choice/view_model/lockscreen_choice_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final lockscreenChoiceViewModelProvider = StateNotifierProvider.autoDispose<
    LockscreenChoiceViewModel, LockscreenChoiceUiState>(
  (ref) => LockscreenChoiceViewModel(ref),
);

