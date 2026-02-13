import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/equipment.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _isInitialized = false;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Инициализация для Windows
    if (!_isInitialized) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _isInitialized = true;
    }
    
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inventory.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE equipment (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        serialNumber TEXT,
        inventoryNumber TEXT,
        manufacturer TEXT,
        model TEXT,
        purchaseDate TEXT,
        purchasePrice REAL,
        department TEXT,
        location TEXT,
        status TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> initDatabase() async {
    await database;
    print('База данных инициализирована');
  }

  // ============ ДОБАВЛЕННЫЙ МЕТОД ============
  Future<int> getEquipmentCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM equipment');
    
    if (result.isNotEmpty && result.first['count'] != null) {
      return result.first['count'] as int;
    }
    return 0;
  }
  // ===========================================

  // CRUD операции для оборудования
  Future<int> insertEquipment(Equipment equipment) async {
    final db = await database;
    return await db.insert('equipment', equipment.toMap());
  }

  Future<List<Equipment>> getAllEquipment() async {
    final db = await database;
    final maps = await db.query('equipment', orderBy: 'name');
    return maps.map((map) => Equipment.fromMap(map)).toList();
  }

  Future<Equipment?> getEquipment(String id) async {
    final db = await database;
    final maps = await db.query(
      'equipment',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Equipment.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateEquipment(Equipment equipment) async {
    final db = await database;
    return await db.update(
      'equipment',
      equipment.toMap(),
      where: 'id = ?',
      whereArgs: [equipment.id],
    );
  }

  Future<int> deleteEquipment(String id) async {
    final db = await database;
    return await db.delete(
      'equipment',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Equipment>> searchEquipment(String query) async {
    final db = await database;
    final maps = await db.query(
      'equipment',
      where: 'name LIKE ? OR serialNumber LIKE ? OR inventoryNumber LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return maps.map((map) => Equipment.fromMap(map)).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}