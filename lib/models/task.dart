import 'package:flutter/material.dart';

/// Задача, выданная директором сотруднику
class Task {
  String id;
  String title;
  String description;
  String createdBy; // ID директора
  String createdByName; // Имя директора
  String? assignedTo; // ID сотрудника (null = всем)
  String? assignedToName; // Имя сотрудника
  TaskStatus status;
  TaskPriority priority;
  DateTime createdAt;
  DateTime? updatedAt; // Последнее обновление
  DateTime? dueDate; // Дедлайн
  DateTime? startedAt; // Начал выполнение
  DateTime? completedAt; // Завершил
  String? notes; // Заметки от директора

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdByName,
    this.assignedTo,
    this.assignedToName,
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.normal,
    required this.createdAt,
    this.updatedAt,
    this.dueDate,
    this.startedAt,
    this.completedAt,
    this.notes,
  });

  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!) && status != TaskStatus.completed;
  
  int get daysUntilDue {
    if (dueDate == null) return -1;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'assigned_to': assignedTo,
      'assigned_to_name': assignedToName,
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
      // updated_at исключено из-за проблем с миграцией
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['created_by']?.toString() ?? '',
      createdByName: map['created_by_name'] ?? '',
      assignedTo: map['assigned_to'],
      assignedToName: map['assigned_to_name'],
      status: TaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => TaskStatus.pending,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString().split('.').last == map['priority'],
        orElse: () => TaskPriority.normal,
      ),
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? ''),
      dueDate: DateTime.tryParse(map['due_date'] ?? ''),
      startedAt: DateTime.tryParse(map['started_at'] ?? ''),
      completedAt: DateTime.tryParse(map['completed_at'] ?? ''),
      notes: map['notes'],
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    String? createdByName,
    String? assignedTo,
    String? assignedToName,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    DateTime? startedAt,
    DateTime? completedAt,
    String? notes,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }
}

/// Статус задачи
enum TaskStatus {
  pending('Назначена', Colors.grey),
  inProgress('В работе', Colors.blue),
  onHold('На паузе', Colors.orange),
  completed('Выполнена', Colors.green),
  cancelled('Отменена', Colors.red);

  final String label;
  final Color color;

  const TaskStatus(this.label, this.color);
}

/// Приоритет задачи
enum TaskPriority {
  low('Низкий', Colors.grey),
  normal('Средний', Colors.blue),
  high('Высокий', Colors.orange),
  critical('Критичный', Colors.red);

  final String label;
  final Color color;

  const TaskPriority(this.label, this.color);
}

/// Комментарий к задаче (чат)
class TaskComment {
  String id;
  String taskId;
  String authorId;
  String authorName;
  String message;
  DateTime createdAt;
  bool isSystem; // Системное сообщение (смена статуса)

  TaskComment({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.authorName,
    required this.message,
    required this.createdAt,
    this.isSystem = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'author_id': authorId,
      'author_name': authorName,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_system': isSystem ? 1 : 0,
    };
  }

  factory TaskComment.fromMap(Map<String, dynamic> map) {
    return TaskComment(
      id: map['id']?.toString() ?? '',
      taskId: map['task_id']?.toString() ?? '',
      authorId: map['author_id']?.toString() ?? '',
      authorName: map['author_name'] ?? '',
      message: map['message'] ?? '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      isSystem: (map['is_system'] ?? 0) == 1,
    );
  }

  TaskComment copyWith({
    String? id,
    String? taskId,
    String? authorId,
    String? authorName,
    String? message,
    DateTime? createdAt,
    bool? isSystem,
  }) {
    return TaskComment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isSystem: isSystem ?? this.isSystem,
    );
  }
}
