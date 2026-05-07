import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:businessmindset/features/home/view_model/home_quote_ui_state.dart';
import 'package:businessmindset/features/home/view_model/home_quote_view_model.dart';

final homeQuoteViewModelProvider =
    StateNotifierProvider<HomeQuoteNotifier, HomeQuoteUiState>((ref) {
  return HomeQuoteNotifier(ref);
});
