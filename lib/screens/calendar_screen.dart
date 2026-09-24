import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../app_theme.dart';
import '../date_limits.dart';
import '../provider.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/task_list_item.dart';
import '../widgets/empty_tasks.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});
  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late DateTime _focusedDay;
  DateTime? _previousSelection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final selected = context.watch<TaskProvider>().selectedDate;
    if (!DateUtils.isSameDay(_previousSelection, selected)) {
      _focusedDay = selected;
      _previousSelection = selected;
    }
  }

  Future<void> _pickDate() async {
    final provider = context.read<TaskProvider>();
    final date = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: firstTaskDate,
      lastDate: lastTaskDate,
    );
    if (mounted && date != null) provider.selectDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final selected = provider.selectedDate;
    final tasks = provider.tasksByDate(selected);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь'),
        actions: [
          TextButton(
            onPressed: () {
              final today = clampTaskDate(DateTime.now());
              setState(() => _focusedDay = today);
              provider.selectDate(today);
            },
            child: const Text('Сегодня'),
          ),
          IconButton(
            tooltip: 'Выбрать дату',
            onPressed: _pickDate,
            icon: const Icon(Icons.date_range),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: TableCalendar(
                  locale: 'ru_RU',
                  rowHeight:
                      48 + MediaQuery.textScalerOf(context).scale(14) - 14,
                  daysOfWeekHeight:
                      MediaQuery.textScalerOf(context).scale(12) + 14,
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(fontSize: 12, color: appMuted),
                    weekendStyle: TextStyle(fontSize: 12, color: appMuted),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) => events.isEmpty
                        ? null
                        : Positioned(
                            bottom: 5,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: DateUtils.isSameDay(day, selected)
                                    ? Colors.white
                                    : appPrimary,
                              ),
                            ),
                          ),
                  ),
                  firstDay: firstTaskDate,
                  lastDay: lastTaskDate,
                  focusedDay: _focusedDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  selectedDayPredicate: (day) =>
                      DateUtils.isSameDay(day, selected),
                  onDaySelected: (day, focused) {
                    _focusedDay = focused;
                    provider.selectDate(day);
                  },
                  onPageChanged: (day) => _focusedDay = day,
                  onHeaderTapped: (_) => _pickDate(),
                  eventLoader: provider.tasksByDate,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      color: appPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: appPrimary,
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(
                      color: appPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    defaultTextStyle: const TextStyle(color: appInk),
                    weekendTextStyle: const TextStyle(color: appMuted),
                    outsideDaysVisible: false,
                    todayDecoration: BoxDecoration(
                      border: Border.all(color: appPrimary),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: motionDuration(context),
                          child: Text(
                            formatDayMonth(selected),
                            key: ValueKey(selected),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          formatTaskCount(tasks.length),
                          style: const TextStyle(color: appMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (tasks.isEmpty)
              const SliverToBoxAdapter(child: EmptyTasks())
            else
              SliverList.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) => TaskListItem(
                  key: ValueKey(provider.keyForTask(tasks[index])),
                  task: tasks[index],
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            openAddTaskDialog(context: context, selectedDate: selected),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }
}
