import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_manager/database/database_helper_sqlite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.initDatabase();
    });

    tearDown(() async {
      // Clean up database if needed
      // Note: In real tests, you might want to use an in-memory database
    });

    test('getEquipment returns list of maps', () async {
      final equipment = await dbHelper.getEquipment();
      expect(equipment, isA<List<Map<String, dynamic>>>());
    });

    test('getAllEquipment returns list of maps', () async {
      final equipment = await dbHelper.getAllEquipment();
      expect(equipment, isA<List<Map<String, dynamic>>>());
    });

    test('getEquipmentById returns null for non-existent id', () async {
      final equipment = await dbHelper.getEquipmentById('nonexistent_id_12345');
      expect(equipment, isNull);
    });

    test('getEquipmentById returns map for existing id', () async {
      // First insert an equipment
      final id = await dbHelper.insertEquipment({
        'id': 'test_equip_001',
        'name': 'Test Equipment',
        'type': 'computer',
        'status': 'inStock',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Then try to get it
      final equipment = await dbHelper.getEquipmentById('test_equip_001');
      expect(equipment, isNotNull);
      expect(equipment?['name'], equals('Test Equipment'));
    });

    test('insertEquipment returns generated id', () async {
      final id = await dbHelper.insertEquipment({
        'name': 'Test Computer',
        'type': 'computer',
        'status': 'inStock',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      expect(id, isNotEmpty);
      expect(id, isA<String>());
    });

    test('insertEquipment with explicit id returns that id', () async {
      final explicitId = 'explicit_test_id';
      final id = await dbHelper.insertEquipment({
        'id': explicitId,
        'name': 'Test Equipment',
        'type': 'computer',
        'status': 'inStock',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      expect(id, equals(explicitId));
    });

    test('updateEquipment updates existing record', () async {
      // Insert an equipment
      final id = await dbHelper.insertEquipment({
        'id': 'update_test_id',
        'name': 'Original Name',
        'type': 'computer',
        'status': 'inStock',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update it
      final updated = await dbHelper.updateEquipment({
        'id': 'update_test_id',
        'name': 'Updated Name',
        'type': 'computer',
        'status': 'inUse',
        'updated_at': DateTime.now().toIso8601String(),
      });
      expect(updated, greaterThan(0));

      // Verify the update
      final equipment = await dbHelper.getEquipmentById('update_test_id');
      expect(equipment?['name'], equals('Updated Name'));
    });

    test('deleteEquipment soft-deletes record', () async {
      // Insert an equipment
      final id = await dbHelper.insertEquipment({
        'id': 'delete_test_id',
        'name': 'To Delete',
        'type': 'computer',
        'status': 'inStock',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Delete it (soft delete)
      final deleted = await dbHelper.deleteEquipment('delete_test_id');
      expect(deleted, greaterThan(0));
    });

    test('searchEquipment returns matching results', () async {
      // Insert test data
      await dbHelper.insertEquipment({
        'id': 'search_test_1',
        'name': 'Test Computer',
        'type': 'computer',
        'status': 'inStock',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await dbHelper.insertEquipment({
        'id': 'search_test_2',
        'name': 'Test Printer',
        'type': 'printer',
        'status': 'inStock',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Search for "Test"
      final results = await dbHelper.searchEquipment('Test');
      expect(results.length, greaterThanOrEqualTo(2));
    });

    test('getStatistics returns statistics', () async {
      final stats = await dbHelper.getStatistics();
      expect(stats, isA<Map<String, int>>());
      expect(stats.containsKey('total'), isTrue);
      expect(stats.containsKey('in_use'), isTrue);
      expect(stats.containsKey('in_stock'), isTrue);
      expect(stats.containsKey('under_repair'), isTrue);
    });

    test('getEmployees returns list of maps', () async {
      final employees = await dbHelper.getEmployees();
      expect(employees, isA<List<Map<String, dynamic>>>());
    });

    test('insertEmployee returns generated id', () async {
      final id = await dbHelper.insertEmployee({
        'full_name': 'John Doe',
        'department': 'IT',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      expect(id, isNotEmpty);
    });

    test('getConsumables returns list of maps', () async {
      final consumables = await dbHelper.getConsumables();
      expect(consumables, isA<List<Map<String, dynamic>>>());
    });

    test('insertConsumable returns generated id', () async {
      final id = await dbHelper.insertConsumable({
        'name': 'Paper',
        'category': 'Office',
        'unit': 'ream',
        'quantity': 100,
        'min_quantity': 10,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      expect(id, isNotEmpty);
    });

    test('getConsumableStats returns statistics', () async {
      final stats = await dbHelper.getConsumableStats();
      expect(stats, isA<Map<String, int>>());
      expect(stats.containsKey('total'), isTrue);
    });

    test('getEmployeeStats returns statistics', () async {
      final stats = await dbHelper.getEmployeeStats();
      expect(stats, isA<Map<String, int>>());
      expect(stats.containsKey('total'), isTrue);
    });

    test('exportToCSV returns CSV string', () async {
      final csv = await dbHelper.exportToCSV();
      expect(csv, isA<String>());
      expect(csv.isNotEmpty, isTrue);
    });

    test('getAppSettings returns settings or null', () async {
      final settings = await dbHelper.getAppSettings();
      expect(settings, isA<Map<String, dynamic>?>());
    });
  });
}
