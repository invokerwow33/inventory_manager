import 'package:flutter/material.dart';

enum AuditActionType {
  create('Создание', Icons.add_circle, Colors.green),
  update('Изменение', Icons.edit, Colors.orange),
  delete('Удаление', Icons.delete, Colors.red),
  view('Просмотр', Icons.visibility, Colors.blue),
  export('Экспорт', Icons.download, Colors.purple),
  import('Импорт', Icons.upload, Colors.teal),
  login('Вход', Icons.login, Colors.indigo),
  logout('Выход', Icons.logout, Colors.grey),
  backup('Резервное копирование', Icons.backup, Colors.cyan),
  restore('Восстановление', Icons.restore, Colors.deepOrange),
  movement('Перемещение', Icons.swap_horiz, Colors.amber),
  bulk('Массовая операция', Icons.select_all, Colors.pink);

  final String label;
  final IconData icon;
  final Color color;

  const AuditActionType(this.label, this.icon, this.color);

  static AuditActionType fromString(String value) {
    return AuditActionType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AuditActionType.view,
    );
  }
}

enum AuditEntityType {
  equipment('Оборудование'),
  employee('Сотрудник'),
  consumable('Расходник'),
  movement('Перемещение'),
  user('Пользователь'),
  document('Документ'),
  room('Помещение'),
  key('Ключ'),
  vehicle('Транспорт'),
  phone('Телефония'),
  settings('Настройки'),
  system('Система');

  final String label;

  const AuditEntityType(this.label);

  static AuditEntityType fromString(String value) {
    return AuditEntityType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AuditEntityType.system,
    );
  }
}

class AuditLog {
  int? id;
  String userId;
  String? username;
  AuditActionType actionType;
  AuditEntityType entityType;
  String entityId;
  String? entityName;
  Map<String, dynamic>? oldValues;
  Map<String, dynamic>? newValues;
  String? description;
  DateTime timestamp;
  String? ipAddress;
  String? userAgent;
  String? sessionId;

  AuditLog({
    this.id,
    required this.userId,
    this.username,
    required this.actionType,
    required this.entityType,
    required this.entityId,
    this.entityName,
    this.oldValues,
    this.newValues,
    this.description,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
    this.sessionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'action_type': actionType.name,
      'entity_type': entityType.name,
      'entity_id': entityId,
      'entity_name': entityName,
      'old_values': oldValues?.toString(),
      'new_values': newValues?.toString(),
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'session_id': sessionId,
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'],
      userId: map['user_id']?.toString() ?? '',
      username: map['username'],
      actionType: AuditActionType.fromString(map['action_type'] ?? 'view'),
      entityType: AuditEntityType.fromString(map['entity_type'] ?? 'system'),
      entityId: map['entity_id']?.toString() ?? '',
      entityName: map['entity_name'],
      description: map['description'],
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      ipAddress: map['ip_address'],
      userAgent: map['user_agent'],
      sessionId: map['session_id'],
    );
  }

  String get formattedTimestamp {
    return '${timestamp.day.toString().padLeft(2, '0')}.${timestamp.month.toString().padLeft(2, '0')}.${timestamp.year} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }

  String get actionLabel => actionType.label;
  IconData get actionIcon => actionType.icon;
  Color get actionColor => actionType.color;
  String get entityLabel => entityType.label;
}

class DataVersion {
  int? id;
  String entityType;
  String entityId;
  int versionNumber;
  Map<String, dynamic> data;
  String changedBy;
  DateTime changedAt;
  String? changeDescription;

  DataVersion({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.versionNumber,
    required this.data,
    required this.changedBy,
    required this.changedAt,
    this.changeDescription,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'version_number': versionNumber,
      'data': data.toString(),
      'changed_by': changedBy,
      'changed_at': changedAt.toIso8601String(),
      'change_description': changeDescription,
    };
  }

  factory DataVersion.fromMap(Map<String, dynamic> map) {
    return DataVersion(
      id: map['id'],
      entityType: map['entity_type'] ?? '',
      entityId: map['entity_id']?.toString() ?? '',
      versionNumber: map['version_number'] ?? 1,
      data: {},
      changedBy: map['changed_by'] ?? '',
      changedAt: DateTime.tryParse(map['changed_at'] ?? '') ?? DateTime.now(),
      changeDescription: map['change_description'],
    );
  }
}
