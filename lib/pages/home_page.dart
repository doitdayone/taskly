import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';
import '../widgets/task_list.dart';

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

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All?'),
        content: const Text('Are you sure you want to delete all tasks?'),
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(Task task) {
    final controller = TextEditingController(text: task.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Task', style: TextStyle(color: Colors.red)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Task name'),
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
                widget.repository.updateTask(task, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.red)),
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
            color: Colors.white,
            onPressed: _showDeleteAllDialog,
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

          return TaskList(
            tasks: tasks,
            onDelete: (task) {
              widget.repository.deleteTask(task);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('${task.name} deleted')));
            },
            onToggle: (task) {
              widget.repository.toggleTask(task);
            },
            onEdit: (task) {
              _showEditTaskDialog(task);
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
