import 'package:businessmindset/features/settings/pages/app_ordered_quotes/view_model/app_ordered_quotes_ui_state.dart';
import 'package:businessmindset/features/settings/pages/app_ordered_quotes/view_model/app_ordered_quotes_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appOrderedQuotesViewModelProvider = StateNotifierProvider.autoDispose<
    AppOrderedQuotesViewModel, AppOrderedQuotesUiState>(
  (ref) => AppOrderedQuotesViewModel(ref),
);

