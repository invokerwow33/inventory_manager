import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_manager/models/task.dart';

void main() {
  group('Task Model', () {
    test('should create Task with required fields', () {
      final task = Task(
        id: 'task_1',
        title: 'Test Task',
        description: 'Test Description',
        createdBy: 'user_1',
        createdByName: 'Test User',
        createdAt: DateTime.now(),
        status: TaskStatus.pending,
        priority: TaskPriority.normal,
      );

      expect(task.id, 'task_1');
      expect(task.title, 'Test Task');
      expect(task.description, 'Test Description');
      expect(task.status, TaskStatus.pending);
      expect(task.priority, TaskPriority.normal);
    });

    test('should convert to map and back', () {
      final now = DateTime.now();
      final task = Task(
        id: 'task_1',
        title: 'Test Task',
        description: 'Test Description',
        createdBy: 'user_1',
        createdByName: 'Test User',
        createdAt: now,
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
      );

      final map = task.toMap();
      final taskFromMap = Task.fromMap(map);

      expect(taskFromMap.id, task.id);
      expect(taskFromMap.title, task.title);
      expect(taskFromMap.status, task.status);
      expect(taskFromMap.priority, task.priority);
    });

    test('should identify overdue tasks correctly', () {
      final overdueTask = Task(
        id: 'task_1',
        title: 'Overdue Task',
        description: 'Description',
        createdBy: 'user_1',
        createdByName: 'Test User',
        createdAt: DateTime.now(),
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        status: TaskStatus.pending,
        priority: TaskPriority.normal,
      );

      expect(overdueTask.isOverdue, true);
    });

    test('should not mark completed tasks as overdue', () {
      final completedTask = Task(
        id: 'task_1',
        title: 'Completed Task',
        description: 'Description',
        createdBy: 'user_1',
        createdByName: 'Test User',
        createdAt: DateTime.now(),
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        status: TaskStatus.completed,
        priority: TaskPriority.normal,
      );

      expect(completedTask.isOverdue, false);
    });
  });

  group('TaskStatus', () {
    test('should have correct values', () {
      expect(TaskStatus.values.length, 5);
      expect(TaskStatus.values.contains(TaskStatus.pending), true);
      expect(TaskStatus.values.contains(TaskStatus.inProgress), true);
      expect(TaskStatus.values.contains(TaskStatus.completed), true);
      expect(TaskStatus.values.contains(TaskStatus.cancelled), true);
      expect(TaskStatus.values.contains(TaskStatus.onHold), true);
    });
  });

  group('TaskPriority', () {
    test('should have correct values', () {
      expect(TaskPriority.values.length, 4);
      expect(TaskPriority.values.contains(TaskPriority.low), true);
      expect(TaskPriority.values.contains(TaskPriority.normal), true);
      expect(TaskPriority.values.contains(TaskPriority.high), true);
      expect(TaskPriority.values.contains(TaskPriority.critical), true);
    });
  });
}
