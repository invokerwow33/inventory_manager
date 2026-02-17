import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/equipment.dart';

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

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'inventory.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE equipment(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        serial_number TEXT,
        inventory_number TEXT,
        manufacturer TEXT,
        model TEXT,
        department TEXT,
        responsible_person TEXT,
        purchase_date TEXT,
        status TEXT,
        location TEXT,
        notes TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
  }

  Future<List<Equipment>> getAllEquipment() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('equipment');
    return maps.map((map) => _mapToEquipment(map)).toList();
  }

  Future<int> insertEquipment(Equipment equipment) async {
    final db = await database;
    return await db.insert('equipment', _equipmentToMap(equipment));
  }

  Future<int> updateEquipment(Equipment equipment) async {
    final db = await database;
    return await db.update(
      'equipment',
      _equipmentToMap(equipment),
      where: 'id = ?',
      whereArgs: [int.parse(equipment.id)],
    );
  }

  Future<int> deleteEquipment(String id) async {
    final db = await database;
    return await db.delete(
      'equipment',
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
  }

  Future<Equipment?> getEquipment(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'equipment',
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
    if (maps.isEmpty) return null;
    return _mapToEquipment(maps.first);
  }

  Future<List<Equipment>> searchEquipment(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'equipment',
      where: 'name LIKE ? OR serial_number LIKE ? OR inventory_number LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return maps.map((map) => _mapToEquipment(map)).toList();
  }

  Future<int> getEquipmentCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM equipment');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Equipment _mapToEquipment(Map<String, dynamic> map) {
    return Equipment(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      type: _parseType(map['category'] ?? 'computer'),
      status: _parseStatus(map['status'] ?? 'На складе'),
      serialNumber: map['serial_number'],
      inventoryNumber: map['inventory_number'],
      manufacturer: map['manufacturer'],
      model: map['model'],
      department: map['department'],
      responsiblePerson: map['responsible_person'],
      location: map['location'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> _equipmentToMap(Equipment e) {
    return {
      if (e.id.isNotEmpty && e.id != '0') 'id': int.parse(e.id),
      'name': e.name,
      'category': e.type.toString().split('.').last,
      'status': e.status.label,
      'serial_number': e.serialNumber,
      'inventory_number': e.inventoryNumber,
      'manufacturer': e.manufacturer,
      'model': e.model,
      'department': e.department,
      'responsible_person': e.responsiblePerson,
      'location': e.location,
      'created_at': e.createdAt.toIso8601String(),
      'updated_at': e.updatedAt.toIso8601String(),
    };
  }

  EquipmentType _parseType(String type) {
    return EquipmentType.values.firstWhere(
      (t) => t.toString().split('.').last.toLowerCase() == type.toLowerCase(),
      orElse: () => EquipmentType.computer,
    );
  }

  EquipmentStatus _parseStatus(String status) {
    final statusMap = {
      'В использовании': EquipmentStatus.inUse,
      'На складе': EquipmentStatus.inStock,
      'В ремонте': EquipmentStatus.underRepair,
      'Списано': EquipmentStatus.writtenOff,
    };
    return statusMap[status] ?? EquipmentStatus.inStock;
  }
}
