import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskList extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onDelete;
  final Function(Task) onToggle;
  final Function(Task) onEdit;

  const TaskList({
    super.key,
    required this.tasks,
    required this.onDelete,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Dismissible(
          key: Key(task.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) => onDelete(task),
          child: ListTile(
            title: Text(
              task.name,
              style: TextStyle(
                decoration: task.done ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(task.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: Checkbox(
              value: task.done,
              activeColor: Colors.red,
              onChanged: (val) => onToggle(task),
            ),
            onLongPress: () => onEdit(task),
          ),
        );
      },
    );
  }
}
