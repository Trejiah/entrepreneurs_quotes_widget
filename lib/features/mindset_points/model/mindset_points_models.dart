class MindsetStatLabel {
  const MindsetStatLabel({
    required this.translationKey,
    required this.imageName,
  });

  final String translationKey;
  final String imageName;
}

const List<MindsetStatLabel> kMindsetStatLabels = [
  MindsetStatLabel(translationKey: 'Open', imageName: 'open.png'),
  MindsetStatLabel(translationKey: 'Like', imageName: 'like.png'),
  MindsetStatLabel(translationKey: 'Share', imageName: 'share.png'),
];
