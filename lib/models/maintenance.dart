import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum MaintenanceType {
  preventive('Плановое', Icons.schedule, Colors.blue),
  corrective('Ремонтное', Icons.build, Colors.orange),
  inspection('Инспекция', Icons.search, Colors.green),
  calibration('Калибровка', Icons.tune, Colors.purple),
  cleaning('Чистка', Icons.cleaning_services, Colors.teal),
  upgrade('Модернизация', Icons.upgrade, Colors.indigo);

  final String label;
  final IconData icon;
  final Color color;

  const MaintenanceType(this.label, this.icon, this.color);

  static MaintenanceType fromString(String value) {
    return MaintenanceType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MaintenanceType.preventive,
    );
  }
}

enum MaintenanceStatus {
  scheduled('Запланировано', Colors.blue, Icons.event),
  inProgress('В работе', Colors.orange, Icons.engineering),
  completed('Завершено', Colors.green, Icons.check_circle),
  cancelled('Отменено', Colors.red, Icons.cancel),
  overdue('Просрочено', Colors.deepOrange, Icons.warning);

  final String label;
  final Color color;
  final IconData icon;

  const MaintenanceStatus(this.label, this.color, this.icon);

  static MaintenanceStatus fromString(String value) {
    return MaintenanceStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MaintenanceStatus.scheduled,
    );
  }
}

class MaintenanceRecord {
  String id;
  String equipmentId;
  String equipmentName;
  MaintenanceType type;
  MaintenanceStatus status;
  String? description;
  DateTime scheduledDate;
  DateTime? completedDate;
  String? performedBy;
  double? cost;
  String? notes;
  List<String>? photos;
  int? reminderDays;
  DateTime createdAt;
  DateTime updatedAt;

  MaintenanceRecord({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.type,
    this.status = MaintenanceStatus.scheduled,
    this.description,
    required this.scheduledDate,
    this.completedDate,
    this.performedBy,
    this.cost,
    this.notes,
    this.photos,
    this.reminderDays,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipment_id': equipmentId,
      'equipment_name': equipmentName,
      'type': type.name,
      'status': status.name,
      'description': description,
      'scheduled_date': scheduledDate.toIso8601String(),
      'completed_date': completedDate?.toIso8601String(),
      'performed_by': performedBy,
      'cost': cost,
      'notes': notes,
      'photos': photos?.join(','),
      'reminder_days': reminderDays,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MaintenanceRecord.fromMap(Map<String, dynamic> map) {
    return MaintenanceRecord(
      id: map['id']?.toString() ?? '',
      equipmentId: map['equipment_id']?.toString() ?? '',
      equipmentName: map['equipment_name'] ?? '',
      type: MaintenanceType.fromString(map['type'] ?? 'preventive'),
      status: MaintenanceStatus.fromString(map['status'] ?? 'scheduled'),
      description: map['description'],
      scheduledDate: DateTime.tryParse(map['scheduled_date'] ?? '') ?? DateTime.now(),
      completedDate: map['completed_date'] != null
          ? DateTime.tryParse(map['completed_date'])
          : null,
      performedBy: map['performed_by'],
      cost: map['cost']?.toDouble(),
      notes: map['notes'],
      photos: map['photos']?.toString().split(',').where((s) => s.isNotEmpty).toList(),
      reminderDays: map['reminder_days'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get formattedScheduledDate {
    return DateFormat('dd.MM.yyyy').format(scheduledDate);
  }

  String get formattedCompletedDate {
    return completedDate != null
        ? DateFormat('dd.MM.yyyy').format(completedDate!)
        : 'Не завершено';
  }

  bool get isOverdue {
    if (status == MaintenanceStatus.completed || status == MaintenanceStatus.cancelled) {
      return false;
    }
    return DateTime.now().isAfter(scheduledDate);
  }

  bool get needsReminder {
    if (reminderDays == null || status != MaintenanceStatus.scheduled) return false;
    final reminderDate = scheduledDate.subtract(Duration(days: reminderDays!));
    return DateTime.now().isAfter(reminderDate) && DateTime.now().isBefore(scheduledDate);
  }

  int? get daysUntilDue {
    if (status == MaintenanceStatus.completed || status == MaintenanceStatus.cancelled) {
      return null;
    }
    final now = DateTime.now();
    final difference = scheduledDate.difference(now);
    return difference.inDays;
  }

  MaintenanceRecord copyWith({
    String? id,
    String? equipmentId,
    String? equipmentName,
    MaintenanceType? type,
    MaintenanceStatus? status,
    String? description,
    DateTime? scheduledDate,
    DateTime? completedDate,
    String? performedBy,
    double? cost,
    String? notes,
    List<String>? photos,
    int? reminderDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceRecord(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      performedBy: performedBy ?? this.performedBy,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
      reminderDays: reminderDays ?? this.reminderDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MaintenanceSchedule {
  String id;
  String equipmentId;
  String equipmentName;
  MaintenanceType type;
  int intervalMonths;
  String? description;
  DateTime lastMaintenance;
  DateTime nextMaintenance;
  bool isActive;
  String? assignedTo;
  DateTime createdAt;
  DateTime updatedAt;

  MaintenanceSchedule({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.type,
    required this.intervalMonths,
    this.description,
    required this.lastMaintenance,
    required this.nextMaintenance,
    this.isActive = true,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipment_id': equipmentId,
      'equipment_name': equipmentName,
      'type': type.name,
      'interval_months': intervalMonths,
      'description': description,
      'last_maintenance': lastMaintenance.toIso8601String(),
      'next_maintenance': nextMaintenance.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MaintenanceSchedule.fromMap(Map<String, dynamic> map) {
    return MaintenanceSchedule(
      id: map['id']?.toString() ?? '',
      equipmentId: map['equipment_id']?.toString() ?? '',
      equipmentName: map['equipment_name'] ?? '',
      type: MaintenanceType.fromString(map['type'] ?? 'preventive'),
      intervalMonths: map['interval_months'] ?? 3,
      description: map['description'],
      lastMaintenance: DateTime.tryParse(map['last_maintenance'] ?? '') ?? DateTime.now(),
      nextMaintenance: DateTime.tryParse(map['next_maintenance'] ?? '') ?? DateTime.now(),
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      assignedTo: map['assigned_to'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isDue {
    return DateTime.now().isAfter(nextMaintenance);
  }

  int get daysUntilDue {
    return nextMaintenance.difference(DateTime.now()).inDays;
  }

  void recalculateNextMaintenance() {
    nextMaintenance = DateTime(
      lastMaintenance.year,
      lastMaintenance.month + intervalMonths,
      lastMaintenance.day,
    );
  }
}
