import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

final languageProvider = StateProvider<String>(
      (ref) {
    final locale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return ['fr', 'en'].contains(locale) ? locale : 'en';
  },
);
