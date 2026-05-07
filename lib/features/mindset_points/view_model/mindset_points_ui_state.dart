import 'package:businessmindset/features/mindset_points/model/mindset_points_models.dart';

class MindsetPointsUiState {
  const MindsetPointsUiState({
    this.period = 0,
    this.openTodayPoints = 1,
    this.likeTodayPoints = 0,
    this.shareTodayPoints = 0,
    this.openWeekPoints = 1,
    this.likeWeekPoints = 0,
    this.shareWeekPoints = 0,
    this.openAllPoints = 1,
    this.likeAllPoints = 0,
    this.shareAllPoints = 0,
    this.todayTotQuotes = 1,
    this.weekTotQuotes = 1,
    this.allTotQuotes = 1,
    this.totDays = 1,
    this.motivList = const ['', '', ''],
    this.quoteList = const [1, 1, 1],
    this.valueList = const [
      [1, 0, 0],
      [1, 0, 0],
      [1, 0, 0],
    ],
    this.totList = const [1, 1, 1],
    this.horizontalDragDistance = 0.0,
    this.showFinalMask = false,
    this.hasLoaded = false,
    this.labels = kMindsetStatLabels,
  });

  final int period;
  final int openTodayPoints;
  final int likeTodayPoints;
  final int shareTodayPoints;
  final int openWeekPoints;
  final int likeWeekPoints;
  final int shareWeekPoints;
  final int openAllPoints;
  final int likeAllPoints;
  final int shareAllPoints;
  final int todayTotQuotes;
  final int weekTotQuotes;
  final int allTotQuotes;
  final int totDays;
  final List<String> motivList;
  final List<int> quoteList;
  final List<List<int>> valueList;
  final List<int> totList;
  final double horizontalDragDistance;
  final bool showFinalMask;
  final bool hasLoaded;
  final List<MindsetStatLabel> labels;

  MindsetPointsUiState copyWith({
    int? period,
    int? openTodayPoints,
    int? likeTodayPoints,
    int? shareTodayPoints,
    int? openWeekPoints,
    int? likeWeekPoints,
    int? shareWeekPoints,
    int? openAllPoints,
    int? likeAllPoints,
    int? shareAllPoints,
    int? todayTotQuotes,
    int? weekTotQuotes,
    int? allTotQuotes,
    int? totDays,
    List<String>? motivList,
    List<int>? quoteList,
    List<List<int>>? valueList,
    List<int>? totList,
    double? horizontalDragDistance,
    bool? showFinalMask,
    bool? hasLoaded,
    List<MindsetStatLabel>? labels,
  }) {
    return MindsetPointsUiState(
      period: period ?? this.period,
      openTodayPoints: openTodayPoints ?? this.openTodayPoints,
      likeTodayPoints: likeTodayPoints ?? this.likeTodayPoints,
      shareTodayPoints: shareTodayPoints ?? this.shareTodayPoints,
      openWeekPoints: openWeekPoints ?? this.openWeekPoints,
      likeWeekPoints: likeWeekPoints ?? this.likeWeekPoints,
      shareWeekPoints: shareWeekPoints ?? this.shareWeekPoints,
      openAllPoints: openAllPoints ?? this.openAllPoints,
      likeAllPoints: likeAllPoints ?? this.likeAllPoints,
      shareAllPoints: shareAllPoints ?? this.shareAllPoints,
      todayTotQuotes: todayTotQuotes ?? this.todayTotQuotes,
      weekTotQuotes: weekTotQuotes ?? this.weekTotQuotes,
      allTotQuotes: allTotQuotes ?? this.allTotQuotes,
      totDays: totDays ?? this.totDays,
      motivList: motivList ?? this.motivList,
      quoteList: quoteList ?? this.quoteList,
      valueList: valueList ?? this.valueList,
      totList: totList ?? this.totList,
      horizontalDragDistance:
          horizontalDragDistance ?? this.horizontalDragDistance,
      showFinalMask: showFinalMask ?? this.showFinalMask,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      labels: labels ?? this.labels,
    );
  }
}
