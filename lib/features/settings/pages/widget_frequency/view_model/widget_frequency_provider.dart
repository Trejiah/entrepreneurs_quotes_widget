import 'package:businessmindset/features/settings/pages/widget_frequency/view_model/widget_frequency_ui_state.dart';
import 'package:businessmindset/features/settings/pages/widget_frequency/view_model/widget_frequency_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final widgetFrequencyViewModelProvider = StateNotifierProvider.autoDispose<
    WidgetFrequencyViewModel, WidgetFrequencyUiState>(
  (ref) => WidgetFrequencyViewModel(ref),
);

