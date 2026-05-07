import 'package:businessmindset/features/settings/pages/widget/view_model/widget_ui_state.dart';
import 'package:businessmindset/features/settings/pages/widget/view_model/widget_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final widgetViewModelProvider =
    StateNotifierProvider.autoDispose<WidgetViewModel, WidgetUiState>(
  (ref) => WidgetViewModel(ref),
);

