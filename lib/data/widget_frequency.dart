class WidgetFrequencyOption {
  final String id;
  final String localizationKey;
  final bool requiresPremium;
  final String shortLocalizationKey;

  const WidgetFrequencyOption({
    required this.id,
    required this.localizationKey,
    required this.shortLocalizationKey,
    this.requiresPremium = false,
  });
}

const String defaultWidgetFrequencyId = "every_3_hours";

const WidgetFrequencyOption oncePerDayFrequency = WidgetFrequencyOption(
  id: "once_per_day",
  localizationKey: "freq_once_day",
  shortLocalizationKey: "freq_short_once_day",
);

const WidgetFrequencyOption twicePerDayFrequency = WidgetFrequencyOption(
  id: "twice_per_day",
  localizationKey: "freq_twice_day",
  shortLocalizationKey: "freq_short_twice_day",
);

const WidgetFrequencyOption everySixHoursFrequency = WidgetFrequencyOption(
  id: "every_6_hours",
  localizationKey: "freq_every_6_hours",
  shortLocalizationKey: "freq_short_every_6_hours",
);

const WidgetFrequencyOption everyThreeHoursFrequency = WidgetFrequencyOption(
  id: "every_3_hours",
  localizationKey: "freq_every_3_hours",
  shortLocalizationKey: "freq_short_every_3_hours",
);

const WidgetFrequencyOption everyHourFrequency = WidgetFrequencyOption(
  id: "every_hour",
  localizationKey: "freq_every_hour",
  shortLocalizationKey: "freq_short_every_hour",
);

const WidgetFrequencyOption twiceAnHourFrequency = WidgetFrequencyOption(
  id: "twice_per_hour",
  localizationKey: "freq_twice_hour",
  shortLocalizationKey: "freq_short_twice_hour",
);

const List<WidgetFrequencyOption> widgetFrequencyOptions = [
  oncePerDayFrequency,
  twicePerDayFrequency,
  everySixHoursFrequency,
  everyThreeHoursFrequency,
  everyHourFrequency,
  twiceAnHourFrequency,
];

