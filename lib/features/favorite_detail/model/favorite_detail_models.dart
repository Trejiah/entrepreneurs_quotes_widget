/// Entrée immutable utilisée par le provider MVVM.
class FavoriteDetailInput {
  const FavoriteDetailInput({
    required this.pageStyle,
    required this.choiceList,
    this.variable,
  });

  final String pageStyle; // "search" ou autre (history)
  final List<String> choiceList;
  final String? variable;
}

