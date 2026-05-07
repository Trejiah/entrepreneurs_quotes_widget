class SiginUiState {
  const SiginUiState({
    required this.signedIn,
    required this.userSign,
    this.email = '',
    required this.accountStatusKey,
    required this.cloudSyncKey,
    required this.iconState,
  });

  factory SiginUiState.initial() {
    return const SiginUiState(
      signedIn: false,
      userSign: false,
      email: '',
      accountStatusKey: 'Free account',
      cloudSyncKey: 'signinto',
      iconState: 'close',
    );
  }

  final bool signedIn;
  final bool userSign;
  final String email;
  /// Passed to `translate` as subtitle key (legacy: `"Premium"` or `"Free account"`).
  final String accountStatusKey;
  /// `"signinto"` | `"enable"` for `translate`.
  final String cloudSyncKey;
  /// `"close"` | `"checked"` for icon vs translate branch in UI.
  final String iconState;

  SiginUiState copyWith({
    bool? signedIn,
    bool? userSign,
    String? email,
    String? accountStatusKey,
    String? cloudSyncKey,
    String? iconState,
  }) {
    return SiginUiState(
      signedIn: signedIn ?? this.signedIn,
      userSign: userSign ?? this.userSign,
      email: email ?? this.email,
      accountStatusKey: accountStatusKey ?? this.accountStatusKey,
      cloudSyncKey: cloudSyncKey ?? this.cloudSyncKey,
      iconState: iconState ?? this.iconState,
    );
  }
}
