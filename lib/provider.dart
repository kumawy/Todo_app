import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'models/tasks.dart';
import 'date_limits.dart';

class TaskException implements Exception {
  const TaskException(this.message);
  final String message;
  @override
  String toString() => message;
}

class DeletedTask {
  const DeletedTask(this.key, this.task);
  final dynamic key;
  final Task task;
}

class TaskProvider extends ChangeNotifier {
  TaskProvider({Box<Task>? box}) : _box = box ?? Hive.box<Task>('tasks') {
    _reload();
  }

  final Box<Task> _box;
  List<Task> _tasks = [];
  final Expando<Object> _keys = Expando<Object>();
  Future<void> _pending = Future.value();
  bool _disposed = false;
  DateTime _selectedDate = clampTaskDate(DateTime.now());

  List<Task> get tasks => List.unmodifiable(_tasks);
  DateTime get selectedDate => _selectedDate;

  void selectDate(DateTime date) {
    _selectedDate = clampTaskDate(date);
    notifyListeners();
  }

  Object? keyForTask(Task task) => _keys[task] ?? task.key;

  void _reload() {
    _tasks = _box.values.toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    for (final task in _tasks) {
      _keys[task] = task.key;
    }
  }

  // Serialize validation and writes so concurrent submissions cannot overlap.
  // Publish only committed data; failed writes leave the displayed snapshot intact.
  Future<T> _write<T>(Future<T> Function() action) {
    final operation = _pending.then((_) async {
      try {
        final result = await action();
        _reload();
        if (!_disposed) notifyListeners();
        return result;
      } on TaskException {
        rethrow;
      } catch (_) {
        throw const TaskException(
          'Не удалось сохранить изменения. Попробуйте ещё раз.',
        );
      }
    });
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  void _validate(Task task, {dynamic excludingKey}) {
    if (task.title.trim().isEmpty) {
      throw const TaskException('Введите название задачи.');
    }
    if (task.startHour < 0 ||
        task.startHour > 23 ||
        task.endHour < 0 ||
        task.endHour > 23 ||
        task.startMinute < 0 ||
        task.startMinute > 59 ||
        task.endMinute < 0 ||
        task.endMinute > 59 ||
        task.startMinutes == task.endMinutes) {
      throw const TaskException('Укажите разное время начала и окончания.');
    }
    if (_tasks.any(
      (existing) =>
          keyForTask(existing) != excludingKey &&
          task.startsAt.isBefore(existing.endsAt) &&
          task.endsAt.isAfter(existing.startsAt),
    )) {
      throw const TaskException('Время пересекается с другой задачей.');
    }
  }

  Future<void> addTask(Task task) => _write(() async {
    _validate(task);
    await _box.add(task.copyWith());
  });

  Future<void> updateTask(Task original, Task replacement) => _write(() async {
    if (!_box.containsKey(keyForTask(original))) {
      throw const TaskException('Задача уже удалена.');
    }
    _validate(replacement, excludingKey: keyForTask(original));
    await _box.put(keyForTask(original), replacement.copyWith());
  });

  Future<void> toggleTask(Task task) => _write(() async {
    final current = _box.get(keyForTask(task));
    if (current == null) throw const TaskException('Задача уже удалена.');
    await _box.put(keyForTask(task), current.copyWith(isDone: !current.isDone));
  });

  Future<DeletedTask> deleteTask(Task task) => _write(() async {
    final key = keyForTask(task);
    final current = _box.get(key);
    if (current == null) throw const TaskException('Задача уже удалена.');
    final deleted = DeletedTask(key, current.copyWith());
    await _box.delete(key);
    return deleted;
  });

  Future<void> restoreTask(DeletedTask deleted) => _write(() async {
    if (_box.containsKey(deleted.key)) {
      throw const TaskException('Задача уже восстановлена.');
    }
    _validate(deleted.task);
    await _box.put(deleted.key, deleted.task.copyWith());
  });

  // Include the following day's part of an overnight task in the calendar.
  List<Task> tasksByDate(DateTime date) {
    final start = DateUtils.dateOnly(date);
    final end = DateTime(start.year, start.month, start.day + 1);
    return _tasks
        .where(
          (task) => task.startsAt.isBefore(end) && task.endsAt.isAfter(start),
        )
        .toList();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
