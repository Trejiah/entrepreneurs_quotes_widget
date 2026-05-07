import 'package:businessmindset/features/favorites/view_model/favorites_ui_state.dart';
import 'package:businessmindset/features/favorites/view_model/favorites_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final favoritesViewModelProvider =
    StateNotifierProvider.autoDispose<FavoritesNotifier, FavoritesUiState>((
      ref,
    ) {
      return FavoritesNotifier();
    });
