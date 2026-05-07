

class TopicDefinition {
  final String id;
  final String localizationKey;
  final bool requiresPremium;
  final bool isGeneral;
  final bool isFavorites;

  const TopicDefinition({
    required this.id,
    required this.localizationKey,
    this.requiresPremium = true,
    this.isGeneral = false,
    this.isFavorites = false,
  });
}

const TopicDefinition generalTopicDefinition = TopicDefinition(
  id: "general",
  localizationKey: "General",
  requiresPremium: false,
  isGeneral: true,
);

const TopicDefinition favoritesTopicDefinition = TopicDefinition(
  id: "favoritesquotes",
  localizationKey: "Favoritesquotes",
  requiresPremium: true,
  isFavorites: true,
);

/// Special topic for "My personalized feed"
const String personalizedFeedTopicId = "personalized_feed";

const TopicDefinition personalizedFeedTopicDefinition = TopicDefinition(
  id: personalizedFeedTopicId,
  localizationKey: "personalized_feed",
  requiresPremium: true,
);

const TopicDefinition noMercyTopicDefinition = TopicDefinition(
  id: "no_mercy",
  localizationKey: "no_mercy",
  requiresPremium: true,
);

const TopicDefinition affirmativeTopicDefinition = TopicDefinition(
  id: "affirmative",
  localizationKey: "affirmative",
  requiresPremium: true,
);

List<String> topicList = [
  "confmind",
  "focdic",
  "resilience",
  "vispurp",
  "entrepreneurship",
  "leadership",
  "salebranding",
  "growsucces",
  "wealthmoney",
  "womenemp",
  "businessic",
  "frombook",
];

final List<TopicDefinition> quoteTopicDefinitions = topicList
    .map(
      (id) => TopicDefinition(
        id: id,
        localizationKey: id,
        requiresPremium: true,
      ),
    )
    .toList(growable: false);

final List<TopicDefinition> widgetTopicDefinitions = [
  personalizedFeedTopicDefinition,
  generalTopicDefinition,
  favoritesTopicDefinition,
  ...quoteTopicDefinitions,
  noMercyTopicDefinition,
  affirmativeTopicDefinition,
];

// Icon mapping for each topic (for now, all use favoriteplain.png)
Map<String, String> topicIconMap = {
  "general": "general",
  "favoritesquotes": "favoritegold",
  "confmind": "confmind",
  "focdic": "focusconf",
  "resilience": "resill",
  "vispurp": "visetpurp",
  "entrepreneurship": "entrepre",
  "leadership": "leadersh",
  "salebranding": "brand",
  "growsucces": "growscc",
  "wealthmoney": "money",
  "womenemp": "women",
  "businessic": "businico",
  "frombook": "frombook",
  "no_mercy": "no_mercy",
  "affirmative": "affirmations",
};