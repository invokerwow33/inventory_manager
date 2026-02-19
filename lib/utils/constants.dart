/// Application-wide constants
class AppConstants {
  AppConstants._();

  // Cache duration for equipment data
  static const Duration equipmentCacheDuration = Duration(minutes: 5);

  // Equipment statuses
  static const String equipmentStatusInUse = 'В использовании';
  static const String equipmentStatusInStock = 'На складе';
  static const String equipmentStatusUnderRepair = 'В ремонте';
  static const String equipmentStatusWrittenOff = 'Списано';
  static const String equipmentStatusReserved = 'Зарезервировано';

  static const List<String> equipmentStatuses = [
    equipmentStatusInUse,
    equipmentStatusInStock,
    equipmentStatusUnderRepair,
    equipmentStatusWrittenOff,
    equipmentStatusReserved,
  ];

  // Movement types
  static const String movementTypeIssue = 'Выдача';
  static const String movementTypeReturn = 'Возврат';
  static const String movementTypeTransfer = 'Перемещение';
  static const String movementTypeWriteOff = 'Списание';

  static const List<String> movementTypes = [
    movementTypeIssue,
    movementTypeReturn,
    movementTypeTransfer,
    movementTypeWriteOff,
  ];

  // Consumable operation types
  static const String consumableOperationIncome = 'приход';
  static const String consumableOperationExpense = 'расход';

  static const List<String> consumableOperationTypes = [
    consumableOperationIncome,
    consumableOperationExpense,
  ];

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File export limits
  static const int maxExportRows = 10000;

  // ID prefixes
  static const String equipmentIdPrefix = 'eq_';
  static const String consumableIdPrefix = 'cons_';
  static const String employeeIdPrefix = 'emp_';
}
