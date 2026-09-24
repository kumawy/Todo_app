import 'dart:async';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:super_todoapp/models/tasks.dart';

// Fault injection around a real Hive box, including delayed writes.
class ControlledBox implements Box<Task> {
  ControlledBox(this.delegate);
  final Box<Task> delegate;
  bool fail = false;
  Completer<void>? gate;
  Future<void> beforeWrite() async {
    await gate?.future;
    if (fail) throw const FileSystemException('disk full');
  }

  @override
  Iterable<Task> get values => delegate.values;
  @override
  bool containsKey(dynamic key) => delegate.containsKey(key);
  @override
  Task? get(dynamic key, {Task? defaultValue}) =>
      delegate.get(key, defaultValue: defaultValue);
  @override
  Future<int> add(Task value) async {
    await beforeWrite();
    return delegate.add(value);
  }

  @override
  Future<void> put(dynamic key, Task value) async {
    await beforeWrite();
    await delegate.put(key, value);
  }

  @override
  Future<void> delete(dynamic key) async {
    await beforeWrite();
    await delegate.delete(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
