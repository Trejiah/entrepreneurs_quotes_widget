import 'package:businessmindset/features/mindset_points/view_model/mindset_points_ui_state.dart';
import 'package:businessmindset/features/mindset_points/view_model/mindset_points_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mindsetPointsViewModelProvider = StateNotifierProvider.autoDispose<
    MindsetPointsNotifier, MindsetPointsUiState>((ref) {
  return MindsetPointsNotifier();
});
