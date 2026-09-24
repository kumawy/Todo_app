import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/tasks.dart';
import '../provider.dart';
import 'add_task_dialog.dart';

// Keep the recovery action independent of the deleted row's lifecycle.
void _offerRestore(
  ScaffoldMessengerState messenger,
  TaskProvider provider,
  DeletedTask deleted, {
  String? error,
}) {
  if (!messenger.mounted) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(error ?? 'Задача «${deleted.task.title}» удалена'),
      duration: const Duration(seconds: 8),
      persist: error != null,
      showCloseIcon: error != null,
      action: SnackBarAction(
        label: error == null ? 'Отменить' : 'Повторить',
        onPressed: () async {
          try {
            await provider.restoreTask(deleted);
          } on TaskException catch (error) {
            _offerRestore(messenger, provider, deleted, error: error.message);
          }
        },
      ),
    ),
  );
}

class TaskListItem extends StatefulWidget {
  const TaskListItem({super.key, required this.task});
  final Task task;

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> {
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context.read<TaskProvider>().toggleTask(widget.task);
    } on TaskException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (_busy) return;
    final provider = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final deleted = await provider.deleteTask(widget.task);
      // The list item may be disposed after the committed deletion.
      _offerRestore(messenger, provider, deleted);
    } on TaskException catch (error) {
      if (messenger.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _menu(Task task) => PopupMenuButton<String>(
    enabled: !_busy,
    tooltip: 'Действия с задачей',
    iconSize: 20,
    padding: EdgeInsets.zero,
    onSelected: (action) async {
      if (action == 'delete') {
        await _delete();
      } else if (action == 'toggle') {
        await _toggle();
      } else if (mounted) {
        await openAddTaskDialog(
          context: context,
          selectedDate: task.date,
          task: task,
        );
      }
    },
    itemBuilder: (_) => [
      PopupMenuItem(
        value: 'toggle',
        child: Text(
          task.isDone ? 'Отметить невыполненной' : 'Отметить выполненной',
        ),
      ),
      const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
      const PopupMenuItem(
        value: 'delete',
        child: Text('Удалить', style: TextStyle(color: Color(0xFFB3261E))),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return Dismissible(
      key: ValueKey(context.read<TaskProvider>().keyForTask(task)),
      // Return false because removal is controlled by the committed storage write.
      // This also keeps a failed deletion on screen.
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _toggle();
        } else {
          await _delete();
        }
        return false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.green.shade400,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.check_circle_outline, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: AnimatedContainer(
        duration: motionDuration(context),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: task.isDone ? appSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appBorder),
          boxShadow: task.isDone
              ? []
              : const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _busy
                ? null
                : () => openAddTaskDialog(
                    context: context,
                    selectedDate: task.date,
                    task: task,
                  ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
              child: Row(
                children: [
                  Checkbox(
                    semanticLabel: task.isDone
                        ? 'Отметить невыполненной'
                        : 'Отметить выполненной',
                    value: task.isDone,
                    activeColor: appPrimary,
                    checkColor: Colors.white,
                    onChanged: _busy ? null : (_) => _toggle(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: motionDuration(context),
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(
                                fontSize: 16,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: task.isDone ? appMuted : appInk,
                                decoration: task.isDone
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                          child: Text(task.title),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${formatTime(task.startTime)}–${formatTime(task.endTime)}'
                          '${task.endsNextDay ? ' · следующий день' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: appMuted,
                          ),
                        ),
                        if (task.endsNextDay)
                          Text(
                            'Начало ${formatDayMonth(task.startsAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: appMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _menu(task),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
