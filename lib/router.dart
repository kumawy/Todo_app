import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'screens/calendar_screen.dart';
import 'screens/home_screen.dart';
import 'screens/pomodoro_screen.dart';
import 'screens/settings_screen.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MyHomePage(),
      routes: [
        GoRoute(
          path: 'settings',
          pageBuilder: (context, state) =>
              _animatedPage(context, state, const Settings()),
        ),
        GoRoute(
          path: 'calendar',
          pageBuilder: (context, state) =>
              _animatedPage(context, state, const Calendar()),
        ),
        GoRoute(
          path: 'pomodoro',
          pageBuilder: (context, state) =>
              _animatedPage(context, state, const Pomodoro()),
        ),
      ],
    ),
  ],
);

Page<void> _animatedPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  if (Theme.of(context).platform == TargetPlatform.iOS &&
      !MediaQuery.disableAnimationsOf(context)) {
    return CupertinoPage<void>(key: state.pageKey, child: child);
  }
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
