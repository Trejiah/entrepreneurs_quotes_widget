import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:businessmindset/features/settings/model/settings_models.dart';
import 'package:businessmindset/features/settings/model/settings_outcome.dart';
import 'package:businessmindset/features/settings/view_model/settings_ui_state.dart';

class SettingsNotifier extends StateNotifier<SettingsUiState> {
  SettingsNotifier() : super(const SettingsUiState());

  SettingsOutcome outcomeFor(SettingAction action, {required bool premium}) {
    return outcomeForSettingAction(action, premium: premium);
  }

  Future<void> loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    state = state.copyWith(
      appVersion: info.version,
      buildNumber: info.buildNumber,
    );
  }

  Future<void> openContactMail() async {
    const recipient = 'businessmindset.app@gmail.com';
    const subject = 'Feedback - Business Mindset';

    final mailUrl = Uri(
      scheme: 'mailto',
      path: recipient,
      queryParameters: {'subject': subject},
    ).toString();

    if (!await launchUrlString(mailUrl, mode: LaunchMode.externalApplication)) {
      if (kDebugMode) {
        debugPrint('[Settings] Unable to open mail app');
      }
    }
  }

  Future<void> shareApp({
    required String lang,
    Rect? sharePositionOrigin,
  }) async {
    const appName = 'Business Mindset';
    const playUrl =
        'https://play.google.com/store/apps/details?id=com.bakemono.businessmindset';
    const appStoreUrl =
        'https://apps.apple.com/us/app/business-mindset-quotes/id6754601387';

    final storeUrl = Platform.isIOS ? appStoreUrl : playUrl;

    final msgFr =
        'Salut ! Jette un œil à cette application pour rester focus sur tes objectifs business : \n$storeUrl';
    final msgEn =
        'Hey there! Check out this app for staying focused on your business goals: \n$storeUrl';

    final text = (lang == 'fr') ? msgFr : msgEn;

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        title: appName,
        subject: appName,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  Future<void> openStoreForReview() async {
    const androidPackage = 'com.bakemono.businessmindset';
    const iosAppId = '6754601387';

    final url = Platform.isIOS
        ? 'https://apps.apple.com/app/id$iosAppId?action=write-review'
        : 'https://play.google.com/store/apps/details?id=$androidPackage';

    if (!await launchUrlString(url, mode: LaunchMode.externalApplication)) {
      if (kDebugMode) {
        debugPrint('[Settings] Unable to open store: $url');
      }
    }
  }

  Future<void> openPrivacyPage() async {
    const url = 'https://landing-business-mindset.web.app/privacy.html';
    if (!await launchUrlString(url, mode: LaunchMode.externalApplication)) {
      if (kDebugMode) {
        debugPrint('[Settings] Unable to open privacy: $url');
      }
    }
  }

  Future<void> openTermsPage() async {
    const url = 'https://landing-business-mindset.web.app/terms.html';
    if (!await launchUrlString(url, mode: LaunchMode.externalApplication)) {
      if (kDebugMode) {
        debugPrint('[Settings] Unable to open terms: $url');
      }
    }
  }
}
