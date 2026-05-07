import 'package:businessmindset/features/settings/pages/choose_quote/view_model/choose_quote_ui_state.dart';
import 'package:businessmindset/features/settings/pages/choose_quote/view_model/choose_quote_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chooseQuoteViewModelProvider =
    StateNotifierProvider.autoDispose<ChooseQuoteViewModel, ChooseQuoteUiState>(
  (ref) => ChooseQuoteViewModel(ref),
);

