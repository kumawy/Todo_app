import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/tasks.dart';
import '../provider.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  List<Task> getTasksForDay(DateTime day, List<Task> tasks) {
    return tasks.where((task) {
      return task.date.day == day.day &&
          task.date.month == day.month &&
          task.date.year == day.year;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final tasks = getTasksForDay(selectedDay, provider.tasks);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar"),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, selectedDay),

            onDaySelected: (selected, focused) {
              setState(() {
                selectedDay = selected;
                focusedDay = focused;
              });
            },

            eventLoader: (day) => getTasksForDay(day, provider.tasks),

            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xFF4143D1),
                shape: BoxShape.circle,
              ),

            ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: Color(0xFF4143D1),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
          ),

          const SizedBox(height: 10),

          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text("No tasks"))
                : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, i) {
                final task = tasks[i];

                return ListTile(
                  title: Text(task.title),
                  subtitle: Text(
                    "${task.startTime.format(context)} - ${task.endTime.format(context)}",
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}