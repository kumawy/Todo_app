import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../provider.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/app_drawer.dart';
import '../widgets/task_list_item.dart';
import '../widgets/week_date_strip.dart';
import '../widgets/empty_tasks.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final date = provider.selectedDate;
    final tasks = provider.tasksByDate(date);
    final title = DateUtils.isSameDay(date, DateTime.now())
        ? 'Сегодня'
        : formatDayMonth(date);
    return Scaffold(
      drawer: const AppDrawer(),
      drawerScrimColor: Colors.black.withValues(alpha: 0.18),
      backgroundColor: appPrimary,
      appBar: AppBar(
        backgroundColor: appPrimary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Мои задачи', style: TextStyle(color: Colors.white)),
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Открыть меню',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Календарь',
            onPressed: () => context.go('/calendar'),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              tooltip: 'Таймер фокуса',
              icon: const Icon(Icons.timer_outlined, color: Colors.white),
              onPressed: () => context.go('/pomodoro'),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gap = constraints.maxHeight < 400 ? 12.0 : 24.0;
          final stackHeader =
              constraints.maxWidth < 360 ||
              MediaQuery.textScalerOf(context).scale(20) > 26;
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: motionDuration(context),
                child: Text(
                  title,
                  key: ValueKey(title),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                tasks.isEmpty
                    ? formatTaskCount(0)
                    : 'Выполнено ${tasks.where((task) => task.isDone).length} из ${tasks.length}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!DateUtils.isSameDay(date, DateTime.now()))
                TextButton.icon(
                  onPressed: () => provider.selectDate(DateTime.now()),
                  icon: const Icon(Icons.today_outlined, size: 16),
                  label: const Text('Сегодня'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                ),
            ],
          );
          final addButton = Tooltip(
            message: 'Добавить задачу',
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: appPrimary,
              ),
              onPressed: () =>
                  openAddTaskDialog(context: context, selectedDate: date),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Добавить'),
            ),
          );
          final header = Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: gap),
            child: stackHeader
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [heading, const SizedBox(height: 12), addButton],
                  )
                : Row(
                    children: [
                      Expanded(child: heading),
                      const SizedBox(width: 12),
                      addButton,
                    ],
                  ),
          );
          final dateStrip = WeekDateStrip(
            selectedDate: date,
            onDateSelected: provider.selectDate,
            hasTasks: (day) => provider.tasksByDate(day).isNotEmpty,
          );
          const emptyState = EmptyTasks();
          Widget taskItem(BuildContext context, int index) => TaskListItem(
            key: ValueKey(provider.keyForTask(tasks[index])),
            task: tasks[index],
          );
          return SafeArea(
            top: false,
            bottom: false,
            child: LayoutBuilder(
              builder: (context, bodyConstraints) => Column(
                children: [
                  // Keep room for the task panel with large text or a keyboard.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: bodyConstraints.maxHeight * 0.45,
                    ),
                    child: SingleChildScrollView(child: header),
                  ),
                  Expanded(
                    child: Container(
                      key: const ValueKey('home-task-panel'),
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: LayoutBuilder(
                          builder: (context, panelConstraints) {
                            // In very short windows let the dates scroll inside
                            // the panel too, leaving every task reachable.
                            final compact =
                                panelConstraints.maxHeight <
                                MediaQuery.textScalerOf(context).scale(40) +
                                    120;
                            if (compact) {
                              return CustomScrollView(
                                key: const ValueKey('home-task-scroll'),
                                slivers: [
                                  SliverToBoxAdapter(child: dateStrip),
                                  if (tasks.isEmpty)
                                    SliverFillRemaining(
                                      hasScrollBody: false,
                                      child: emptyState,
                                    )
                                  else
                                    SliverPadding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      sliver: SliverList.builder(
                                        itemCount: tasks.length,
                                        itemBuilder: taskItem,
                                      ),
                                    ),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                dateStrip,
                                Expanded(
                                  child: tasks.isEmpty
                                      ? CustomScrollView(
                                          key: const ValueKey(
                                            'home-task-scroll',
                                          ),
                                          slivers: [
                                            SliverFillRemaining(
                                              hasScrollBody: false,
                                              child: emptyState,
                                            ),
                                          ],
                                        )
                                      : ListView.builder(
                                          key: const ValueKey(
                                            'home-task-scroll',
                                          ),
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          itemCount: tasks.length,
                                          itemBuilder: taskItem,
                                        ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
