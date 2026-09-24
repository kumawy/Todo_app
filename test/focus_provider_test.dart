import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:super_todoapp/focus_provider.dart';

void main() {
  late Directory directory;
  late Box<int> settings;
  late DateTime now;
  late FocusProvider timer;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('todo-focus-test-');
    Hive.init(directory.path);
    settings = await Hive.openBox<int>('settings');
    now = DateTime(2026, 9, 20, 12);
    timer = FocusProvider(settings: settings, now: () => now);
  });
  tearDown(() async {
    timer.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'uses elapsed time, pauses, resumes and completes after background gap',
    () {
      timer.start();
      now = now.add(const Duration(minutes: 2));
      expect(timer.remainingSeconds, 23 * 60);
      timer.pause();
      now = now.add(const Duration(minutes: 10));
      expect(timer.remainingSeconds, 23 * 60);
      timer.start();
      now = now.add(const Duration(minutes: 24));
      timer.refresh();
      expect(timer.remainingSeconds, 0);
      expect(timer.isRunning, isFalse);
      timer.reset(breakMode: true);
      expect(timer.remainingSeconds, 5 * 60);
    },
  );

  test('repeated pauses preserve fractions of a second', () {
    for (var i = 0; i < 10; i++) {
      timer.start();
      now = now.add(const Duration(milliseconds: 900));
      timer.pause();
      now = now.add(const Duration(minutes: 1));
    }
    expect(timer.remainingSeconds, 1491);
    timer.start();
    now = now.add(const Duration(seconds: 1491));
    timer.refresh();
    expect(timer.remainingSeconds, 0);
    expect(timer.isRunning, isFalse);
  });

  test('pausing after the deadline cannot leave a negative duration', () {
    timer.start();
    now = now.add(const Duration(minutes: 26));
    timer.pause();
    timer.start();
    expect(timer.remainingSeconds, 0);
    expect(timer.isRunning, isFalse);
  });

  test('settings persist and do not interrupt a running session', () async {
    timer.start();
    now = now.add(const Duration(minutes: 1));
    await timer.saveSettings(45, 10);
    expect(timer.remainingSeconds, 24 * 60);
    timer.reset();
    expect(timer.remainingSeconds, 45 * 60);
    await settings.close();
    settings = await Hive.openBox<int>('settings');
    final reopened = FocusProvider(settings: settings);
    expect(reopened.focusMinutes, 45);
    expect(reopened.breakMinutes, 10);
    reopened.dispose();
  });

  test('failed settings write leaves previous values usable', () async {
    await settings.close();
    await expectLater(timer.saveSettings(45, 10), throwsA(anything));
    expect(timer.focusMinutes, 25);
    expect(timer.breakMinutes, 5);
    expect(timer.saving, isFalse);
  });
  test(
    'progress keeps the current session duration after settings change',
    () async {
      timer.start();
      now = now.add(const Duration(minutes: 5));
      timer.pause();
      expect(timer.hasStarted, isTrue);
      expect(timer.progress, closeTo(0.2, 0.001));
      await timer.saveSettings(60, 15);
      expect(timer.progress, closeTo(0.2, 0.001));
      expect(timer.remainingSeconds, 1200);
      timer.reset();
      expect(timer.progress, 0);
      expect(timer.hasStarted, isFalse);
      expect(timer.remainingSeconds, 3600);
    },
  );
}
