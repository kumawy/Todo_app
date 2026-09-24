import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedRoute = GoRouterState.of(context).uri.path;
    void navigate(String route) {
      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      router.go(route);
    }

    Widget destination(String label, IconData icon, String route) {
      final selected = selectedRoute == route;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: AnimatedContainer(
          duration: motionDuration(context),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.transparent,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              selected: selected,
              selectedColor: Colors.white,
              iconColor: Colors.white.withValues(alpha: 0.85),
              textColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: Icon(icon),
              title: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.chevron_right, size: 18)
                  : null,
              onTap: () => navigate(route),
            ),
          ),
        ),
      );
    }

    return Drawer(
      width: MediaQuery.sizeOf(context).width.clamp(0, 400) * 0.86,
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF3639A5).withValues(alpha: 0.86),
                const Color(0xFF25265E).withValues(alpha: 0.78),
              ],
            ),
            border: Border(
              right: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        child: const Text(
                          'AM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'aslan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'aslanmuratov@gmail.com',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                destination('Главная', Icons.home_outlined, '/'),
                destination(
                  'Календарь',
                  Icons.calendar_month_outlined,
                  '/calendar',
                ),
                destination('Таймер фокуса', Icons.timer_outlined, '/pomodoro'),
                Divider(color: Colors.white.withValues(alpha: 0.16)),
                destination('Настройки', Icons.settings_outlined, '/settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
