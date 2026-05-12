import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_manager/providers/task_provider.dart';

void main() {
  group('TaskProvider', () {
    late TaskProvider provider;

    setUp(() {
      provider = TaskProvider();
    });

    test('should have empty task list initially', () {
      expect(provider.tasks, isEmpty);
      expect(provider.allTasks, isEmpty);
      expect(provider.comments, isEmpty);
      expect(provider.selectedTask, isNull);
    });

    test('should have correct initial state', () {
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });

    test('should calculate statistics correctly with empty list', () {
      final stats = provider.statistics;
      expect(stats['total'], 0);
      expect(stats['pending'], 0);
      expect(stats['inProgress'], 0);
      expect(stats['completed'], 0);
      expect(stats['overdue'], 0);
    });

    test('should clear error', () {
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('should clear filters', () {
      provider.clearFilters();
      expect(provider.tasks, isEmpty);
    });

    test('should clear selection', () {
      provider.clearSelection();
      expect(provider.selectedTask, isNull);
    });
  });
}
