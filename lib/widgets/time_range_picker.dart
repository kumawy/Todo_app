import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../app_theme.dart';

Future<TimeRange?> showTimeRangePicker(
  BuildContext context, {
  TimeOfDay? initialStart,
  TimeOfDay? initialEnd,
}) => showModalBottomSheet<TimeRange>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 560),
  sheetAnimationStyle: AnimationStyle(
    duration: motionDuration(context, 280),
    reverseDuration: motionDuration(context),
  ),
  builder: (_) =>
      _TimeRangePicker(initialStart: initialStart, initialEnd: initialEnd),
);

class TimeRange {
  const TimeRange(this.start, this.end);
  final TimeOfDay start;
  final TimeOfDay end;
  bool get endsNextDay =>
      end.hour * 60 + end.minute < start.hour * 60 + start.minute;
  int get durationMinutes =>
      (end.hour * 60 + end.minute - start.hour * 60 - start.minute + 1440) %
      1440;
}

class _TimeRangePicker extends StatefulWidget {
  const _TimeRangePicker({this.initialStart, this.initialEnd});
  final TimeOfDay? initialStart;
  final TimeOfDay? initialEnd;
  @override
  State<_TimeRangePicker> createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<_TimeRangePicker> {
  late TimeOfDay start;
  late TimeOfDay end;
  @override
  void initState() {
    super.initState();
    start = widget.initialStart ?? TimeOfDay.now();
    end =
        widget.initialEnd ??
        TimeOfDay(hour: (start.hour + 1) % 24, minute: start.minute);
  }

  Widget _picker(String label, bool isStart) {
    final time = isStart ? start : end;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: appMuted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          height: 156,
          decoration: BoxDecoration(
            color: appSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: CupertinoTheme(
            data: CupertinoThemeData(
              primaryColor: appPrimary,
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: Theme.of(
                  context,
                ).textTheme.bodyLarge!.copyWith(fontSize: 21, color: appInk),
              ),
            ),
            child: CupertinoDatePicker(
              key: ValueKey(isStart ? 'start-time-picker' : 'end-time-picker'),
              mode: CupertinoDatePickerMode.time,
              initialDateTime: DateTime(2024, 1, 1, time.hour, time.minute),
              use24hFormat: true,
              onDateTimeChanged: (date) => setState(() {
                if (isStart) {
                  start = TimeOfDay.fromDateTime(date);
                } else {
                  end = TimeOfDay.fromDateTime(date);
                }
              }),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final range = TimeRange(start, end);
    final invalid = start == end;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: appBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Время задачи',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              '${formatTime(start)}–${formatTime(end)}',
              style: const TextStyle(
                fontSize: 20,
                color: appPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatDurationMinutes(range.durationMinutes),
              style: const TextStyle(color: appMuted),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow =
                    constraints.maxWidth < 340 ||
                    MediaQuery.textScalerOf(context).scale(14) > 20;
                return narrow
                    ? Column(
                        children: [
                          _picker('Начало', true),
                          const SizedBox(height: 20),
                          _picker('Окончание', false),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _picker('Начало', true)),
                          const SizedBox(width: 16),
                          Expanded(child: _picker('Окончание', false)),
                        ],
                      );
              },
            ),
            if (range.endsNextDay)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Окончание на следующий день',
                  style: TextStyle(color: appMuted),
                ),
              ),
            if (invalid)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Начало и окончание не должны совпадать.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: invalid
                    ? null
                    : () => Navigator.of(context).pop(range),
                child: const Text('Выбрать время'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
