import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/paywall_models.dart';
import 'paywallb_ui_state.dart';
import 'paywallb_view_model.dart';

final paywallbViewModelProvider = StateNotifierProvider.autoDispose
    .family<PaywallbViewModel, PaywallbUiState, PaywallbInput>(
  (ref, input) => PaywallbViewModel(ref, input),
);

