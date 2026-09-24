final firstTaskDate = DateTime(1900);
final lastTaskDate = DateTime(2200, 12, 31);

DateTime clampTaskDate(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  if (day.isBefore(firstTaskDate)) return firstTaskDate;
  if (day.isAfter(lastTaskDate)) return lastTaskDate;
  return day;
}
