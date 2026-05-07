import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';

class PlatformAuthResult {
  final bool signedIn;
  final String? email;
  const PlatformAuthResult({required this.signedIn, required this.email});
}

PlatformAuthResult checkPlatformAuth() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const PlatformAuthResult(signedIn: false, email: "");
  }

  final isApple = Platform.isIOS;     // ✅ iPhone / iPad
  final isAndroid = Platform.isAndroid; // ✅ Android phones

  final providers = user.providerData.map((p) => p.providerId).toSet();

  if (isApple) {
    final ok = providers.contains('apple.com');
    return PlatformAuthResult(signedIn: ok, email: ok ? user.email : "");
  }

  if (isAndroid) {
    final ok = providers.contains('google.com');
    return PlatformAuthResult(signedIn: ok, email: ok ? user.email : "");
  }

  // fallback (rare, ex: tests)
  return PlatformAuthResult(signedIn: true, email: user.email);
}
