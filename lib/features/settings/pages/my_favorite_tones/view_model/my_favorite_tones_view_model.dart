import 'package:businessmindset/features/settings/pages/my_favorite_tones/view_model/my_favorite_tones_ui_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyFavoriteTonesViewModel extends StateNotifier<MyFavoriteTonesUiState> {
  MyFavoriteTonesViewModel(Ref ref) : super(const MyFavoriteTonesUiState());

  void setCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }

  void setToneValue(int toneIndex, int? value) {
    final next = List<int?>.from(state.selectedToneValues);
    if (toneIndex < 0 || toneIndex >= next.length) return;
    next[toneIndex] = value;
    state = state.copyWith(selectedToneValues: next);
  }
}

