import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class FocusProvider extends ChangeNotifier {
  FocusProvider({required this._settings, DateTime Function()? now})
    : _now = now ?? DateTime.now {
    focusMinutes = _readDuration('focusMinutes', 25);
    breakMinutes = _readDuration('breakMinutes', 5);
    _remaining = Duration(minutes: focusMinutes);
    _sessionDuration = _remaining;
  }

  final Box<int> _settings;
  final DateTime Function() _now;
  late int focusMinutes;
  late int breakMinutes;
  late Duration _remaining;
  late Duration _sessionDuration;
  bool _hasStarted = false;
  DateTime? _deadline;
  Timer? _ticker;
  bool isBreak = false;
  bool saving = false;
  bool _disposed = false;

  int _readDuration(String key, int fallback) {
    final value = _settings.get(key, defaultValue: fallback)!;
    return value > 0 && value <= 120 ? value : fallback;
  }

  bool get isRunning => _deadline != null;
  bool get hasStarted => _hasStarted;
  double get progress =>
      (1 - remainingSeconds / _sessionDuration.inSeconds).clamp(0.0, 1.0);
  int get remainingSeconds {
    final duration = _deadline?.difference(_now()) ?? _remaining;
    return (duration.inMicroseconds / Duration.microsecondsPerSecond)
        .ceil()
        .clamp(0, 7200);
  }

  void start() {
    if (isRunning || remainingSeconds == 0) return;
    _hasStarted = true;
    _deadline = _now().add(_remaining);
    _ticker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => refresh(),
    );
    notifyListeners();
  }

  void refresh() {
    if (_deadline == null) return;
    if (remainingSeconds == 0) {
      _remaining = Duration.zero;
      _deadline = null;
      _ticker?.cancel();
    }
    notifyListeners();
  }

  void pause() {
    if (!isRunning) return;
    final remaining = _deadline!.difference(_now());
    _remaining = remaining.isNegative ? Duration.zero : remaining;
    _deadline = null;
    _ticker?.cancel();
    notifyListeners();
  }

  void reset({bool? breakMode}) {
    _ticker?.cancel();
    _deadline = null;
    isBreak = breakMode ?? isBreak;
    _remaining = Duration(minutes: isBreak ? breakMinutes : focusMinutes);
    _sessionDuration = _remaining;
    _hasStarted = false;
    notifyListeners();
  }

  Future<void> saveSettings(int focus, int rest) async {
    if (saving) return;
    if (focus < 1 || focus > 120 || rest < 1 || rest > 120) {
      throw ArgumentError('Длительность должна быть от 1 до 120 минут.');
    }
    saving = true;
    notifyListeners();
    try {
      await _settings.putAll({'focusMinutes': focus, 'breakMinutes': rest});
      focusMinutes = focus;
      breakMinutes = rest;
      // An active or paused session keeps its duration until the next reset.
      if (!_hasStarted) {
        _remaining = Duration(minutes: isBreak ? rest : focus);
        _sessionDuration = _remaining;
      }
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    super.dispose();
  }
}
