import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../date_limits.dart';

class WeekDateStrip extends StatelessWidget {
  const WeekDateStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.daysToShow = 7,
    this.hasTasks,
  });
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final int daysToShow;
  final bool Function(DateTime)? hasTasks;
  static const _labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final afterStrip = DateTime(
      today.year,
      today.month,
      today.day + daysToShow,
    );
    final firstDay = clampTaskDate(
      !selectedDate.isBefore(today) && selectedDate.isBefore(afterStrip)
          ? today
          : selectedDate,
    );
    final dates = List.generate(
      daysToShow,
      (index) => DateTime(firstDay.year, firstDay.month, firstDay.day + index),
    ).takeWhile((date) => !date.isAfter(lastTaskDate));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: dates.map((date) {
          final selected = DateUtils.isSameDay(date, selectedDate);
          final isToday = DateUtils.isSameDay(date, today);
          final occupied = hasTasks?.call(date) ?? false;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              selected: selected,
              button: true,
              label:
                  '${formatDate(date)}${isToday ? ', сегодня' : ''}${occupied ? ', есть задачи' : ''}',
              child: AnimatedContainer(
                duration: motionDuration(context),
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(minWidth: 56),
                decoration: BoxDecoration(
                  color: selected ? appPrimary : appSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isToday && !selected
                        ? appPrimary
                        : Colors.transparent,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onDateSelected(date),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : appInk,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _labels[date.weekday - 1],
                            style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : appMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedContainer(
                            duration: motionDuration(context),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: occupied
                                  ? (selected ? Colors.white : appPrimary)
                                  : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
