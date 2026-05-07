import 'package:businessmindset/features/settings/pages/my_feed/view_model/my_feed_ui_state.dart';
import 'package:businessmindset/features/settings/pages/my_feed/view_model/my_feed_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final myFeedViewModelProvider =
    StateNotifierProvider.autoDispose<MyFeedViewModel, MyFeedUiState>(
  (ref) => MyFeedViewModel(ref),
);

