import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

Future<Map<String, TimeOfDay>?> showTimeRangePicker(
    BuildContext context, {
      TimeOfDay? initialStart,
      TimeOfDay? initialEnd,
    }) async {
  TimeOfDay start = initialStart ?? TimeOfDay.now();
  TimeOfDay end = initialEnd ??
      TimeOfDay(hour: (start.hour + 1) % 24, minute: start.minute);

  return showModalBottomSheet<Map<String, TimeOfDay>>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final startMinutes = start.hour * 60 + start.minute;
          final endMinutes = end.hour * 60 + end.minute;
          final hasConflict = endMinutes <= startMinutes;

          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Select time",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                const Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          "Start",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4143D1),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "End",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4143D1),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: 180,
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.time,
                          initialDateTime:
                          DateTime(2024, 1, 1, start.hour, start.minute),
                          use24hFormat: true,
                          onDateTimeChanged: (dt) {
                            setModalState(() {
                              start = TimeOfDay(hour: dt.hour, minute: dt.minute);
                            });
                          },
                        ),
                      ),
                      Container(
                          width: 1, height: 140, color: Colors.grey.shade200),
                      Expanded(
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.time,
                          initialDateTime:
                          DateTime(2024, 1, 1, end.hour, end.minute),
                          use24hFormat: true,
                          onDateTimeChanged: (dt) {
                            setModalState(() {
                              end = TimeOfDay(hour: dt.hour, minute: dt.minute);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                if (hasConflict)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "End time must be after start time",
                      style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                    ),
                  ),

                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasConflict
                            ? Colors.grey.shade300
                            : const Color(0xFF4143D1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: hasConflict
                          ? null
                          : () => Navigator.pop(context, {
                        'start': start,
                        'end': end,
                      }),
                      child: const Text("Done",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
