import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/tasks.dart';

class TaskProvider extends ChangeNotifier {
  final Box<Task> _box = Hive.box<Task>('tasks');

  List<Task> get tasks => _box.values.toList();

  void addTask(Task task) {
    _box.add(task);
    notifyListeners();
  }

  void toggleTask(Task task) {
    task.isDone = !task.isDone;
    task.save();
    notifyListeners();
  }

  void deleteTask(Task task) {
    task.delete();
    notifyListeners();
  }

  List<Task> tasksByDate(DateTime date) {
    return _box.values.where((task) {
      return task.date.year == date.year &&
          task.date.month == date.month &&
          task.date.day == date.day;
    }).toList();
  }
}