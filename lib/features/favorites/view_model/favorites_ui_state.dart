import 'package:businessmindset/features/favorites/model/favorites_models.dart';

class FavoritesUiState {
  const FavoritesUiState({
    this.selectedTopics = const [],
    this.favoritesModified = false,
    this.isLoaded = false,
    this.topics = const [],
  });

  final List<String> selectedTopics;
  final bool favoritesModified;
  final bool isLoaded;
  final List<FavoriteTopicItem> topics;

  FavoritesUiState copyWith({
    List<String>? selectedTopics,
    bool? favoritesModified,
    bool? isLoaded,
    List<FavoriteTopicItem>? topics,
  }) {
    return FavoritesUiState(
      selectedTopics: selectedTopics ?? this.selectedTopics,
      favoritesModified: favoritesModified ?? this.favoritesModified,
      isLoaded: isLoaded ?? this.isLoaded,
      topics: topics ?? this.topics,
    );
  }
}
