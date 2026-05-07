import 'dart:math';

import 'package:businessmindset/features/mindset_points/view_model/mindset_points_ui_state.dart';
import 'package:businessmindset/models/motiv_model.dart';
import 'package:businessmindset/services/mindset_points_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MindsetPointsNotifier extends StateNotifier<MindsetPointsUiState> {
  MindsetPointsNotifier() : super(const MindsetPointsUiState());

  static const double kMinVelX = 650;

  Future<void> loadPrefs({required String lang}) async {
    final prefs = await SharedPreferences.getInstance();
    final values = await MindsetPointsService.instance.getAllValues();

    final openAllPoints = values['openAllPoints'] ?? 1;
    final likeAllPoints = values['likeAllPoints'] ?? 0;
    final shareAllPoints = values['shareAllPoints'] ?? 0;
    final openTodayPoints = values['openTodayPoints'] ?? 1;
    final likeTodayPoints = values['likeTodayPoints'] ?? 0;
    final shareTodayPoints = values['shareTodayPoints'] ?? 0;
    final openWeekPoints = values['openWeekPoints'] ?? 1;
    final likeWeekPoints = values['likeWeekPoints'] ?? 0;
    final shareWeekPoints = values['shareWeekPoints'] ?? 0;
    final totDays = values['totDays'] ?? 3;
    final todayTotQuotes = values['todayTotQuotes'] ?? 1;
    final weekTotQuotes = values['weekTotQuotes'] ?? 1;
    final allTotQuotes = values['allTotQuotes'] ?? 1;

    final now = DateTime.now();
    final todayStr = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final savedDate = prefs.getString('todayQuoteDate');

    String dayQuote = '';
    String weekQuote = '';
    String allQuote = '';

    if (savedDate == todayStr) {
      dayQuote = prefs.getString('dayQuote') ?? '';
      weekQuote = prefs.getString('weekQuote') ?? '';
      allQuote = prefs.getString('allQuote') ?? '';
    } else {
      String pick(String bucket) {
        final list = motivTot[bucket];
        if (list == null || list.isEmpty) return '';
        final item = list[Random().nextInt(list.length)];
        return item[lang] ?? item['en'] ?? '';
      }

      dayQuote = pick('today');
      weekQuote = pick('week');
      allQuote = pick('all');

      await prefs.setString('dayQuote', dayQuote);
      await prefs.setString('weekQuote', weekQuote);
      await prefs.setString('allQuote', allQuote);
      await prefs.setString('todayQuoteDate', todayStr);
    }

    final valueList = [
      [openTodayPoints, likeTodayPoints, shareTodayPoints],
      [openWeekPoints, likeWeekPoints, shareWeekPoints],
      [openAllPoints, likeAllPoints, shareAllPoints],
    ];
    final totList = [
      openTodayPoints + likeTodayPoints + shareTodayPoints,
      openWeekPoints + likeWeekPoints + shareWeekPoints,
      openAllPoints + likeAllPoints + shareAllPoints,
    ];

    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📋 [MindsetPoints] Loading values');
      debugPrint('   - openAllPoints: $openAllPoints');
      debugPrint('   - likeAllPoints: $likeAllPoints');
      debugPrint('   - shareAllPoints: $shareAllPoints');
      debugPrint('   - openTodayPoints: $openTodayPoints');
      debugPrint('   - likeTodayPoints: $likeTodayPoints');
      debugPrint('   - shareTodayPoints: $shareTodayPoints');
      debugPrint('   - openWeekPoints: $openWeekPoints');
      debugPrint('   - likeWeekPoints: $likeWeekPoints');
      debugPrint('   - shareWeekPoints: $shareWeekPoints');
      debugPrint('   - totDays: $totDays');
      debugPrint('   - todayTotQuotes: $todayTotQuotes');
      debugPrint('   - weekTotQuotes: $weekTotQuotes');
      debugPrint('   - allTotQuotes: $allTotQuotes');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    state = state.copyWith(
      openAllPoints: openAllPoints,
      likeAllPoints: likeAllPoints,
      shareAllPoints: shareAllPoints,
      openTodayPoints: openTodayPoints,
      likeTodayPoints: likeTodayPoints,
      shareTodayPoints: shareTodayPoints,
      openWeekPoints: openWeekPoints,
      likeWeekPoints: likeWeekPoints,
      shareWeekPoints: shareWeekPoints,
      totDays: totDays,
      todayTotQuotes: todayTotQuotes,
      weekTotQuotes: weekTotQuotes,
      allTotQuotes: allTotQuotes,
      quoteList: [todayTotQuotes, weekTotQuotes, allTotQuotes],
      motivList: [dayQuote, weekQuote, allQuote],
      valueList: valueList,
      totList: totList,
      hasLoaded: true,
    );
  }

  void onHorizontalDragStart() {
    state = state.copyWith(horizontalDragDistance: 0.0);
  }

  void onHorizontalDragUpdate({
    required double primaryDelta,
    required bool fromOnboarding,
  }) {
    if (fromOnboarding && primaryDelta > 0) {
      return;
    }
    state = state.copyWith(
      horizontalDragDistance: state.horizontalDragDistance + primaryDelta,
    );
  }

  bool showFinalMaskAndTrack() {
    if (state.showFinalMask) return false;
    state = state.copyWith(showFinalMask: true);
    return true;
  }

  bool onHorizontalDragEnd({
    required double velocityX,
    required double screenWidth,
    required bool fromOnboarding,
  }) {
    final kMinDx = (screenWidth * 0.18).clamp(80.0, 160.0);
    final flingLeft = velocityX <= -kMinVelX;
    final flingRight = velocityX >= kMinVelX;
    final farLeft = state.horizontalDragDistance <= -kMinDx;
    final farRight = state.horizontalDragDistance >= kMinDx;

    int dir = 0;
    if (flingLeft || farLeft) dir = -1;
    if (flingRight || farRight) dir = 1;

    state = state.copyWith(horizontalDragDistance: 0.0);

    if (fromOnboarding && dir == -1) {
      return showFinalMaskAndTrack();
    }
    if (fromOnboarding && dir == 1) {
      return false;
    }
    if (dir == 0) {
      return false;
    }

    final period = state.period;
    if (dir == 1 && period == 0) return false;
    if (dir == -1 && period == 2) return false;

    final nextPeriod = dir == -1
        ? (period + 1).clamp(0, 2)
        : (period - 1).clamp(0, 2);
    state = state.copyWith(period: nextPeriod);
    return false;
  }

  bool setPeriod(int period, {required bool fromOnboarding}) {
    if (fromOnboarding) return false;
    state = state.copyWith(period: period.clamp(0, 2));
    return true;
  }
}
