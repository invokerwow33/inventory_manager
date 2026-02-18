import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> initDatabase() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'inventory.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Equipment table
    await db.execute('''
      CREATE TABLE equipment(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT,
        serial_number TEXT,
        inventory_number TEXT,
        manufacturer TEXT,
        model TEXT,
        department TEXT,
        responsible_person TEXT,
        purchase_date TEXT,
        purchase_price REAL,
        status TEXT,
        location TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Employees table
    await db.execute('''
      CREATE TABLE employees(
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        department TEXT,
        position TEXT,
        email TEXT,
        phone TEXT,
        employee_number TEXT,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Consumables table
    await db.execute('''
      CREATE TABLE consumables(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT,
        unit TEXT,
        quantity REAL DEFAULT 0,
        min_quantity REAL DEFAULT 0,
        supplier TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Movements table
    await db.execute('''
      CREATE TABLE movements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        equipment_id TEXT,
        equipment_name TEXT,
        from_location TEXT,
        to_location TEXT,
        from_responsible TEXT,
        to_responsible TEXT,
        movement_date TEXT,
        movement_type TEXT,
        document_number TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Consumable movements table
    await db.execute('''
      CREATE TABLE consumable_movements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        consumable_id TEXT,
        consumable_name TEXT,
        quantity REAL,
        operation_type TEXT,
        operation_date TEXT,
        employee_id TEXT,
        employee_name TEXT,
        document_number TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration logic if needed
    }
  }

  // ========== EQUIPMENT METHODS ==========

  Future<List<Map<String, dynamic>>> getEquipment({bool forceRefresh = false}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('equipment');
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<Map<String, dynamic>?> getEquipmentById(dynamic id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'equipment',
      where: 'id = ?',
      whereArgs: [id.toString()],
    );
    if (maps.isEmpty) return null;
    return Map<String, dynamic>.from(maps.first);
  }

  Future<String> insertEquipment(Map<String, dynamic> equipment) async {
    final db = await database;
    // Ensure id is set
    if (!equipment.containsKey('id') || equipment['id'] == null) {
      equipment['id'] = 'eq_${DateTime.now().millisecondsSinceEpoch}';
    }
    // Ensure timestamps
    final now = DateTime.now().toIso8601String();
    equipment['created_at'] ??= now;
    equipment['updated_at'] ??= now;

    await db.insert('equipment', equipment, conflictAlgorithm: ConflictAlgorithm.replace);
    return equipment['id'].toString();
  }

  Future<int> updateEquipment(Map<String, dynamic> equipment) async {
    final db = await database;
    equipment['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'equipment',
      equipment,
      where: 'id = ?',
      whereArgs: [equipment['id'].toString()],
    );
  }

  Future<int> deleteEquipment(dynamic id) async {
    final db = await database;
    return await db.delete(
      'equipment',
      where: 'id = ?',
      whereArgs: [id.toString()],
    );
  }

  Future<List<Map<String, dynamic>>> searchEquipment(String query) async {
    final db = await database;
    final lowerQuery = '%${query.toLowerCase()}%';
    final List<Map<String, dynamic>> maps = await db.query(
      'equipment',
      where: 'LOWER(name) LIKE ? OR LOWER(serial_number) LIKE ? OR LOWER(inventory_number) LIKE ?',
      whereArgs: [lowerQuery, lowerQuery, lowerQuery],
    );
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<List<Map<String, dynamic>>> searchEquipmentByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'equipment',
      where: 'LOWER(name) LIKE ?',
      whereArgs: ['%${name.toLowerCase()}%'],
      limit: 10,
    );
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<List<Map<String, dynamic>>> searchEquipmentByInventoryNumber(String inventoryNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'equipment',
      where: 'LOWER(inventory_number) LIKE ?',
      whereArgs: ['%${inventoryNumber.toLowerCase()}%'],
      limit: 10,
    );
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<int> getEquipmentCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM equipment');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ========== EMPLOYEE METHODS ==========

  Future<List<Map<String, dynamic>>> getEmployees({bool includeInactive = false}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;
    if (includeInactive) {
      maps = await db.query('employees');
    } else {
      maps = await db.query('employees', where: 'is_active = ?', whereArgs: [1]);
    }
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<Map<String, dynamic>?> getEmployeeById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Map<String, dynamic>.from(maps.first);
  }

  Future<String> insertEmployee(Map<String, dynamic> employee) async {
    final db = await database;
    if (!employee.containsKey('id') || employee['id'] == null) {
      employee['id'] = 'emp_${DateTime.now().millisecondsSinceEpoch}';
    }
    final now = DateTime.now().toIso8601String();
    employee['created_at'] ??= now;
    employee['updated_at'] ??= now;
    
    await db.insert('employees', employee, conflictAlgorithm: ConflictAlgorithm.replace);
    return employee['id'];
  }

  Future<int> updateEmployee(Map<String, dynamic> employee) async {
    final db = await database;
    employee['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'employees',
      employee,
      where: 'id = ?',
      whereArgs: [employee['id'].toString()],
    );
  }

  Future<int> deleteEmployee(String id) async {
    final db = await database;
    // Soft delete
    return await db.update(
      'employees',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> searchEmployees(String query) async {
    final db = await database;
    final lowerQuery = '%${query.toLowerCase()}%';
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'is_active = 1 AND (LOWER(full_name) LIKE ? OR LOWER(department) LIKE ? OR LOWER(position) LIKE ?)',
      whereArgs: [lowerQuery, lowerQuery, lowerQuery],
    );
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<List<String>> getDepartments() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT department FROM employees WHERE department IS NOT NULL AND department != "" ORDER BY department'
    );
    return result.map((r) => r['department'] as String).toList();
  }

  // ========== CONSUMABLE METHODS ==========

  Future<List<Map<String, dynamic>>> getConsumables() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('consumables');
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<Map<String, dynamic>?> getConsumableById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'consumables',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Map<String, dynamic>.from(maps.first);
  }

  Future<String> insertConsumable(Map<String, dynamic> consumable) async {
    final db = await database;
    if (!consumable.containsKey('id') || consumable['id'] == null) {
      consumable['id'] = 'cons_${DateTime.now().millisecondsSinceEpoch}';
    }
    final now = DateTime.now().toIso8601String();
    consumable['created_at'] ??= now;
    consumable['updated_at'] ??= now;
    
    await db.insert('consumables', consumable, conflictAlgorithm: ConflictAlgorithm.replace);
    return consumable['id'];
  }

  Future<int> updateConsumable(Map<String, dynamic> consumable) async {
    final db = await database;
    consumable['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'consumables',
      consumable,
      where: 'id = ?',
      whereArgs: [consumable['id'].toString()],
    );
  }

  Future<int> deleteConsumable(String id) async {
    final db = await database;
    return await db.delete(
      'consumables',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> searchConsumables(String query) async {
    final db = await database;
    final lowerQuery = '%${query.toLowerCase()}%';
    final List<Map<String, dynamic>> maps = await db.query(
      'consumables',
      where: 'LOWER(name) LIKE ? OR LOWER(category) LIKE ?',
      whereArgs: [lowerQuery, lowerQuery],
    );
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getLowStockConsumables() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'consumables',
      where: 'quantity <= min_quantity AND min_quantity > 0',
    );
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  // ========== MOVEMENT METHODS ==========

  Future<int> addMovement(Map<String, dynamic> movement) async {
    final db = await database;
    movement['created_at'] = DateTime.now().toIso8601String();
    return await db.insert('movements', movement);
  }

  Future<List<Map<String, dynamic>>> getMovements() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movements',
      orderBy: 'movement_date DESC',
    );
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getEquipmentMovements(dynamic equipmentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movements',
      where: 'equipment_id = ?',
      whereArgs: [equipmentId.toString()],
      orderBy: 'movement_date DESC',
    );
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getRecentMovements({int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movements',
      orderBy: 'movement_date DESC',
      limit: limit,
    );
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<String> exportMovementsToCSV() async {
    final movements = await getMovements();
    final csvData = StringBuffer();
    
    csvData.writeln('ID,Дата,Тип,Оборудование,ID оборудования,Откуда,Куда,Ответственный от,Ответственный кому,Номер документа,Примечания');
    
    for (final movement in movements) {
      final row = [
        movement['id']?.toString() ?? '',
        '"${movement['movement_date']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${movement['movement_type']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${movement['equipment_name']?.toString().replaceAll('"', '""') ?? ''}"',
        movement['equipment_id']?.toString() ?? '',
        '"${movement['from_location']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${movement['to_location']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${movement['from_responsible']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${movement['to_responsible']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${movement['document_number']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${movement['notes']?.toString().replaceAll('"', '""') ?? ''}"',
      ].join(',');
      
      csvData.writeln(row);
    }
    
    return csvData.toString();
  }

  Future<void> clearMovements() async {
    final db = await database;
    await db.delete('movements');
  }

  // ========== CONSUMABLE MOVEMENT METHODS ==========

  Future<int> addConsumableMovement(Map<String, dynamic> movement) async {
    final db = await database;
    movement['created_at'] = DateTime.now().toIso8601String();
    final id = await db.insert('consumable_movements', movement);
    
    // Update consumable quantity
    final consumableId = movement['consumable_id']?.toString();
    final operationType = movement['operation_type']?.toString();
    final quantity = (movement['quantity'] ?? 0).toDouble();
    
    if (consumableId != null) {
      final consumable = await getConsumableById(consumableId);
      if (consumable != null) {
        double newQuantity = (consumable['quantity'] ?? 0).toDouble();
        if (operationType == 'приход') {
          newQuantity += quantity;
        } else if (operationType == 'расход') {
          newQuantity -= quantity;
        }
        
        await updateConsumable({
          'id': consumableId,
          'quantity': newQuantity,
        });
      }
    }
    
    return id;
  }

  Future<List<Map<String, dynamic>>> getConsumableMovements(String? consumableId) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (consumableId != null && consumableId.isNotEmpty) {
      maps = await db.query(
        'consumable_movements',
        where: 'consumable_id = ?',
        whereArgs: [consumableId],
        orderBy: 'operation_date DESC',
      );
    } else {
      maps = await db.query('consumable_movements', orderBy: 'operation_date DESC');
    }
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  // ========== STATISTICS METHODS ==========

  Future<Map<String, int>> getStatistics() async {
    final db = await database;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM equipment');
    final inUseResult = await db.rawQuery("SELECT COUNT(*) as count FROM equipment WHERE status = 'В использовании'");
    final inStockResult = await db.rawQuery("SELECT COUNT(*) as count FROM equipment WHERE status = 'На складе'");
    final underRepairResult = await db.rawQuery("SELECT COUNT(*) as count FROM equipment WHERE status = 'В ремонте'");
    
    return {
      'total': Sqflite.firstIntValue(totalResult) ?? 0,
      'in_use': Sqflite.firstIntValue(inUseResult) ?? 0,
      'in_stock': Sqflite.firstIntValue(inStockResult) ?? 0,
      'under_repair': Sqflite.firstIntValue(underRepairResult) ?? 0,
    };
  }

  // ========== EXPORT METHODS ==========

  Future<String> exportToCSV() async {
    final equipment = await getEquipment();
    final csvData = StringBuffer();
    
    csvData.writeln('ID,Название,Тип,Серийный номер,Инвентарный номер,Статус,Ответственный,Местоположение,Дата покупки,Примечания');
    
    for (final item in equipment) {
      final row = [
        item['id']?.toString() ?? '',
        '"${item['name']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${item['type']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${item['serial_number']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${item['inventory_number']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${item['status']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${item['responsible_person']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${item['location']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${item['purchase_date']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${item['notes']?.toString().replaceAll('"', '""') ?? ''}"',
      ].join(',');
      
      csvData.writeln(row);
    }
    
    return csvData.toString();
  }

  // ========== UTILITY METHODS ==========

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('equipment');
    await db.delete('employees');
    await db.delete('consumables');
    await db.delete('movements');
    await db.delete('consumable_movements');
  }
}
