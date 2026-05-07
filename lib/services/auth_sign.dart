// auth_login.dart
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';          // Android
import 'package:sign_in_with_apple/sign_in_with_apple.dart';   // iOS
import 'package:businessmindset/config/env.dart';
import 'revenuecat_service.dart';

/// =========================
/// Public API (use this)
/// =========================
/// Sign in according to platform:
/// - iOS  -> Apple
/// - Android -> Google
Future<UserCredential> signInWithPlatform() async {
  UserCredential credential;
  if (Platform.isIOS) {
    credential = await signInWithApple();
  } else if (Platform.isAndroid) {
    credential = await signInWithGoogle();
  } else {
    throw FirebaseAuthException(
      code: 'unsupported-platform',
      message: 'Plateforme non supportée pour ce flux de connexion.',
    );
  }

  final userId = credential.user?.uid;
  if (userId != null) {
    try {
      await RevenueCatService.instance.ensureConfigured(appUserId: userId);
    } catch (error) {
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("❌ [Auth] Error during RevenueCat configuration");
        debugPrint("   Message: $error");
        debugPrint("   UserId: $userId");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
    }
  }

  return credential;
}

/// Simple sign-out (Firebase + Google if Android)

Future<void> signOutAll() async {
  try {
    if (Platform.isAndroid) {
      final google = GoogleSignIn.instance;
      await google.initialize(); // obligatoire depuis v7+
      await google.signOut();    // déconnexion Google locale
    }

    // On iOS, nothing to do on the Apple side (just Firebase)
    await FirebaseAuth.instance.signOut();
    await RevenueCatService.instance.logOut();

    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("📋 [Auth] Sign-out successful");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("❌ [Auth] Sign-out error");
      debugPrint("   Message: $e");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
  }
}

/// =========================
/// iOS : Sign in with Apple
/// =========================

Future<UserCredential> signInWithApple() async {
  // 1) Nonce (Apple + Firebase recommend a nonce for security)
  final rawNonce = _generateNonce();
  final nonce = _sha256ofString(rawNonce);

  // 2) Lancer l'UI Apple
  final appleCred = await SignInWithApple.getAppleIDCredential(
    scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ],
    nonce: nonce, // important pour Firebase
  );

  // 🔍 Checking tokens received from Apple
  if (kDebugMode) {
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    debugPrint("🍎 [Apple] Tokens received");
    debugPrint("   identityToken length: ${appleCred.identityToken?.length ?? 0}");
    debugPrint("   authorizationCode length: ${appleCred.authorizationCode.length}");
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  }

  // 3) Build the Firebase credential
  final oauth = OAuthProvider("apple.com").credential(
    idToken: appleCred.identityToken,
    accessToken: appleCred.authorizationCode, // 👈 Nécessaire pour Firebase !
    rawNonce: rawNonce,
  );

  // 4) Sign in Firebase
  return FirebaseAuth.instance.signInWithCredential(oauth);
}

/// ==========================
/// Android : Google Sign-In
/// ==========================

Future<UserCredential> signInWithGoogle() async {
  final gsi = GoogleSignIn.instance;

  if (kDebugMode) {
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    debugPrint("🔐 [Google] Starting Android sign-in flow");
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  }

  // v7: initialization (on Android, serverClientId is required for idToken)
  final serverId = Env.googleAndroidServerClientId.trim();
  if (Platform.isAndroid && serverId.isEmpty && kDebugMode) {
    debugPrint(
      '[Auth] ⚠️ GOOGLE_ANDROID_SERVER_CLIENT_ID manquant — connexion Google Android peut échouer.',
    );
  }
  await gsi.initialize(
    serverClientId: Platform.isAndroid && serverId.isNotEmpty ? serverId : null,
    // clientId (iOS) is optional if nothing special to configure
  );

  try {
    // Try to reuse an existing session if present (optional)
    await gsi.attemptLightweightAuthentication();
    return _authenticateWithGoogleAndFirebase(gsi);
  } catch (error) {
    final shouldRetry = _isGoogleReauthFailure(error);
    if (!shouldRetry) rethrow;

    if (kDebugMode) {
      debugPrint("⚠️ [Google] Reauth failure detected, resetting session and retrying once");
      debugPrint("   Message: $error");
    }

    await _resetGoogleSession(gsi);
    return _authenticateWithGoogleAndFirebase(gsi);
  }
}

Future<UserCredential> _authenticateWithGoogleAndFirebase(GoogleSignIn gsi) async {
  // Open the Google account picker
  final account = await gsi.authenticate();

  if (kDebugMode) {
    debugPrint("📋 [Google] Account selected: ${account.email}");
  }

  // Retrieve the tokens (in v7 only idToken is exposed - enough for Firebase)
  final auth = account.authentication;

  // Pass the idToken to Firebase
  final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
  final firebaseCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

  if (kDebugMode) {
    debugPrint("✅ [Google] Firebase sign-in success: ${firebaseCredential.user?.uid}");
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  }

  return firebaseCredential;
}

bool _isGoogleReauthFailure(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('account reauth failed');
}

Future<void> _resetGoogleSession(GoogleSignIn gsi) async {
  try {
    await gsi.signOut();
  } catch (_) {
    // Ignore: no active Google session is fine.
  }
  try {
    await gsi.disconnect();
  } catch (_) {
    // Ignore: disconnect can fail if there is nothing to revoke.
  }
}

/// =========================
/// Helpers (nonce Apple)
/// =========================

String _generateNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final rand = Random.secure();
  return List.generate(length, (_) => charset[rand.nextInt(charset.length)])
      .join();
}

String _sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
