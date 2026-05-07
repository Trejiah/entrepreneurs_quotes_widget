import 'package:businessmindset/features/settings/pages/sigin/view_model/sigin_ui_state.dart';
import 'package:businessmindset/providers/user_provider.dart';
import 'package:businessmindset/services/auth_check.dart';
import 'package:businessmindset/services/auth_sign.dart';
import 'package:businessmindset/services/mindset_points_service.dart';
import 'package:businessmindset/services/save_cloud.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SiginViewModel extends StateNotifier<SiginUiState> {
  SiginViewModel(this._ref) : super(SiginUiState.initial());

  final Ref _ref;

  void refreshAuthState() {
    final auth = checkPlatformAuth();
    final premium = _ref.read(premiumProvider);
    final accountStatusKey = premium ? 'Premium' : 'Free account';

    if (auth.signedIn) {
      state = state.copyWith(
        signedIn: true,
        userSign: true,
        iconState: 'checked',
        email: auth.email ?? '',
        cloudSyncKey: premium ? 'enable' : 'signinto',
        accountStatusKey: accountStatusKey,
      );
    } else {
      state = state.copyWith(
        signedIn: false,
        userSign: false,
        iconState: 'close',
        email: '',
        cloudSyncKey: 'signinto',
        accountStatusKey: accountStatusKey,
      );
    }

    if (kDebugMode) {
      debugPrint('refresh');
    }
  }

  Future<void> syncCloudIfUserHasFirebaseData(WidgetRef widgetRef) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final uid = user.uid;
      final databaseRef = FirebaseDatabase.instance.ref('users/$uid');
      final snapshot = await databaseRef.get();

      if (snapshot.exists) {
        MindsetPointsService.instance.disableSave();

        if (kDebugMode) {
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          debugPrint("📥 [SignIn] Loading Firebase data...");
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        }

        try {
          await loadAllCloud(widgetRef);
          if (kDebugMode) {
            debugPrint("✅ [SignIn] Firebase data loaded successfully");
          }
        } finally {
          MindsetPointsService.instance.enableSave();
          if (kDebugMode) {
            debugPrint("▶️ [SignIn] Auto-save re-enabled");
            debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint("ℹ️ [SignIn] No Firebase data found - No auto-save");
        }
      }
    } catch (e) {
      debugPrint("remove account error: $e");
    }
  }

  Future<void> logOut() async {
    await signOutAll();
    refreshAuthState();
  }

  Future<void> deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final uid = user.uid;
      final userRef = FirebaseDatabase.instance.ref('users/$uid');
      await userRef.remove();
      await logOut();
    } catch (e) {
      debugPrint("remove account error: $e");
    }
  }

  Future<void> logIn(WidgetRef widgetRef) async {
    try {
      final credential = await signInWithPlatform();
      final user = credential.user;

      if (user != null) {
        if (kDebugMode) {
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          debugPrint("📋 [SignIn] Login successful");
          debugPrint("   - Email: ${user.email}");
          debugPrint("   - UID: ${user.uid}");
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        }

        await syncCloudIfUserHasFirebaseData(widgetRef);
        refreshAuthState();
      } else {
        if (kDebugMode) {
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          debugPrint("❌ [SignIn] Error: No user returned");
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        }
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("❌ [SignIn] Firebase Auth error");
        debugPrint("   Code: ${e.code}");
        debugPrint("   Message: ${e.message}");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("❌ [SignIn] Unknown error");
        debugPrint("   Message: $e");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      }
    }
  }
}
