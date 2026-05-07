import 'package:businessmindset/features/settings/pages/cancel_sub/model/cancel_sub_models.dart';
import 'package:businessmindset/features/settings/pages/cancel_sub/view_model/cancel_sub_ui_state.dart';
import 'package:businessmindset/services/revenuecat_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CancelSubResult {
  const CancelSubResult({
    required this.success,
    this.error,
  });

  final bool success;
  final Object? error;
}

class CancelSubViewModel extends StateNotifier<CancelSubUiState> {
  CancelSubViewModel()
      : super(CancelSubUiState(
          isChecked: List<bool>.filled(kCancelReasonKeys.length, false),
        ));

  void toggleReason(int index) {
    if (index < 0 || index >= state.isChecked.length) return;
    final next = List<bool>.from(state.isChecked);
    next[index] = !next[index];
    state = state.copyWith(isChecked: next);
  }

  List<String> selectedReasonKeys() {
    final out = <String>[];
    for (int i = 0; i < kCancelReasonKeys.length; i++) {
      if (state.isChecked[i]) out.add(kCancelReasonKeys[i]);
    }
    return out;
  }

  Future<CancelSubResult> handleCancel() async {
    final cancelList = selectedReasonKeys();
    if (kDebugMode && cancelList.isNotEmpty) {
      debugPrint('[CANCEL SUBSCRIPTION] Reasons: $cancelList');
    }

    try {
      await RevenueCatService.instance.showManageSubscriptions();
      return const CancelSubResult(success: true);
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint(
          '[CANCEL SUBSCRIPTION ERROR] Failed to open manage subscriptions: $error',
        );
        debugPrint('$stack');
      }
      return CancelSubResult(success: false, error: error);
    }
  }
}

