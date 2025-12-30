import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/task.dart';
import 'pages/home_page.dart';
import 'repositories/task_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "env/.env");

  // 1. Init Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 2. Init Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  final taskBox = await Hive.openBox<Task>('tasks');

  // 3. Create Repository
  final repository = TaskRepository(taskBox, Supabase.instance.client);

  runApp(MyApp(repository: repository, taskBox: taskBox));
}

class MyApp extends StatelessWidget {
  final TaskRepository repository;
  final Box<Task> taskBox;

  const MyApp({super.key, required this.repository, required this.taskBox});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskly',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: HomePage(repository: repository, taskBox: taskBox),
    );
  }
}
