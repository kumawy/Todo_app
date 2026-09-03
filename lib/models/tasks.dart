import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'tasks.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  bool isDone;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  int startHour;

  @HiveField(4)
  int startMinute;

  @HiveField(5)
  int endHour;

  @HiveField(6)
  int endMinute;

  // ✅ ОСНОВНОЙ (Hive будет использовать его)
  Task({
    required this.title,
    this.isDone = false,
    required this.date,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  // ✅ ОСТАВЛЯЕМ для UI (ничего не ломаем)
  factory Task.fromTime({
    required String title,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    bool isDone = false,
  }) {
    return Task(
      title: title,
      isDone: isDone,
      date: date,
      startHour: startTime.hour,
      startMinute: startTime.minute,
      endHour: endTime.hour,
      endMinute: endTime.minute,
    );
  }

  // UI геттеры
  TimeOfDay get startTime =>
      TimeOfDay(hour: startHour, minute: startMinute);

  TimeOfDay get endTime =>
      TimeOfDay(hour: endHour, minute: endMinute);
}