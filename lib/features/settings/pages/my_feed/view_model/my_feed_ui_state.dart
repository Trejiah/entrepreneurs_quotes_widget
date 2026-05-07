class MyFeedUiState {
  const MyFeedUiState({
    required this.initialPercentages,
    required this.axisValues,
    required this.calculatedPercentages,
    required this.maxAxisValue,
    this.hasChanges = false,
    this.draggingPoint,
  });

  factory MyFeedUiState.initial() {
    const categoryKeys = ['growth', 'discipline', 'confidence', 'strategy'];
    final defaults = <String, double>{
      for (final key in categoryKeys) key: 25.0,
    };
    return MyFeedUiState(
      initialPercentages: defaults,
      axisValues: defaults,
      calculatedPercentages: defaults,
      maxAxisValue: 100.0,
    );
  }

  final Map<String, double> initialPercentages;
  final Map<String, double> axisValues;
  final Map<String, double> calculatedPercentages;
  final bool hasChanges;
  final String? draggingPoint;
  final double maxAxisValue;

  MyFeedUiState copyWith({
    Map<String, double>? initialPercentages,
    Map<String, double>? axisValues,
    Map<String, double>? calculatedPercentages,
    bool? hasChanges,
    Object? draggingPoint = _sentinel,
    double? maxAxisValue,
  }) {
    return MyFeedUiState(
      initialPercentages: initialPercentages ?? this.initialPercentages,
      axisValues: axisValues ?? this.axisValues,
      calculatedPercentages: calculatedPercentages ?? this.calculatedPercentages,
      hasChanges: hasChanges ?? this.hasChanges,
      draggingPoint:
          identical(draggingPoint, _sentinel) ? this.draggingPoint : draggingPoint as String?,
      maxAxisValue: maxAxisValue ?? this.maxAxisValue,
    );
  }
}

const _sentinel = Object();

