import 'package:flutter/material.dart';
import 'time_range_picker.dart';


Future<void> openAddTaskDialog({
  required BuildContext context,
  required DateTime selectedDate,
  required bool Function(String title, TimeOfDay start, TimeOfDay end)
      onSubmit,
}) {
  final controller = TextEditingController();
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  return showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "New Task",
                    style: TextStyle(
                      color: Color(0xFF4143D1),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${selectedDate.day}.${selectedDate.month}.${selectedDate.year}",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.black87, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: "Enter task...",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: Color(0xFF4143D1), width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  InkWell(
                    onTap: () async {
                      final result = await showTimeRangePicker(
                        dialogContext,
                        initialStart: startTime,
                        initialEnd: endTime,
                      );
                      if (result != null) {
                        setDialogState(() {
                          startTime = result['start'];
                          endTime = result['end'];
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: (startTime != null && endTime != null)
                            ? const Color(0xFF4143D1).withValues(alpha: 0.08)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (startTime != null && endTime != null)
                              ? const Color(0xFF4143D1)
                              : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: (startTime != null && endTime != null)
                                ? const Color(0xFF4143D1)
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (startTime != null && endTime != null)
                                ? "${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')} — "
                                    "${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}"
                                : "Set time",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: (startTime != null && endTime != null)
                                  ? const Color(0xFF4143D1)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4143D1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            if (controller.text.isEmpty) return;
                            if (startTime == null || endTime == null) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                    content: Text("Выберите время начала и конца")),
                              );
                              return;
                            }
                            final added =
                                onSubmit(controller.text, startTime!, endTime!);
                            if (added) {
                              Navigator.pop(dialogContext);
                            }
                          },
                          child: const Text("Add",
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
