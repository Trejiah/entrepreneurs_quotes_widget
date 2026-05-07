import 'package:businessmindset/features/settings/pages/my_favorite_tones/view_model/my_favorite_tones_ui_state.dart';
import 'package:businessmindset/features/settings/pages/my_favorite_tones/view_model/my_favorite_tones_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final myFavoriteTonesViewModelProvider = StateNotifierProvider.autoDispose<
    MyFavoriteTonesViewModel, MyFavoriteTonesUiState>(
  (ref) => MyFavoriteTonesViewModel(ref),
);

