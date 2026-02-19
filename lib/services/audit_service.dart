import '../database/database_helper.dart';
import '../models/audit_log.dart';

class AuditService {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> log({
    required String userId,
    String? username,
    required AuditActionType actionType,
    required AuditEntityType entityType,
    required String entityId,
    String? entityName,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? description,
    String? ipAddress,
    String? userAgent,
    String? sessionId,
  }) async {
    final log = AuditLog(
      userId: userId,
      username: username,
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      entityName: entityName,
      oldValues: oldValues,
      newValues: newValues,
      description: description,
      timestamp: DateTime.now(),
      ipAddress: ipAddress,
      userAgent: userAgent,
      sessionId: sessionId,
    );

    await _dbHelper.addAuditLog(log.toMap());
  }

  Future<void> logLogin(String userId, String username) async {
    await log(
      userId: userId,
      username: username,
      actionType: AuditActionType.login,
      entityType: AuditEntityType.user,
      entityId: userId,
      entityName: username,
      description: 'Пользователь вошел в систему',
    );
  }

  Future<void> logLoginAttempt(String username, bool success) async {
    await log(
      userId: 'system',
      username: username,
      actionType: AuditActionType.login,
      entityType: AuditEntityType.user,
      entityId: 'unknown',
      entityName: username,
      description: success 
          ? 'Успешная попытка входа' 
          : 'Неудачная попытка входа',
    );
  }

  Future<void> logLogout(String userId, String username) async {
    await log(
      userId: userId,
      username: username,
      actionType: AuditActionType.logout,
      entityType: AuditEntityType.user,
      entityId: userId,
      entityName: username,
      description: 'Пользователь вышел из системы',
    );
  }

  Future<void> logUserCreated(String userId, String newUserId, String newUsername) async {
    await log(
      userId: userId,
      actionType: AuditActionType.create,
      entityType: AuditEntityType.user,
      entityId: newUserId,
      entityName: newUsername,
      description: 'Создан новый пользователь: $newUsername',
    );
  }

  Future<void> logUserUpdated(String userId, String targetUserId) async {
    await log(
      userId: userId,
      actionType: AuditActionType.update,
      entityType: AuditEntityType.user,
      entityId: targetUserId,
      description: 'Обновлены данные пользователя',
    );
  }

  Future<void> logUserDeleted(String userId, String targetUserId) async {
    await log(
      userId: userId,
      actionType: AuditActionType.delete,
      entityType: AuditEntityType.user,
      entityId: targetUserId,
      description: 'Пользователь удален',
    );
  }

  Future<void> logPasswordChanged(String userId, String targetUserId) async {
    await log(
      userId: userId,
      actionType: AuditActionType.update,
      entityType: AuditEntityType.user,
      entityId: targetUserId,
      description: 'Изменен пароль пользователя',
    );
  }

  Future<void> logEquipmentCreated(
    String userId, 
    String equipmentId, 
    String equipmentName,
    Map<String, dynamic> data,
  ) async {
    await log(
      userId: userId,
      actionType: AuditActionType.create,
      entityType: AuditEntityType.equipment,
      entityId: equipmentId,
      entityName: equipmentName,
      newValues: data,
      description: 'Создано оборудование: $equipmentName',
    );
  }

  Future<void> logEquipmentUpdated(
    String userId,
    String equipmentId,
    String equipmentName,
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) async {
    await log(
      userId: userId,
      actionType: AuditActionType.update,
      entityType: AuditEntityType.equipment,
      entityId: equipmentId,
      entityName: equipmentName,
      oldValues: oldData,
      newValues: newData,
      description: 'Обновлено оборудование: $equipmentName',
    );
  }

  Future<void> logEquipmentDeleted(
    String userId,
    String equipmentId,
    String equipmentName,
  ) async {
    await log(
      userId: userId,
      actionType: AuditActionType.delete,
      entityType: AuditEntityType.equipment,
      entityId: equipmentId,
      entityName: equipmentName,
      description: 'Удалено оборудование: $equipmentName',
    );
  }

  Future<void> logMovementCreated(
    String userId,
    String movementId,
    String equipmentName,
    String movementType,
  ) async {
    await log(
      userId: userId,
      actionType: AuditActionType.movement,
      entityType: AuditEntityType.movement,
      entityId: movementId,
      entityName: equipmentName,
      description: '$movementType: $equipmentName',
    );
  }

  Future<void> logExport(
    String userId,
    String entityType,
    String format,
  ) async {
    await log(
      userId: userId,
      actionType: AuditActionType.export,
      entityType: AuditEntityType.values.firstWhere(
        (e) => e.name == entityType,
        orElse: () => AuditEntityType.system,
      ),
      entityId: 'export',
      description: 'Экспорт $entityType в формате $format',
    );
  }

  Future<void> logImport(
    String userId,
    String entityType,
    int count,
  ) async {
    await log(
      userId: userId,
      actionType: AuditActionType.import,
      entityType: AuditEntityType.values.firstWhere(
        (e) => e.name == entityType,
        orElse: () => AuditEntityType.system,
      ),
      entityId: 'import',
      description: 'Импорт $count записей $entityType',
    );
  }

  Future<void> logBackup(String userId, String location) async {
    await log(
      userId: userId,
      actionType: AuditActionType.backup,
      entityType: AuditEntityType.system,
      entityId: 'backup',
      description: 'Создана резервная копия: $location',
    );
  }

  Future<void> logRestore(String userId, String location) async {
    await log(
      userId: userId,
      actionType: AuditActionType.restore,
      entityType: AuditEntityType.system,
      entityId: 'restore',
      description: 'Восстановление из резервной копии: $location',
    );
  }

  Future<void> logBulkOperation(
    String userId,
    String operation,
    int count,
    String entityType,
  ) async {
    await log(
      userId: userId,
      actionType: AuditActionType.bulk,
      entityType: AuditEntityType.values.firstWhere(
        (e) => e.name == entityType,
        orElse: () => AuditEntityType.system,
      ),
      entityId: 'bulk',
      description: 'Массовая операция "$operation" над $count записями $entityType',
    );
  }

  Future<void> logSettingsChanged(String userId, String settingName) async {
    await log(
      userId: userId,
      actionType: AuditActionType.update,
      entityType: AuditEntityType.settings,
      entityId: 'settings',
      description: 'Изменена настройка: $settingName',
    );
  }

  Future<List<AuditLog>> getAuditLogs({
    int limit = 100,
    int offset = 0,
    String? userId,
    AuditEntityType? entityType,
    AuditActionType? actionType,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final data = await _dbHelper.getAuditLogs(
      limit: limit,
      offset: offset,
      userId: userId,
      entityType: entityType?.name,
      actionType: actionType?.name,
      fromDate: fromDate,
      toDate: toDate,
    );
    return data.map((m) => AuditLog.fromMap(m)).toList();
  }
}
