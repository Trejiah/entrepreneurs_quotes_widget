import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_draft_repository.dart';

final onboardingDraftRepositoryProvider = Provider<OnboardingDraftRepository>(
  (ref) => OnboardingDraftRepository(),
);
