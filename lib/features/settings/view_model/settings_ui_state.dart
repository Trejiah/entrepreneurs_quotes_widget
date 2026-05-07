/// État UI de l’écran Réglages.
class SettingsUiState {
  const SettingsUiState({
    this.appVersion = '1.0.0',
    this.buildNumber = '',
  });

  final String appVersion;
  final String buildNumber;

  SettingsUiState copyWith({
    String? appVersion,
    String? buildNumber,
  }) {
    return SettingsUiState(
      appVersion: appVersion ?? this.appVersion,
      buildNumber: buildNumber ?? this.buildNumber,
    );
  }
}
