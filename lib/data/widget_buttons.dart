class WidgetButtonOption {
  final String id;
  final String localizationKey;

  const WidgetButtonOption({
    required this.id,
    required this.localizationKey,
  });
}

const String widgetButtonNoneId = "none";
const String widgetButtonLikeId = "like";
const String widgetButtonShareId = "share";

const WidgetButtonOption widgetButtonNoneOption = WidgetButtonOption(
  id: widgetButtonNoneId,
  localizationKey: "widget_button_none",
);

const WidgetButtonOption widgetButtonLikeOption = WidgetButtonOption(
  id: widgetButtonLikeId,
  localizationKey: "widget_button_like",
);

const WidgetButtonOption widgetButtonShareOption = WidgetButtonOption(
  id: widgetButtonShareId,
  localizationKey: "widget_button_share",
);

const List<WidgetButtonOption> widgetButtonOptions = [
  widgetButtonNoneOption,
  widgetButtonLikeOption,
  widgetButtonShareOption,
];

const Set<String> defaultWidgetButtonSelection = {
  widgetButtonLikeId,
  widgetButtonShareId,
};

