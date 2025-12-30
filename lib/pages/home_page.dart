import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';

class HomePage extends StatefulWidget {
  final TaskRepository repository;
  final Box<Task> taskBox;

  const HomePage({super.key, required this.repository, required this.taskBox});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Trigger sync on startup
    widget.repository.syncTasksWithApi();
  }

  void _showAddTaskDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task', style: TextStyle(color: Colors.red)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'What needs to be done?'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                widget.repository.addTask(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Taskly!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete All?'),
                  content: const Text(
                    'Are you sure you want to delete all tasks?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.repository.deleteAllTasks();
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: widget.taskBox.listenable(),
        builder: (context, Box<Task> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('No tasks yet!'));
          }

          // Sort by createdAt descending
          final tasks = box.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
                onDismissed: (direction) {
                  widget.repository.deleteTask(task);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${task.name} deleted')),
                  );
                },
                child: ListTile(
                  title: Text(
                    task.name,
                    style: TextStyle(
                      decoration: task.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat(
                      'yyyy-MM-dd HH:mm:ss.SSS',
                    ).format(task.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: Checkbox(
                    value: task.done,
                    activeColor: Colors.red,
                    onChanged: (val) {
                      widget.repository.toggleTask(task);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
