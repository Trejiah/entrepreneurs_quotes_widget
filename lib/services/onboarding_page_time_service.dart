class OnboardingPageTimeService {
  OnboardingPageTimeService._();

  static DateTime? _openedAt;
  static int? _pageNumber;

  static void markPageOpened(int pageNumber) {
    _pageNumber = pageNumber;
    _openedAt = DateTime.now();
  }

  static DateTime? get openedAt => _openedAt;
  static int? get pageNumber => _pageNumber;
}
