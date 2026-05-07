import 'package:businessmindset/models/topics.dart';

class FavoriteTopicItem {
  const FavoriteTopicItem({
    required this.id,
    required this.labelKey,
  });

  final String id;
  final String labelKey;
}

const Set<String> kFreeFavoriteTopicIds = {
  'favoritesquotes',
  'general',
  'resilience',
  'vispurp',
};

List<FavoriteTopicItem> buildFavoriteTopicsList() {
  final topics = <FavoriteTopicItem>[
    const FavoriteTopicItem(
      id: personalizedFeedTopicId,
      labelKey: 'personalized_feed',
    ),
    const FavoriteTopicItem(
      id: 'favoritesquotes',
      labelKey: 'Favoritesquotes',
    ),
    const FavoriteTopicItem(
      id: 'general',
      labelKey: 'General',
    ),
  ];

  for (final topicId in topicList) {
    topics.add(FavoriteTopicItem(id: topicId, labelKey: topicId));
  }

  topics.addAll(const [
    FavoriteTopicItem(id: 'no_mercy', labelKey: 'no_mercy'),
    FavoriteTopicItem(id: 'affirmative', labelKey: 'affirmative'),
  ]);

  return topics;
}
