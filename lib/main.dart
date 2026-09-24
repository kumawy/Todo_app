import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'focus_provider.dart';
import 'models/tasks.dart';
import 'provider.dart';
import 'router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StartupApp());
}

Future<void> _openData() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TaskAdapter());
  if (!Hive.isBoxOpen('tasks')) await Hive.openBox<Task>('tasks');
  if (!Hive.isBoxOpen('settings')) await Hive.openBox<int>('settings');
}

class StartupApp extends StatefulWidget {
  const StartupApp({super.key, this.initialize});
  final Future<void> Function()? initialize;
  @override
  State<StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<StartupApp> {
  late Future<void> _loading;
  @override
  void initState() {
    super.initState();
    _loading = Future.sync(widget.initialize ?? _openData);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return const MyApp();
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (snapshot.hasError) ...[
                        const Icon(
                          Icons.folder_off_outlined,
                          size: 48,
                          color: appPrimary,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Не удалось открыть данные',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Попробуйте снова. Если ошибка повторится, проверьте свободное место на устройстве.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: appMuted, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () {
                            final loading = Future.sync(
                              widget.initialize ?? _openData,
                            );
                            setState(() {
                              _loading = loading;
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Повторить'),
                        ),
                      ] else ...[
                        const CircularProgressIndicator(),
                        const SizedBox(height: 24),
                        const Text(
                          'Открываем ваши задачи…',
                          style: TextStyle(color: appMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => TaskProvider()),
      ChangeNotifierProvider(
        create: (_) => FocusProvider(settings: Hive.box<int>('settings')),
      ),
    ],
    child: MaterialApp.router(
      title: 'Мои задачи',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    ),
  );
}
