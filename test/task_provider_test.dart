import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:super_todoapp/models/tasks.dart';
import 'package:super_todoapp/provider.dart';
import 'support/controlled_box.dart';

Task task(String title, int start, int end, {DateTime? date}) => Task(
  title: title,
  date: date ?? DateTime(2026, 9, 20),
  startHour: start ~/ 60,
  startMinute: start % 60,
  endHour: end ~/ 60,
  endMinute: end % 60,
);

void main() {
  late Directory directory;
  late Box<Task> box;
  late ControlledBox controlled;
  late TaskProvider provider;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('todo-provider-test-');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TaskAdapter());
    box = await Hive.openBox<Task>('tasks');
    controlled = ControlledBox(box);
    provider = TaskProvider(box: controlled);
  });
  tearDown(() async {
    provider.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'trims titles, sorts by start time and persists after reopening',
    () async {
      await provider.addTask(task(' Позже ', 900, 960));
      await provider.addTask(task('Раньше', 540, 600));
      expect(provider.tasks.map((t) => t.title), ['Раньше', 'Позже']);
      await provider.toggleTask(provider.tasks.first);
      await box.close();
      box = await Hive.openBox<Task>('tasks');
      final restored = TaskProvider(box: box);
      expect(restored.tasks.first.isDone, isTrue);
      expect(restored.tasks.map((t) => t.title), ['Раньше', 'Позже']);
      restored.dispose();
    },
  );

  test('rejects empty titles and zero duration without writes', () async {
    await expectLater(
      provider.addTask(task('  ', 540, 600)),
      throwsA(isA<TaskException>()),
    );
    await expectLater(
      provider.addTask(task('Название', 540, 540)),
      throwsA(isA<TaskException>()),
    );
    expect(box.isEmpty, isTrue);
  });

  test('rejects overlap, allows adjacent intervals', () async {
    await provider.addTask(task('Первая', 540, 600));
    await expectLater(
      provider.addTask(task('Конфликт', 570, 630)),
      throwsA(isA<TaskException>()),
    );
    await provider.addTask(task('Соседняя', 600, 660));
    expect(provider.tasks, hasLength(2));
  });

  test(
    'overnight task appears on both dates and conflicts across midnight',
    () async {
      final date = DateTime(2026, 12, 31);
      final tomorrow = DateTime(2027, 1, 1);
      await provider.addTask(task('Ночная', 1410, 30, date: date));
      expect(provider.tasksByDate(date), hasLength(1));
      expect(provider.tasksByDate(tomorrow), hasLength(1));
      await expectLater(
        provider.addTask(task('Конфликт', 0, 60, date: tomorrow)),
        throwsA(isA<TaskException>()),
      );
      await provider.addTask(task('После', 30, 60, date: tomorrow));
      expect(provider.tasksByDate(tomorrow), hasLength(2));
    },
  );

  test('ending at midnight does not occupy the following day', () async {
    await provider.addTask(task('Вечер', 1380, 0));
    expect(provider.tasksByDate(DateTime(2026, 9, 21)), isEmpty);
  });

  test(
    'editing excludes itself, moving validates destination and keeps key',
    () async {
      await provider.addTask(task('Первая', 540, 600));
      await provider.addTask(task('Вторая', 660, 720));
      final original = provider.tasks.first;
      final key = original.key;
      await provider.updateTask(original, task('Переименована', 540, 600));
      expect(provider.tasks.first.title, 'Переименована');
      await expectLater(
        provider.updateTask(provider.tasks.first, task('Конфликт', 660, 700)),
        throwsA(isA<TaskException>()),
      );
      await provider.updateTask(
        provider.tasks.first,
        task('Перенесена', 660, 720, date: DateTime(2026, 9, 21)),
      );
      expect(provider.tasksByDate(DateTime(2026, 9, 21)).single.key, key);
      expect(provider.tasksByDate(DateTime(2026, 9, 20)), hasLength(1));
    },
  );

  test(
    'deletion can be undone and restoration cannot overwrite a conflict',
    () async {
      await provider.addTask(task('Задача', 540, 600));
      final key = provider.tasks.single.key;
      final deleted = await provider.deleteTask(provider.tasks.single);
      expect(provider.tasks, isEmpty);
      await provider.restoreTask(deleted);
      expect(provider.tasks.single.key, key);
      final deletedAgain = await provider.deleteTask(provider.tasks.single);
      await provider.addTask(task('Новая', 540, 600));
      await expectLater(
        provider.restoreTask(deletedAgain),
        throwsA(isA<TaskException>()),
      );
      expect(provider.tasks.single.title, 'Новая');
    },
  );

  test(
    'failed add, toggle, edit and delete preserve committed state',
    () async {
      await provider.addTask(task('Исходная', 540, 600));
      final original = provider.tasks.single;
      controlled.fail = true;
      await expectLater(
        provider.addTask(task('Новая', 660, 720)),
        throwsA(isA<TaskException>()),
      );
      await expectLater(
        provider.toggleTask(original),
        throwsA(isA<TaskException>()),
      );
      await expectLater(
        provider.updateTask(original, task('Правка', 540, 600)),
        throwsA(isA<TaskException>()),
      );
      await expectLater(
        provider.deleteTask(original),
        throwsA(isA<TaskException>()),
      );
      expect(provider.tasks.single.title, 'Исходная');
      expect(provider.tasks.single.isDone, isFalse);
      expect(box.values.single.title, 'Исходная');
      controlled.fail = false;
      await provider.toggleTask(original);
      expect(provider.tasks.single.isDone, isTrue);
    },
  );

  test(
    'publishes only after persistence and serializes conflicting submissions',
    () async {
      controlled.gate = Completer<void>();
      final first = provider.addTask(task('Первая', 540, 600));
      final second = provider.addTask(task('Вторая', 550, 610));
      final rejection = expectLater(second, throwsA(isA<TaskException>()));
      await Future<void>.delayed(Duration.zero);
      expect(provider.tasks, isEmpty);
      controlled.gate!.complete();
      await first;
      await rejection;
      expect(provider.tasks.single.title, 'Первая');
    },
  );
}
