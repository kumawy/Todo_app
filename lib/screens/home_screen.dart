import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tasks.dart';
import '../provider.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/app_drawer.dart';
import '../widgets/task_list_item.dart';
import '../widgets/week_date_strip.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  DateTime selectedDate = DateTime.now();

  List<Task> get filteredTasks {
    final provider = context.watch<TaskProvider>();
    return provider.tasksByDate(selectedDate);
  }


  bool addTask(String title, TimeOfDay startTime, TimeOfDay endTime) {
    final provider = context.read<TaskProvider>();

    final newTask = Task.fromTime(
      title: title,
      date: selectedDate,
      startTime: startTime,
      endTime: endTime,
    );

    final hasConflict = provider.tasks.any((task) {
      if (task.date.day != selectedDate.day ||
          task.date.month != selectedDate.month ||
          task.date.year != selectedDate.year) {
        return false;
      }

      final newStart = startTime.hour * 60 + startTime.minute;
      final newEnd = endTime.hour * 60 + endTime.minute;

      final existingStart = task.startTime.hour * 60 + task.startTime.minute;
      final existingEnd = task.endTime.hour * 60 + task.endTime.minute;

      return newStart < existingEnd && newEnd > existingStart;
    });

    if (hasConflict) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Время пересекается!")),
      );
      return false;
    }

    provider.addTask(newTask);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer() ,
      backgroundColor: const Color(0xFF4143D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4143D1),
        title: Text(
          "${selectedDate.day} ${[
            'january', 'february', 'march', 'april', 'may', 'june',
            'july', 'august', 'september', 'october', 'november', 'december'
          ][selectedDate.month - 1]}",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                icon: const Icon(Icons.menu,color: Colors.white),);
            }
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: const Icon(Icons.timer, color: Colors.white),
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${filteredTasks.length} Tasks",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: () => openAddTaskDialog(
                    context: context,
                    selectedDate: selectedDate,
                    onSubmit: addTask,
                  ),
                  child: const Text(
                    "Add Task",
                    style: TextStyle(fontSize: 20, color: Color(0xFF4143D1)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                ),
              ),
              width: double.infinity,
              child: Column(
                children: [
                  WeekDateStrip(
                    selectedDate: selectedDate,
                    onDateSelected: (date) {
                      setState(() {
                        selectedDate = date;
                      });
                    },
                  ),
                  Expanded(
                    child: filteredTasks.isEmpty
                        ? Center(
                      child: Text(
                        "No tasks for this day",
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    )
                        : ListView.builder(
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, i) {
                        return TaskListItem(task: filteredTasks[i]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}