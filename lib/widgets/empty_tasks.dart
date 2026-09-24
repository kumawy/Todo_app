import 'package:flutter/material.dart';
import '../app_theme.dart';

class EmptyTasks extends StatelessWidget {
  const EmptyTasks({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: appSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_outlined,
              color: appPrimary,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'На этот день планов пока нет',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: appInk,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Добавьте первую задачу — начните с самого важного.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5, color: appMuted),
          ),
        ],
      ),
    ),
  );
}
