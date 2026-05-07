import 'package:businessmindset/features/settings/pages/widget_buttons/view_model/widget_buttons_ui_state.dart';
import 'package:businessmindset/features/settings/pages/widget_buttons/view_model/widget_buttons_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final widgetButtonsViewModelProvider = StateNotifierProvider.autoDispose<
    WidgetButtonsViewModel, WidgetButtonsUiState>(
  (ref) => WidgetButtonsViewModel(ref),
);

