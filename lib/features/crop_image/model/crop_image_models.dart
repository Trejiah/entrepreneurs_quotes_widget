class CropImageConfig {
  const CropImageConfig({
    required this.imagePath,
    this.aspectRatio = 1064 / 498,
    this.initialSize = 0.8,
  });

  final String imagePath;
  final double aspectRatio;
  final double initialSize;
}

