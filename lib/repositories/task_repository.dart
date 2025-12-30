import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';

class TaskRepository {
  final Box<Task> _box;
  final SupabaseClient _supabase;

  TaskRepository(this._box, this._supabase);

  /// Syncs tasks between Hive (local) and Supabase (remote).
  /// Truth source for conflict: API (Last Write Wins usually, but here simplifies to API timestamp check).
  Future<void> syncTasksWithApi() async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .order('created_at');

      final List<Task> apiTasks = (response as List)
          .map((e) => Task.fromJson(e))
          .toList();

      final Map<String, Task> apiMap = {
        for (var task in apiTasks) task.id: task,
      };

      // 1. Update & Delete Local
      final keysToDelete = <String>[];
      for (final key in _box.keys) {
        final localTask = _box.get(key);
        if (localTask == null) continue;

        // Don't delete local tasks that are pending creation
        if (localTask.syncStatus == 'pending_create') continue;

        final apiTask = apiMap[localTask.id];

        if (apiTask == null) {
          // Exists in Hive but not API.
          // If it's not pending create, it means it was deleted on server (or never synced).
          // We assume deleted on server.
          keysToDelete.add(localTask.id);
        } else {
          // Exists in both. Update if API is newer.
          if (apiTask.updatedAt.isAfter(localTask.updatedAt)) {
            await _box.put(localTask.id, apiTask);
          }
        }
      }

      await _box.deleteAll(keysToDelete);

      // 2. Add New from API
      for (final apiTask in apiTasks) {
        if (!_box.containsKey(apiTask.id)) {
          await _box.put(apiTask.id, apiTask);
        }
      }

      // 3. Retry Pending Syncs (Background)
      await _pushPendingChanges();
    } catch (e) {
      debugPrint('Sync error: $e');
      // Quiet fail for sync
    }
  }

  Future<void> _pushPendingChanges() async {
    for (final task in _box.values) {
      if (task.syncStatus == 'pending_create') {
        await _createApiTask(task);
      } else if (task.syncStatus == 'pending_update') {
        await _updateApiTask(task);
      }
    }
  }

  Future<void> addTask(String name) async {
    final task = Task.create(name: name);
    // Local first
    await _box.put(task.id, task);

    try {
      await _createApiTask(task);
    } catch (e) {
      debugPrint('Add Task Error: $e');
      // Remains pending_create
    }
  }

  Future<void> _createApiTask(Task task) async {
    await _supabase.from('tasks').insert(task.toJson());
    // Update status to synced
    await _box.put(task.id, task.copyWith(syncStatus: 'synced'));
  }

  Future<void> toggleTask(Task task) async {
    final updated = task.copyWith(
      done: !task.done,
      updatedAt: DateTime.now(),
      syncStatus: 'pending_update',
    );
    await _box.put(updated.id, updated);

    try {
      await _updateApiTask(updated);
    } catch (e) {
      debugPrint('Toggle Task Error: $e');
      // Remains pending_update
    }
  }

  Future<void> _updateApiTask(Task task) async {
    await _supabase.from('tasks').update(task.toJson()).eq('id', task.id);
    await _box.put(task.id, task.copyWith(syncStatus: 'synced'));
  }

  Future<void> updateTask(Task task, String newName) async {
    final updated = task.copyWith(
      name: newName,
      updatedAt: DateTime.now(),
      syncStatus: 'pending_update',
    );
    await _box.put(updated.id, updated);

    try {
      await _updateApiTask(updated);
    } catch (e) {
      debugPrint('Update Task Error: $e');
    }
  }

  Future<void> deleteTask(Task task) async {
    // Backup for rollback
    final backup = task;

    // Optimistic Delete
    await _box.delete(task.id);

    try {
      await _supabase.from('tasks').delete().eq('id', task.id);
    } catch (e) {
      debugPrint('Delete Task Error: $e');
      // Rollback on failure
      await _box.put(backup.id, backup); // Restores the task
      rethrow; // Or show snackbar in UI
    }
  }

  Future<void> deleteAllTasks() async {
    // Backup keys for rollback
    final backup = Map<String, Task>.fromEntries(
      _box.values.map((e) => MapEntry(e.id, e)),
    );

    // Optimistic Delete All Local
    await _box.clear();

    try {
      // Delete All Remote
      // Note: Supabase doesn't support "delete all without where" easily in some SDK versions for safety,
      // but "neq" (not equal) logic or deleting by ID list works.
      // Deleting all rows:
      await _supabase
          .from('tasks')
          .delete()
          .neq(
            'id',
            '00000000-0000-0000-0000-000000000000',
          ); // Hack to delete all
    } catch (e) {
      debugPrint('Delete All Error: $e');
      // Rollback
      await _box.putAll(backup);
      rethrow;
    }
  }
}
