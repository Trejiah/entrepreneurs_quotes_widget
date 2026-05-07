// page_transitions.dart
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

Route<T> sharedAxisFromBottom<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (context, animation, secondary, child) {
      final accessible = MediaQuery.of(context).accessibleNavigation;
      if (accessible) return child; // Réduit le motion: pas d’anim

      // Vertical SharedAxis + slight "slide from bottom" to visually anchor on the bottom icon
      final slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic))
          .animate(animation);

      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondary,
        transitionType: SharedAxisTransitionType.vertical,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

Route<T> fadeThroughRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (context, a, s, child) =>
        FadeThroughTransition(animation: a, secondaryAnimation: s, child: child),
  );
}

Route<T> sharedAxisFromRight<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (context, animation, secondary, child) {
      final accessible = MediaQuery.of(context).accessibleNavigation;
      if (accessible) return child; // Réduit le motion : pas d’anim

      // Horizontal SharedAxis + slight "slide from right"
      final slide = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic))
          .animate(animation);

      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondary,
        transitionType: SharedAxisTransitionType.horizontal,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
