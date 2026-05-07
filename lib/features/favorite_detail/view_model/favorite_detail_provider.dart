import 'package:businessmindset/features/favorite_detail/model/favorite_detail_models.dart';
import 'package:businessmindset/features/favorite_detail/view_model/favorite_detail_ui_state.dart';
import 'package:businessmindset/features/favorite_detail/view_model/favorite_detail_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final favoriteDetailViewModelProvider = StateNotifierProvider.autoDispose
    .family<FavoriteDetailNotifier, FavoriteDetailUiState, FavoriteDetailInput>(
  (ref, input) {
    return FavoriteDetailNotifier(ref, input);
  },
);

