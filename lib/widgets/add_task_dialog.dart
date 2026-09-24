import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../date_limits.dart';
import '../models/tasks.dart';
import '../provider.dart';
import 'time_range_picker.dart';

Future<void> openAddTaskDialog({
  required BuildContext context,
  required DateTime selectedDate,
  Task? task,
}) {
  final provider = context.read<TaskProvider>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    constraints: const BoxConstraints(maxWidth: 560),
    sheetAnimationStyle: AnimationStyle(
      duration: motionDuration(context, 280),
      reverseDuration: motionDuration(context),
    ),
    builder: (_) =>
        _TaskDialog(selectedDate: selectedDate, task: task, provider: provider),
  );
}

class _TaskDialog extends StatefulWidget {
  const _TaskDialog({
    required this.selectedDate,
    required this.provider,
    this.task,
  });
  final DateTime selectedDate;
  final Task? task;
  final TaskProvider provider;
  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late DateTime _date;
  TimeRange? _range;
  String? _timeError;
  String? _saveError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _controller = TextEditingController(text: task?.title);
    _date = DateUtils.dateOnly(task?.date ?? widget.selectedDate);
    if (task != null) _range = TimeRange(task.startTime, task.endTime);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final date = await showDatePicker(
      context: context,
      initialDate: clampTaskDate(_date),
      firstDate: firstTaskDate,
      lastDate: lastTaskDate,
    );
    if (mounted && date != null) {
      setState(() {
        _date = date;
        _timeError = null;
      });
    }
  }

  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();
    final result = await showTimeRangePicker(
      context,
      initialStart: _range?.start,
      initialEnd: _range?.end,
    );
    if (mounted && result != null) {
      setState(() {
        _range = result;
        _timeError = null;
      });
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final range = _range;
    if (range == null) {
      setState(() => _timeError = 'Выберите время начала и окончания.');
      return;
    }
    setState(() {
      _saving = true;
      _timeError = null;
      _saveError = null;
    });
    final task = Task.fromTime(
      title: _controller.text.trim(),
      date: _date,
      startTime: range.start,
      endTime: range.end,
      isDone: widget.task?.isDone ?? false,
    );
    try {
      if (widget.task == null) {
        await widget.provider.addTask(task);
      } else {
        await widget.provider.updateTask(widget.task!, task);
      }
      widget.provider.selectDate(_date);
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop();
      }
    } on TaskException catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          if (error.message == 'Время пересекается с другой задачей.') {
            _timeError = error.message;
          } else {
            _saveError = error.message;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AnimatedPadding(
      duration: motionDuration(context),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.task == null
                            ? 'Новая задача'
                            : 'Редактировать задачу',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Закрыть',
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _controller,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Название задачи',
                    hintText: 'Что нужно сделать?',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Введите название задачи.'
                      : null,
                ),
                const SizedBox(height: 20),
                Semantics(
                  button: true,
                  label: 'Изменить дату',
                  child: InkWell(
                    onTap: _saving ? null : _pickDate,
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Дата',
                        suffixIcon: Icon(Icons.calendar_month_outlined),
                      ),
                      child: Text('${formatDayMonth(_date)} ${_date.year}'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Semantics(
                  button: true,
                  label: 'Выбрать время задачи',
                  child: InkWell(
                    onTap: _saving ? null : _pickTime,
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Время',
                        errorText: _timeError,
                        suffixIcon: const Icon(Icons.schedule),
                      ),
                      child: Text(
                        _range == null
                            ? 'Выбрать время'
                            : '${formatTime(_range!.start)}–${formatTime(_range!.end)}',
                        style: TextStyle(
                          color: _range == null ? appMuted : appInk,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_range != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${formatDurationMinutes(_range!.durationMinutes)}${_range!.endsNextDay ? ' · окончание на следующий день' : ''}',
                      style: const TextStyle(color: appMuted, fontSize: 13),
                    ),
                  ),
                if (_saveError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _saveError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Сохранение…' : 'Сохранить'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
