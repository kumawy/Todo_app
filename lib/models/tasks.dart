import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'tasks.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final bool isDone;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final int startHour;

  @HiveField(4)
  final int startMinute;

  @HiveField(5)
  final int endHour;

  @HiveField(6)
  final int endMinute;

  Task({
    required this.title,
    this.isDone = false,
    required this.date,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

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

  TimeOfDay get startTime => TimeOfDay(hour: startHour, minute: startMinute);

  TimeOfDay get endTime => TimeOfDay(hour: endHour, minute: endMinute);

  int get startMinutes => startHour * 60 + startMinute;
  int get endMinutes => endHour * 60 + endMinute;
  bool get endsNextDay => endMinutes < startMinutes;

  DateTime get startsAt =>
      DateTime(date.year, date.month, date.day, startHour, startMinute);
  DateTime get endsAt => DateTime(
    date.year,
    date.month,
    date.day + (endsNextDay ? 1 : 0),
    endHour,
    endMinute,
  );

  Task copyWith({bool? isDone}) => Task(
    title: title.trim(),
    isDone: isDone ?? this.isDone,
    date: DateTime(date.year, date.month, date.day),
    startHour: startHour,
    startMinute: startMinute,
    endHour: endHour,
    endMinute: endMinute,
  );
}
