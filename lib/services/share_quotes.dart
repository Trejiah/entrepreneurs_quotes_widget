import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/habits_provider.dart';
import 'package:businessmindset/features/share_preview/view/share_preview_page.dart';
import 'share_image_renderer.dart';

const MethodChannel _channel = MethodChannel('businessmindset/deeplink');

Future<bool> shareQuote(
  String currentQuote, {
  BuildContext? context,
  WidgetRef? ref,
  String? signature,
  String? bookTitle,
}) async {
  try {
    // If ref and context are provided, generate the image and show the preview page
    if (ref != null && context != null) {
      try {
        final currentTheme = ref.read(currentThemeProvider);
        final userName = ref.read(userNameStateProvider);

        Uint8List? result;

        if (Platform.isIOS) {
          // iOS: SwiftUI generator (see ios/Runner/AppDelegate.swift).
          final native = await _channel.invokeMethod(
            'generateShareImageBytes',
            {
              'quote': currentQuote,
              'signature': signature,
              'bookTitle': bookTitle,
              'userName': userName,
              'themeIsImage': currentTheme['isImage'] == true,
              'themeImageName': currentTheme['imageName'],
              'themeColor1': currentTheme['color1'],
              'themeColor2': currentTheme['color2'],
              'themeColor3': currentTheme['color3'],
              'themeNbrColor': currentTheme['nbrcolor'] ?? 1,
              'themeFontFamily': currentTheme['fontfamily'],
              'themeFontSize': currentTheme['fontsize'],
              'themeFontColor': currentTheme['fontcolor'],
            },
          );
          if (native is Uint8List) result = native;
        } else {
          // Android (and any other host): pure-Flutter offscreen renderer.
          result = await ShareImageRenderer.render(
            context: context,
            quote: currentQuote,
            signature: signature,
            bookTitle: bookTitle,
            userName: userName,
            themeIsImage: currentTheme['isImage'] == true,
            themeImageName: currentTheme['imageName'] as String?,
            themeColor1: currentTheme['color1'] as String?,
            themeColor2: currentTheme['color2'] as String?,
            themeColor3: currentTheme['color3'] as String?,
            themeNbrColor: (currentTheme['nbrcolor'] as int?) ?? 1,
            themeFontFamily: currentTheme['fontfamily'] as String?,
            themeFontSize: (currentTheme['fontsize'] as num?)?.toDouble(),
            themeFontColor: currentTheme['fontcolor'] as String?,
          );
        }

        if (result != null) {
          final bytes = result;
          // Navigate to the preview page with the image
          if (context.mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SharePreviewPage(
                  imageBytes: bytes,
                  quote: currentQuote,
                  signature: signature,
                  bookTitle: bookTitle,
                ),
              ),
            );
          }
          return true;
        } else {
          debugPrint('[ShareQuote] Error: invalid result from generateShareImageBytes');
        }
      } catch (e) {
        // On error, fallback to text
        debugPrint('[ShareQuote] Error while generating the image: $e');
      }
    }
    
    // Fallback: share the text (quote + app link)
    const appStoreUrl = "https://apps.apple.com/us/app/business-mindset-quotes/id6754601387";
    const playStoreUrl = "https://play.google.com/store/apps/details?id=com.bakemono.businessmindset";
    final appLink = Platform.isIOS ? appStoreUrl : playStoreUrl;

    final buffer = StringBuffer()..writeln(currentQuote);
    if (signature != null && signature.isNotEmpty) {
      buffer.writeln('— $signature');
    }
    if (bookTitle != null && bookTitle.isNotEmpty) {
      buffer.writeln(bookTitle);
    }
    buffer.writeln('');
    buffer.writeln(appLink);

    final text = buffer.toString().trim();
    
    final box = context?.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null 
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    final shareResult = await SharePlus.instance.share(
      ShareParams(
        text: text,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
    return shareResult.status != ShareResultStatus.dismissed;
  } catch (e) {
    debugPrint('[ShareQuote] General error: $e');
    return false;
  }
}