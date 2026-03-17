import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  List<TaskComment> _comments = [];
  Task? _selectedTask;
  bool _isLoading = false;
  String? _error;

  // Filters
  TaskStatus? _filterStatus;
  TaskPriority? _filterPriority;
  String? _searchQuery;

  // Getters
  List<Task> get tasks => _filteredTasks.isEmpty ? _tasks : _filteredTasks;
  List<Task> get allTasks => _tasks;
  List<TaskComment> get comments => _comments;
  Task? get selectedTask => _selectedTask;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Statistics
  Map<String, int> get statistics {
    final pending = _tasks.where((t) => t.status == TaskStatus.pending).length;
    final inProgress = _tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final completed = _tasks.where((t) => t.status == TaskStatus.completed).length;
    final overdue = _tasks.where((t) => t.isOverdue).length;
    
    return {
      'total': _tasks.length,
      'pending': pending,
      'inProgress': inProgress,
      'completed': completed,
      'overdue': overdue,
    };
  }

  // Load tasks
  Future<void> loadTasks({
    String? assignedTo,
    String? createdBy,
    bool forceRefresh = false,
  }) async {
    // Всегда загружаем если forceRefresh или если список пуст
    if (!forceRefresh && _tasks.isNotEmpty) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final data = await _dbHelper.getTasks(
        assignedTo: assignedTo,
        createdBy: createdBy,
      );
      _tasks = data.map((map) => Task.fromMap(map)).toList();
      _filteredTasks = List.from(_tasks);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки задач: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create task
  Future<void> createTask(Task task) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.createTask(task.toMap());
      // Не добавляем задачу вручную, так как она будет загружена при следующем loadTasks
      // Просто уведомляем об изменении
      notifyListeners();
    } catch (e) {
      _setError('Ошибка создания задачи: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update task
  Future<void> updateTask(Task task) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.updateTask(task.toMap());
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
      }
      if (_selectedTask?.id == task.id) {
        _selectedTask = task;
      }
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка обновления задачи: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update task status
  Future<void> updateTaskStatus(String id, TaskStatus status) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.updateTaskStatus(id, status.toString().split('.').last);
      
      final taskIndex = _tasks.indexWhere((t) => t.id == id);
      if (taskIndex != -1) {
        final task = _tasks[taskIndex];
        final updatedTask = task.copyWith(
          status: status,
          startedAt: status == TaskStatus.inProgress ? DateTime.now() : task.startedAt,
          completedAt: status == TaskStatus.completed ? DateTime.now() : task.completedAt,
        );
        _tasks[taskIndex] = updatedTask;
        
        if (_selectedTask?.id == id) {
          _selectedTask = updatedTask;
        }
      }
      
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка обновления статуса: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete task
  Future<void> deleteTask(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.deleteTask(id);
      _tasks.removeWhere((t) => t.id == id);
      if (_selectedTask?.id == id) {
        _selectedTask = null;
      }
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка удаления задачи: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Load comments for a task
  Future<void> loadComments(String taskId) async {
    _setLoading(true);
    _clearError();

    try {
      final data = await _dbHelper.getTaskComments(taskId);
      _comments = data.map((map) => TaskComment.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки комментариев: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add comment
  Future<void> addComment(TaskComment comment) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.addTaskComment(comment.toMap());
      _comments.add(comment);
      notifyListeners();
    } catch (e) {
      _setError('Ошибка добавления комментария: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Add system comment (status change)
  Future<void> addSystemComment(String taskId, String message) async {
    final comment = TaskComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: taskId,
      authorId: 'system',
      authorName: 'Система',
      message: message,
      createdAt: DateTime.now(),
      isSystem: true,
    );
    await addComment(comment);
  }

  // Select task
  void selectTask(Task? task) {
    _selectedTask = task;
    notifyListeners();
  }

  // Clear selection
  void clearSelection() {
    _selectedTask = null;
    notifyListeners();
  }

  // Apply filters
  void applyFilters() {
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredTasks = _tasks.where((task) {
      // Status filter
      if (_filterStatus != null && task.status != _filterStatus) return false;
      
      // Priority filter
      if (_filterPriority != null && task.priority != _filterPriority) return false;
      
      // Search filter
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        final query = _searchQuery!.toLowerCase();
        return task.title.toLowerCase().contains(query) ||
               task.description.toLowerCase().contains(query) ||
               (task.assignedToName?.toLowerCase().contains(query) ?? false) ||
               task.createdByName.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();

    // Sort: overdue first, then by priority, then by created date
    _filteredTasks.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      
      final priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  // Set filters
  void setFilterStatus(TaskStatus? status) {
    _filterStatus = status;
    _applyFilters();
    notifyListeners();
  }

  void setFilterPriority(TaskPriority? priority) {
    _filterPriority = priority;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _filterStatus = null;
    _filterPriority = null;
    _searchQuery = null;
    _applyFilters();
    notifyListeners();
  }

  // Get tasks by status
  List<Task> getTasksByStatus(TaskStatus status) {
    return _tasks.where((t) => t.status == status).toList();
  }

  // Get overdue tasks
  List<Task> getOverdueTasks() {
    return _tasks.where((t) => t.isOverdue).toList();
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
