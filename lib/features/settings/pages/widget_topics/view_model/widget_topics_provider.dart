import 'package:businessmindset/features/settings/pages/widget_topics/view_model/widget_topics_ui_state.dart';
import 'package:businessmindset/features/settings/pages/widget_topics/view_model/widget_topics_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final widgetTopicsViewModelProvider =
    StateNotifierProvider.autoDispose<WidgetTopicsViewModel, WidgetTopicsUiState>(
  (ref) => WidgetTopicsViewModel(ref),
);

