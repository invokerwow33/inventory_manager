// Этот файл автоматически выбирает реализацию БД в зависимости от платформы
// - Десктоп/Мобайл: SQLite (database_helper_sqlite.dart)
// - Веб: JSON файлы через SimpleDatabaseHelper (database_helper_web.dart)

import 'database_helper_sqlite.dart' as sqlite;
import 'simple_database_helper.dart';

// Export the unified DatabaseHelper based on platform
export 'database_helper_sqlite.dart'
  if (dart.library.html) 'simple_database_helper.dart';

// Unified helper that provides the same interface for both platforms
class DatabaseHelper {
  static DatabaseHelper? _instance;
  late final dynamic _backend;

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  DatabaseHelper._internal() {
    // Use SimpleDatabaseHelper for web, DatabaseHelper for native
    try {
      _backend = SimpleDatabaseHelper();
    } catch (e) {
      // Fallback to SQLite for native platforms
      _backend = sqlite.DatabaseHelper.instance;
    }
  }

  static DatabaseHelper get instance => DatabaseHelper();

  // Initialize database
  Future<void> initDatabase() async {
    if (_backend is SimpleDatabaseHelper) {
      await _backend.initDatabase();
    } else {
      await _backend.initDatabase();
    }
  }

  // ========== EQUIPMENT METHODS ==========

  Future<List<Map<String, dynamic>>> getEquipment({bool forceRefresh = false}) async {
    return await _backend.getEquipment();
  }

  Future<Map<String, dynamic>?> getEquipmentById(dynamic id) async {
    return await _backend.getEquipmentById(id);
  }

  Future<dynamic> insertEquipment(Map<String, dynamic> equipment) async {
    return await _backend.insertEquipment(equipment);
  }

  Future<int> updateEquipment(Map<String, dynamic> equipment) async {
    return await _backend.updateEquipment(equipment);
  }

  Future<int> deleteEquipment(dynamic id) async {
    return await _backend.deleteEquipment(id);
  }

  Future<List<Map<String, dynamic>>> searchEquipment(String query) async {
    return await _backend.searchEquipment(query);
  }

  Future<List<Map<String, dynamic>>> searchEquipmentByName(String name) async {
    return await _backend.searchEquipmentByName(name);
  }

  Future<List<Map<String, dynamic>>> searchEquipmentByInventoryNumber(String inventoryNumber) async {
    return await _backend.searchEquipmentByInventoryNumber(inventoryNumber);
  }

  Future<int> getEquipmentCount() async {
    return await _backend.getEquipmentCount();
  }

  // ========== EMPLOYEE METHODS ==========

  Future<List<Map<String, dynamic>>> getEmployees({bool includeInactive = false}) async {
    return await _backend.getEmployees(includeInactive: includeInactive);
  }

  Future<Map<String, dynamic>?> getEmployeeById(String id) async {
    return await _backend.getEmployeeById(id);
  }

  Future<String> insertEmployee(Map<String, dynamic> employee) async {
    return await _backend.insertEmployee(employee);
  }

  Future<int> updateEmployee(Map<String, dynamic> employee) async {
    return await _backend.updateEmployee(employee);
  }

  Future<int> deleteEmployee(String id) async {
    return await _backend.deleteEmployee(id);
  }

  Future<List<Map<String, dynamic>>> searchEmployees(String query) async {
    return await _backend.searchEmployees(query);
  }

  Future<List<String>> getDepartments() async {
    return await _backend.getDepartments();
  }

  // ========== CONSUMABLE METHODS ==========

  Future<List<Map<String, dynamic>>> getConsumables() async {
    return await _backend.getConsumables();
  }

  Future<Map<String, dynamic>?> getConsumableById(String id) async {
    return await _backend.getConsumableById(id);
  }

  Future<String> insertConsumable(Map<String, dynamic> consumable) async {
    return await _backend.insertConsumable(consumable);
  }

  Future<int> updateConsumable(Map<String, dynamic> consumable) async {
    return await _backend.updateConsumable(consumable);
  }

  Future<int> deleteConsumable(String id) async {
    return await _backend.deleteConsumable(id);
  }

  Future<List<Map<String, dynamic>>> searchConsumables(String query) async {
    return await _backend.searchConsumables(query);
  }

  Future<List<Map<String, dynamic>>> getLowStockConsumables() async {
    return await _backend.getLowStockConsumables();
  }

  // ========== MOVEMENT METHODS ==========

  Future<int> addMovement(Map<String, dynamic> movement) async {
    return await _backend.addMovement(movement);
  }

  Future<List<Map<String, dynamic>>> getMovements() async {
    return await _backend.getMovements();
  }

  Future<List<Map<String, dynamic>>> getEquipmentMovements(dynamic equipmentId) async {
    return await _backend.getEquipmentMovements(equipmentId);
  }

  Future<List<Map<String, dynamic>>> getRecentMovements({int limit = 50}) async {
    return await _backend.getRecentMovements(limit: limit);
  }

  Future<String> exportMovementsToCSV() async {
    return await _backend.exportMovementsToCSV();
  }

  Future<void> clearMovements() async {
    return await _backend.clearMovements();
  }

  // ========== CONSUMABLE MOVEMENT METHODS ==========

  Future<int> addConsumableMovement(Map<String, dynamic> movement) async {
    return await _backend.addConsumableMovement(movement);
  }

  Future<List<Map<String, dynamic>>> getConsumableMovements(String? consumableId) async {
    return await _backend.getConsumableMovements(consumableId);
  }

  // ========== STATISTICS METHODS ==========

  Future<Map<String, int>> getStatistics() async {
    return await _backend.getStatistics();
  }

  // ========== EXPORT METHODS ==========

  Future<String> exportToCSV() async {
    return await _backend.exportToCSV();
  }

  // ========== UTILITY METHODS ==========

  Future<void> clearAllData() async {
    return await _backend.clearAllData();
  }
}
