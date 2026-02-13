import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
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
        purchase_date TEXT,
        status TEXT,
        location TEXT,
        notes TEXT
      )
    ''');
  }

  // Добавьте другие методы по необходимости
  Future<List<Map<String, dynamic>>> getEquipment() async {
    final db = await database;
    return await db.query('equipment');
  }

  Future<void> insertEquipment(Map<String, String> newEquipment) async {}

  Future<void> updateEquipment(Map<String, dynamic> equipment) async {}
}