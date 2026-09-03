import 'package:flutter/material.dart';

class WeekDateStrip extends StatelessWidget {
  const WeekDateStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.daysToShow = 7,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final int daysToShow;

  static const _weekdayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Padding(
        padding: const EdgeInsets.only(left: 40),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: daysToShow,
          itemBuilder: (context, index) {
            final date = DateTime.now().add(Duration(days: index));

            final isSelected = date.day == selectedDate.day &&
                date.month == selectedDate.month;

            return GestureDetector(
              onTap: () => onDateSelected(date),
              child: Container(
                width: 60,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4143D1) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${date.day}",
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _weekdayLabels[date.weekday - 1],
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}