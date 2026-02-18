import 'simple_database_helper.dart';
import '../models/equipment.dart';
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();
  Future<void> initDatabase() async {
    await SimpleDatabaseHelper().initDatabase();
  }
  Future<List<Equipment>> getAllEquipment() async {
    final maps = await SimpleDatabaseHelper().getEquipment();
    return maps.map((m) => _mapToEquipment(m)).toList();
  }
  Future<int> insertEquipment(Equipment equipment) async {
    return await SimpleDatabaseHelper().insertEquipment(_equipmentToMap(equipment));
  }
  Future<int> updateEquipment(Equipment equipment) async {
    return await SimpleDatabaseHelper().updateEquipment(_equipmentToMap(equipment));
  }
  Future<int> deleteEquipment(String id) async {
    final intId = int.tryParse(id) ?? 0;
    return await SimpleDatabaseHelper().deleteEquipment(intId);
  }
  Future<Equipment?> getEquipment(String id) async {
    final intId = int.tryParse(id) ?? 0;
    final map = await SimpleDatabaseHelper().getEquipmentById(intId);
    return map != null && map.isNotEmpty ? _mapToEquipment(map) : null;
  }
  Future<List<Equipment>> searchEquipment(String query) async {
    final maps = await SimpleDatabaseHelper().searchEquipment(query);
    return maps.map((m) => _mapToEquipment(m)).toList();
  }

  Future<List<Equipment>> searchEquipmentByName(String name) async {
    final maps = await SimpleDatabaseHelper().searchEquipmentByName(name);
    return maps.map((m) => _mapToEquipment(m)).toList();
  }

  Future<List<Equipment>> searchEquipmentByInventoryNumber(String inventoryNumber) async {
    final maps = await SimpleDatabaseHelper().searchEquipmentByInventoryNumber(inventoryNumber);
    return maps.map((m) => _mapToEquipment(m)).toList();
  }
  Future<int> getEquipmentCount() async {
    return await SimpleDatabaseHelper().getEquipmentCount();
  }
  // Конвертеры
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
      'id': int.tryParse(e.id) ?? 0,
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
