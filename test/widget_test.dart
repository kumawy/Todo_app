import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:super_todoapp/main.dart';
import 'package:super_todoapp/focus_provider.dart';
import 'package:super_todoapp/screens/pomodoro_screen.dart';
import 'package:super_todoapp/app_theme.dart';
import 'package:super_todoapp/date_limits.dart';
import 'package:super_todoapp/widgets/week_date_strip.dart';
import 'support/controlled_box.dart';
import 'package:super_todoapp/models/tasks.dart';
import 'package:super_todoapp/provider.dart';
import 'package:super_todoapp/router.dart';
import 'package:super_todoapp/widgets/task_list_item.dart';
import 'package:super_todoapp/widgets/time_range_picker.dart';

Task sampleTask(String title, DateTime date, {int hour = 9}) => Task(
  title: title,
  date: date,
  startHour: hour,
  startMinute: 0,
  endHour: hour + 1,
  endMinute: 0,
);

Future<void> finishWrite(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

void main() {
  late Box<Task> box;
  setUp(() async {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TaskAdapter());
    box = await Hive.openBox<Task>('tasks', bytes: Uint8List(0));
    await Hive.openBox<int>('settings', bytes: Uint8List(0));
    router.go('/');
  });
  tearDown(() async {
    await Hive.close();
  });

  testWidgets('creates a trimmed task and rejects whitespace', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Добавить задачу'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Введите название задачи.'), findsOneWidget);
    expect(box.isEmpty, isTrue);
    await tester.enterText(find.byType(TextFormField), '  Купить молоко  ');
    await tester.tap(find.text('Выбрать время'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Выбрать время'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await finishWrite(tester);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Купить молоко'), findsOneWidget);
    expect(box.values.single.title, 'Купить молоко');
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit preserves task identity; delete and undo restore it', (
    tester,
  ) async {
    await box.add(sampleTask('Исходная', DateTime.now()));
    final key = box.values.single.key;
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Исходная'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Изменённая');
    await tester.tap(find.text('Сохранить'));
    await finishWrite(tester);
    expect(box.values.single.key, key);
    expect(find.text('Изменённая'), findsOneWidget);
    await tester.tap(find.byTooltip('Действия с задачей'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await finishWrite(tester);
    expect(box.isEmpty, isTrue);
    await tester.tap(find.text('Отменить'));
    await finishWrite(tester);
    expect(box.values.single.key, key);
    expect(find.text('Изменённая'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipe deletes safely while persistence updates the list', (
    tester,
  ) async {
    await box.add(sampleTask('Удаляемая', DateTime.now()));
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Dismissible), const Offset(-600, 0));
    await tester.pump();
    await finishWrite(tester);
    expect(box.isEmpty, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'drawer closes, Home does not push duplicates, notifications absent',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('Уведомления'), findsNothing);
      expect(find.text('aslan'), findsOneWidget);
      expect(find.text('aslanmuratov@gmail.com'), findsOneWidget);
      await tester.tap(find.text('Главная'));
      await tester.pumpAndSettle();
      expect(router.canPop(), isFalse);
      expect(
        tester.state<ScaffoldState>(find.byType(Scaffold).first).isDrawerOpen,
        isFalse,
      );
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Настройки'));
      await tester.pumpAndSettle();
      expect(find.text('Сохранить настройки'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(
        tester.state<ScaffoldState>(find.byType(Scaffold).first).isDrawerOpen,
        isFalse,
      );
      expect(router.canPop(), isFalse);
    },
  );

  testWidgets('calendar shares arbitrary selected date with Home', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    final context = tester.element(
      find.byType(TaskListItem).evaluate().isNotEmpty
          ? find.byType(TaskListItem).first
          : find.text('Сегодня'),
    );
    context.read<TaskProvider>().selectDate(DateTime(2027, 1, 15));
    await tester.pumpAndSettle();
    expect(find.text('15 января'), findsOneWidget);
    expect(find.text('15.01.2027'), findsNothing);
    expect(find.text('Сегодня'), findsOneWidget);
    await tester.tap(find.byTooltip('Календарь'));
    await tester.pumpAndSettle();
    expect(find.text('15 января'), findsOneWidget);
    expect(find.text('Открыть день'), findsNothing);
    await tester.tap(find.byTooltip('Назад'));
    await tester.pumpAndSettle();
    expect(find.text('15 января'), findsOneWidget);
    expect(find.text('15.01.2027'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late-night time picker has valid next-day default', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTimeRangePicker(
                context,
                initialStart: const TimeOfDay(hour: 23, minute: 30),
              ),
              child: const Text('Открыть'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
    final endPicker = tester.widget<CupertinoDatePicker>(
      find.byKey(const ValueKey('end-time-picker')),
    );
    expect(endPicker.initialDateTime.hour, 0);
    expect(endPicker.initialDateTime.minute, 30);
    expect(find.text('Окончание на следующий день'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Выбрать время'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'small screen with keyboard can scroll task form without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Добавить задачу'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('failed undo can be retried after the row is disposed', (
    tester,
  ) async {
    final controlled = ControlledBox(box);
    final provider = TaskProvider(box: controlled);
    addTearDown(provider.dispose);
    await provider.addTask(sampleTask('Восстановить', DateTime.now()));
    final key = provider.tasks.single.key;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer<TaskProvider>(
              builder: (context, value, _) => Column(
                children: value.tasks
                    .map(
                      (task) => TaskListItem(
                        key: ValueKey(value.keyForTask(task)),
                        task: task,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Действия с задачей'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await finishWrite(tester);
    expect(find.byType(TaskListItem), findsNothing);
    controlled.fail = true;
    await tester.tap(find.text('Отменить'));
    await finishWrite(tester);
    expect(find.text('Повторить'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await finishWrite(tester);
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Повторить'), findsOneWidget);
    controlled.fail = false;
    await tester.tap(find.text('Повторить'));
    await finishWrite(tester);
    expect(provider.tasks.single.key, key);
    expect(find.text('Восстановить'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    for (final populated in [false, true]) {
      testWidgets('home supports 200% text at $size, populated=$populated', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        if (populated) await box.add(sampleTask('Проверка', DateTime.now()));
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          populated
              ? find.text('Проверка')
              : find.text('На этот день планов пока нет'),
          150,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey('home-task-scroll')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'date strip and pickers respect the same upper and lower bounds',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      final provider = tester
          .element(find.text('Сегодня'))
          .read<TaskProvider>();
      provider.selectDate(lastTaskDate);
      await tester.pumpAndSettle();
      final strip = find.byType(WeekDateStrip);
      expect(
        find.descendant(of: strip, matching: find.text('31')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: strip, matching: find.text('1')),
        findsNothing,
      );
      provider.selectDate(DateTime(2201));
      expect(provider.selectedDate, lastTaskDate);
      await tester.tap(find.byTooltip('Календарь'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Выбрать дату'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      provider.selectDate(DateTime(1899));
      await tester.pumpAndSettle();
      expect(provider.selectedDate, firstTaskDate);
      await tester.tap(find.byTooltip('Выбрать дату'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('calendar menu completes and reopens tasks without swiping', (
    tester,
  ) async {
    await box.add(sampleTask('Проверка статуса', DateTime.now()));
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Календарь'));
    await tester.pumpAndSettle();
    final menu = find.byTooltip('Действия с задачей');
    await tester.ensureVisible(menu);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отметить выполненной'));
    await finishWrite(tester);
    expect(box.values.single.isDone, isTrue);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отметить невыполненной'));
    await finishWrite(tester);
    expect(box.values.single.isDone, isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets('task scrolling stays inside the fixed white panel', (
    tester,
  ) async {
    for (var i = 0; i < 15; i++) {
      await box.add(sampleTask('Задача $i', DateTime.now(), hour: i));
    }
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    final panel = find.byKey(const ValueKey('home-task-panel'));
    final dates = find.byType(WeekDateStrip);
    final headingPosition = tester.getTopLeft(find.text('Сегодня'));
    final panelRect = tester.getRect(panel);
    final datesPosition = tester.getTopLeft(dates);
    final taskScroll = find.byKey(const ValueKey('home-task-scroll'));
    final listRect = tester.getRect(taskScroll);
    expect(listRect.top, greaterThanOrEqualTo(panelRect.top));
    expect(listRect.bottom, lessThanOrEqualTo(panelRect.bottom));
    expect(tester.widget<Container>(panel).clipBehavior, Clip.antiAlias);
    await tester.drag(taskScroll, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.getRect(panel), panelRect);
    expect(tester.getTopLeft(find.text('Сегодня')), headingPosition);
    expect(tester.getTopLeft(dates), datesPosition);
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: taskScroll, matching: find.byType(Scrollable)),
    );
    expect(scrollable.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
  testWidgets('startup error retries without clearing existing tasks', (
    tester,
  ) async {
    await box.add(sampleTask('Сохранённая задача', DateTime.now()));
    var attempts = 0;
    await tester.pumpWidget(
      StartupApp(
        initialize: () async {
          attempts++;
          if (attempts == 1) throw StateError('Temporary storage failure');
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Не удалось открыть данные'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Сохранённая задача'), findsOneWidget);
    expect(box.length, 1);
  });

  testWidgets(
    'settings presets save only changed values and validate manual input',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      router.go('/settings');
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, 'Сохранить настройки');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await tester.tap(find.text('45 мин'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await finishWrite(tester);
      expect(Hive.box<int>('settings').get('focusMinutes'), 45);
      expect(find.text('Настройки сохранены'), findsOneWidget);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await tester.enterText(find.byType(TextFormField).first, '0');
      await tester.pumpAndSettle();
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('Введите от 1 до 120 минут.'), findsOneWidget);
      expect(Hive.box<int>('settings').get('focusMinutes'), 45);
    },
  );

  testWidgets('completed focus starts the next break from its primary action', (
    tester,
  ) async {
    var now = DateTime(2026, 9, 24, 12);
    final timer = FocusProvider(
      settings: Hive.box<int>('settings'),
      now: () => now,
    );
    addTearDown(timer.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: timer,
        child: MaterialApp(theme: buildAppTheme(), home: const Pomodoro()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Начать'));
    await tester.pump();
    expect(timer.isRunning, isTrue);
    now = now.add(const Duration(minutes: 25));
    timer.refresh();
    await tester.pumpAndSettle();
    expect(find.text('Сеанс завершён'), findsOneWidget);
    await tester.tap(find.text('Начать перерыв'));
    await tester.pump();
    expect(timer.isBreak, isTrue);
    expect(timer.isRunning, isTrue);
    expect(timer.remainingSeconds, 300);
    timer.pause();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final route in ['/calendar', '/settings', '/pomodoro']) {
    testWidgets('$route supports a small screen and 200% text', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const MyApp());
      router.go(route);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'narrow time picker remains scrollable and accepts an overnight range',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      TimeRange? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selected = await showTimeRangePicker(
                    context,
                    initialStart: const TimeOfDay(hour: 23, minute: 30),
                  );
                },
                child: const Text('Открыть'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final button = find.widgetWithText(FilledButton, 'Выбрать время');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(selected!.durationMinutes, 60);
      expect(selected!.endsNextDay, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'iOS keeps the native swipe-back gesture',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.tap(find.byTooltip('Календарь'));
      await tester.pumpAndSettle();
      expect(router.canPop(), isTrue);
      await tester.dragFrom(const Offset(1, 250), const Offset(650, 0));
      await tester.pumpAndSettle();
      expect(router.canPop(), isFalse);
      expect(find.text('Мои задачи'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('drawer remains usable with large text and reduced motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('aslanmuratov@gmail.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Настройки'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(Drawer),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    expect(find.text('Ваш ритм'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
