import 'package:go_router/go_router.dart';
import 'package:super_todoapp/screens/notification_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/home_screen.dart';
final GoRouter router = GoRouter(
  routes: [
    GoRoute(
        path: '/',
        builder: (context, state) => const MyHomePage(title: 'Home'),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const Settings(),
    ),
    GoRoute(
      path: '/calendar',
      builder: (context, state) => const Calendar(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const Notifications(),
    ),
  ],
);