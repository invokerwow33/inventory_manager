import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum SyncOperationType {
  create('Создание', Icons.add, Colors.green),
  update('Обновление', Icons.edit, Colors.orange),
  delete('Удаление', Icons.delete, Colors.red),
  upload('Загрузка', Icons.upload, Colors.blue),
  download('Скачивание', Icons.download, Colors.purple);

  final String label;
  final IconData icon;
  final Color color;

  const SyncOperationType(this.label, this.icon, this.color);

  static SyncOperationType fromString(String value) {
    return SyncOperationType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SyncOperationType.create,
    );
  }
}

enum SyncStatus {
  pending('В ожидании', Colors.grey, Icons.schedule),
  syncing('В процессе', Colors.blue, Icons.sync),
  completed('Завершено', Colors.green, Icons.check_circle),
  failed('Ошибка', Colors.red, Icons.error),
  conflict('Конфликт', Colors.orange, Icons.warning);

  final String label;
  final Color color;
  final IconData icon;

  const SyncStatus(this.label, this.color, this.icon);

  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SyncStatus.pending,
    );
  }
}

enum SyncPriority {
  low(1, 'Низкий'),
  normal(2, 'Нормальный'),
  high(3, 'Высокий'),
  critical(4, 'Критический');

  final int value;
  final String label;

  const SyncPriority(this.value, this.label);

  static SyncPriority fromValue(int value) {
    return SyncPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SyncPriority.normal,
    );
  }
}

class SyncQueueItem {
  String id;
  SyncOperationType operation;
  String entityType;
  String entityId;
  Map<String, dynamic>? data;
  SyncStatus status;
  SyncPriority priority;
  String? errorMessage;
  int retryCount;
  DateTime? lastAttempt;
  DateTime createdAt;
  String? deviceId;
  String? userId;

  SyncQueueItem({
    required this.id,
    required this.operation,
    required this.entityType,
    required this.entityId,
    this.data,
    this.status = SyncStatus.pending,
    this.priority = SyncPriority.normal,
    this.errorMessage,
    this.retryCount = 0,
    this.lastAttempt,
    required this.createdAt,
    this.deviceId,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operation': operation.name,
      'entity_type': entityType,
      'entity_id': entityId,
      'data': data?.toString(),
      'status': status.name,
      'priority': priority.value,
      'error_message': errorMessage,
      'retry_count': retryCount,
      'last_attempt': lastAttempt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'device_id': deviceId,
      'user_id': userId,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id']?.toString() ?? '',
      operation: SyncOperationType.fromString(map['operation'] ?? 'create'),
      entityType: map['entity_type'] ?? '',
      entityId: map['entity_id']?.toString() ?? '',
      status: SyncStatus.fromString(map['status'] ?? 'pending'),
      priority: SyncPriority.fromValue(map['priority'] ?? 2),
      errorMessage: map['error_message'],
      retryCount: map['retry_count'] ?? 0,
      lastAttempt: map['last_attempt'] != null
          ? DateTime.tryParse(map['last_attempt'])
          : null,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      deviceId: map['device_id'],
      userId: map['user_id'],
    );
  }

  bool get canRetry {
    if (status == SyncStatus.completed) return false;
    if (retryCount >= 5) return false;
    return true;
  }

  Duration get backoffDelay {
    final baseDelay = Duration(seconds: 5);
    final multiplier = retryCount * retryCount;
    return baseDelay * multiplier;
  }

  void incrementRetry() {
    retryCount++;
    lastAttempt = DateTime.now();
  }

  String get formattedCreatedAt {
    return DateFormat('dd.MM.yyyy HH:mm:ss').format(createdAt);
  }

  String get formattedLastAttempt {
    return lastAttempt != null
        ? DateFormat('dd.MM.yyyy HH:mm:ss').format(lastAttempt!)
        : 'Не было попыток';
  }
}

class SyncConflict {
  String id;
  String entityType;
  String entityId;
  Map<String, dynamic> localData;
  Map<String, dynamic> remoteData;
  DateTime localTimestamp;
  DateTime remoteTimestamp;
  String? resolvedData;
  bool isResolved;
  String? resolution;
  DateTime createdAt;
  DateTime? resolvedAt;

  SyncConflict({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.localData,
    required this.remoteData,
    required this.localTimestamp,
    required this.remoteTimestamp,
    this.resolvedData,
    this.isResolved = false,
    this.resolution,
    required this.createdAt,
    this.resolvedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'local_data': localData.toString(),
      'remote_data': remoteData.toString(),
      'local_timestamp': localTimestamp.toIso8601String(),
      'remote_timestamp': remoteTimestamp.toIso8601String(),
      'resolved_data': resolvedData,
      'is_resolved': isResolved ? 1 : 0,
      'resolution': resolution,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  factory SyncConflict.fromMap(Map<String, dynamic> map) {
    return SyncConflict(
      id: map['id']?.toString() ?? '',
      entityType: map['entity_type'] ?? '',
      entityId: map['entity_id']?.toString() ?? '',
      localData: {},
      remoteData: {},
      localTimestamp: DateTime.tryParse(map['local_timestamp'] ?? '') ?? DateTime.now(),
      remoteTimestamp: DateTime.tryParse(map['remote_timestamp'] ?? '') ?? DateTime.now(),
      resolvedData: map['resolved_data'],
      isResolved: map['is_resolved'] == 1 || map['is_resolved'] == true,
      resolution: map['resolution'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      resolvedAt: map['resolved_at'] != null
          ? DateTime.tryParse(map['resolved_at'])
          : null,
    );
  }

  bool get isLocalNewer => localTimestamp.isAfter(remoteTimestamp);
}

class DeviceSyncInfo {
  String id;
  String deviceName;
  String deviceType;
  String? deviceId;
  DateTime lastSync;
  bool isOnline;
  String? ipAddress;
  DateTime? lastSeen;
  bool isTrusted;
  DateTime createdAt;

  DeviceSyncInfo({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    this.deviceId,
    required this.lastSync,
    this.isOnline = false,
    this.ipAddress,
    this.lastSeen,
    this.isTrusted = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_name': deviceName,
      'device_type': deviceType,
      'device_id': deviceId,
      'last_sync': lastSync.toIso8601String(),
      'is_online': isOnline ? 1 : 0,
      'ip_address': ipAddress,
      'last_seen': lastSeen?.toIso8601String(),
      'is_trusted': isTrusted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DeviceSyncInfo.fromMap(Map<String, dynamic> map) {
    return DeviceSyncInfo(
      id: map['id']?.toString() ?? '',
      deviceName: map['device_name'] ?? '',
      deviceType: map['device_type'] ?? '',
      deviceId: map['device_id'],
      lastSync: DateTime.tryParse(map['last_sync'] ?? '') ?? DateTime.now(),
      isOnline: map['is_online'] == 1 || map['is_online'] == true,
      ipAddress: map['ip_address'],
      lastSeen: map['last_seen'] != null
          ? DateTime.tryParse(map['last_seen'])
          : null,
      isTrusted: map['is_trusted'] == 1 || map['is_trusted'] == true,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get formattedLastSync {
    return DateFormat('dd.MM.yyyy HH:mm').format(lastSync);
  }

  Duration? get timeSinceLastSync {
    return DateTime.now().difference(lastSync);
  }

  bool get needsSync {
    final duration = timeSinceLastSync;
    if (duration == null) return true;
    return duration.inMinutes > 30;
  }
}
