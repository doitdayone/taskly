import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final bool done;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  @HiveField(5)
  final String syncStatus; // 'synced', 'pending_create', 'pending_update', 'pending_delete'

  Task({
    required this.id,
    required this.name,
    this.done = false,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'synced',
  });

  factory Task.create({required String name}) {
    final now = DateTime.now();
    return Task(
      id: const Uuid().v4(),
      name: name,
      createdAt: now,
      updatedAt: now,
      syncStatus: 'pending_create',
    );
  }

  Task copyWith({
    String? name,
    bool? done,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return Task(
      id: id,
      name: name ?? this.name,
      done: done ?? this.done,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  // Supabase JSON serialization (excluding syncStatus)
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      name: json['name'] as String,
      done: json['done'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      syncStatus: 'synced',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'done': done,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
