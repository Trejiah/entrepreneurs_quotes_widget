import 'package:businessmindset/data/widget_buttons.dart';
import 'package:businessmindset/data/widget_frequency.dart';

class WidgetUiState {
  const WidgetUiState({
    this.selectedTheme = "App theme",
    this.selectedTopicIds = const {"general"},
    this.selectedFrequencyId = defaultWidgetFrequencyId,
    this.selectedButtonIds = defaultWidgetButtonSelection,
    this.widgetThemeIndex = 0,
    this.widgetIsCustomTheme = false,
    this.widgetThemeDisplayNames = const [],
  });

  final String selectedTheme;
  final Set<String> selectedTopicIds;
  final String selectedFrequencyId;
  final Set<String> selectedButtonIds;
  final int widgetThemeIndex;
  final bool widgetIsCustomTheme;
  final List<String> widgetThemeDisplayNames;

  WidgetUiState copyWith({
    String? selectedTheme,
    Set<String>? selectedTopicIds,
    String? selectedFrequencyId,
    Set<String>? selectedButtonIds,
    int? widgetThemeIndex,
    bool? widgetIsCustomTheme,
    List<String>? widgetThemeDisplayNames,
  }) {
    return WidgetUiState(
      selectedTheme: selectedTheme ?? this.selectedTheme,
      selectedTopicIds: selectedTopicIds ?? this.selectedTopicIds,
      selectedFrequencyId: selectedFrequencyId ?? this.selectedFrequencyId,
      selectedButtonIds: selectedButtonIds ?? this.selectedButtonIds,
      widgetThemeIndex: widgetThemeIndex ?? this.widgetThemeIndex,
      widgetIsCustomTheme: widgetIsCustomTheme ?? this.widgetIsCustomTheme,
      widgetThemeDisplayNames: widgetThemeDisplayNames ?? this.widgetThemeDisplayNames,
    );
  }
}

