import 'package:businessmindset/services/auth_sign.dart';
import 'package:businessmindset/services/mindset_points_service.dart';
import 'package:businessmindset/services/save_cloud.dart';
import 'package:businessmindset/features/onboarding/model/onboarding_outcomes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingAuthViewModel {
  const OnboardingAuthViewModel(this._ref);

  final WidgetRef _ref;

  Future<OnboardingAuthOutcome> loginAndLoadCloud() async {
    try {
      final UserCredential credential = await signInWithPlatform();
      final user = credential.user;

      if (user == null) {
        if (kDebugMode) {
          debugPrint('[Onboarding] Login failed: no user returned');
        }
        return OnboardingAuthOutcome.error;
      }

      final userFire = FirebaseAuth.instance.currentUser;
      if (userFire == null) return OnboardingAuthOutcome.error;

      final uid = userFire.uid;
      final databaseRef = FirebaseDatabase.instance.ref('users/$uid');
      final snapshot = await databaseRef.get();

      if (!snapshot.exists) {
        if (kDebugMode) {
          debugPrint('[Onboarding] No Firebase data found after login');
        }
        return OnboardingAuthOutcome.success;
      }

      MindsetPointsService.instance.disableSave();
      try {
        await loadAllCloud(_ref);
      } finally {
        MindsetPointsService.instance.enableSave();
      }
      return OnboardingAuthOutcome.success;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('[Onboarding] FirebaseAuthException: ${e.code} ${e.message}');
      }
      if (e.code == 'canceled' || e.code == 'popup-closed-by-user') {
        return OnboardingAuthOutcome.cancelled;
      }
      return OnboardingAuthOutcome.error;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Onboarding] loginAndLoadCloud error: $e');
      }
      return OnboardingAuthOutcome.error;
    }
  }
}
