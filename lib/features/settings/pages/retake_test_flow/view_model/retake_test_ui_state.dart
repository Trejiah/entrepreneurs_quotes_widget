class RetakeTestUiState {
  const RetakeTestUiState({
    this.currentPage = 0,
    this.situation,
    this.improvement = const [],
    this.mainfocus = const [],
    this.bigchall = const [],
    this.topics = const [],
    this.goals,
    this.planPercentages = const {},
    this.initialValuesLoaded = false,
  });

  static const int maxPages = 10;

  final int currentPage;
  final String? situation;
  final List<String> improvement;
  final List<String> mainfocus;
  final List<String> bigchall;
  final List<String> topics;
  final String? goals;
  final Map<String, double> planPercentages;
  final bool initialValuesLoaded;

  RetakeTestUiState copyWith({
    int? currentPage,
    Object? situation = _unset,
    List<String>? improvement,
    List<String>? mainfocus,
    List<String>? bigchall,
    List<String>? topics,
    Object? goals = _unset,
    Map<String, double>? planPercentages,
    bool? initialValuesLoaded,
  }) {
    return RetakeTestUiState(
      currentPage: currentPage ?? this.currentPage,
      situation: identical(situation, _unset) ? this.situation : situation as String?,
      improvement: improvement ?? this.improvement,
      mainfocus: mainfocus ?? this.mainfocus,
      bigchall: bigchall ?? this.bigchall,
      topics: topics ?? this.topics,
      goals: identical(goals, _unset) ? this.goals : goals as String?,
      planPercentages: planPercentages ?? this.planPercentages,
      initialValuesLoaded: initialValuesLoaded ?? this.initialValuesLoaded,
    );
  }
}

const Object _unset = Object();
