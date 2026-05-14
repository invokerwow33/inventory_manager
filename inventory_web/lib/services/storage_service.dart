import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _uuid = const Uuid();
  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> initialize() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      
      // Создаем админа по умолчанию если нет пользователей
      final users = getUsers();
      if (users.isEmpty) {
        await createDefaultAdmin();
      }
    }
  }

  Future<void> createDefaultAdmin() async {
    final admin = User(
      id: _uuid.v4(),
      username: 'admin',
      passwordHash: _hashPassword('admin123'),
      fullName: 'Администратор',
      role: 'admin',
      createdAt: DateTime.now(),
    );
    await saveUser(admin);
    debugPrint('[Storage] Создан пользователь admin с паролем admin123');
  }

  String _hashPassword(String password) {
    // Простое хеширование для демонстрации (в production использовать bcrypt)
    return base64Encode(utf8.encode(password));
  }

  bool verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }

  // Users
  List<User> getUsers() {
    final usersJson = _prefs?.getStringList('users') ?? [];
    return usersJson.map((json) => User.fromMap(jsonDecode(json))).toList();
  }

  User? getUserByUsername(String username) {
    final users = getUsers();
    try {
      return users.firstWhere((u) => u.username == username);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(User user) async {
    final users = getUsers();
    final index = users.indexWhere((u) => u.id == user.id);
    
    if (index >= 0) {
      users[index] = user;
    } else {
      users.add(user);
    }
    
    await _prefs?.setStringList(
      'users',
      users.map((u) => jsonEncode(u.toMap())).toList(),
    );
  }

  Future<void> deleteUser(String userId) async {
    final users = getUsers();
    users.removeWhere((u) => u.id == userId);
    await _prefs?.setStringList(
      'users',
      users.map((u) => jsonEncode(u.toMap())).toList(),
    );
  }

  // Equipment
  List<Map<String, dynamic>> getEquipment() {
    final equipmentJson = _prefs?.getStringList('equipment') ?? [];
    return equipmentJson.map((json) => jsonDecode(json) as Map<String, dynamic>).toList();
  }

  Future<void> saveEquipment(Map<String, dynamic> item) async {
    final equipment = getEquipment();
    final index = equipment.indexWhere((e) => e['id'] == item['id']);
    
    if (index >= 0) {
      equipment[index] = item;
    } else {
      equipment.add(item);
    }
    
    await _prefs?.setStringList(
      'equipment',
      equipment.map((e) => jsonEncode(e)).toList(),
    );
  }

  Future<void> deleteEquipment(String id) async {
    final equipment = getEquipment();
    equipment.removeWhere((e) => e['id'] == id);
    await _prefs?.setStringList(
      'equipment',
      equipment.map((e) => jsonEncode(e)).toList(),
    );
  }

  // Consumables
  List<Map<String, dynamic>> getConsumables() {
    final consumablesJson = _prefs?.getStringList('consumables') ?? [];
    return consumablesJson.map((json) => jsonDecode(json) as Map<String, dynamic>).toList();
  }

  Future<void> saveConsumable(Map<String, dynamic> item) async {
    final consumables = getConsumables();
    final index = consumables.indexWhere((c) => c['id'] == item['id']);
    
    if (index >= 0) {
      consumables[index] = item;
    } else {
      consumables.add(item);
    }
    
    await _prefs?.setStringList(
      'consumables',
      consumables.map((c) => jsonEncode(c)).toList(),
    );
  }

  Future<void> deleteConsumable(String id) async {
    final consumables = getConsumables();
    consumables.removeWhere((c) => c['id'] == id);
    await _prefs?.setStringList(
      'consumables',
      consumables.map((c) => jsonEncode(c)).toList(),
    );
  }

  // Employees
  List<Map<String, dynamic>> getEmployees() {
    final employeesJson = _prefs?.getStringList('employees') ?? [];
    return employeesJson.map((json) => jsonDecode(json) as Map<String, dynamic>).toList();
  }

  Future<void> saveEmployee(Map<String, dynamic> item) async {
    final employees = getEmployees();
    final index = employees.indexWhere((e) => e['id'] == item['id']);
    
    if (index >= 0) {
      employees[index] = item;
    } else {
      employees.add(item);
    }
    
    await _prefs?.setStringList(
      'employees',
      employees.map((e) => jsonEncode(e)).toList(),
    );
  }

  Future<void> deleteEmployee(String id) async {
    final employees = getEmployees();
    employees.removeWhere((e) => e['id'] == id);
    await _prefs?.setStringList(
      'employees',
      employees.map((e) => jsonEncode(e)).toList(),
    );
  }

  // Locations
  List<Map<String, dynamic>> getLocations() {
    final locationsJson = _prefs?.getStringList('locations') ?? [];
    return locationsJson.map((json) => jsonDecode(json) as Map<String, dynamic>).toList();
  }

  Future<void> saveLocation(Map<String, dynamic> item) async {
    final locations = getLocations();
    final index = locations.indexWhere((l) => l['id'] == item['id']);
    
    if (index >= 0) {
      locations[index] = item;
    } else {
      locations.add(item);
    }
    
    await _prefs?.setStringList(
      'locations',
      locations.map((l) => jsonEncode(l)).toList(),
    );
  }

  Future<void> deleteLocation(String id) async {
    final locations = getLocations();
    locations.removeWhere((l) => l['id'] == id);
    await _prefs?.setStringList(
      'locations',
      locations.map((l) => jsonEncode(l)).toList(),
    );
  }

  // Session
  String? getCurrentUserId() {
    return _prefs?.getString('currentUserId');
  }

  Future<void> setCurrentUserId(String? userId) async {
    if (userId == null) {
      await _prefs?.remove('currentUserId');
    } else {
      await _prefs?.setString('currentUserId', userId);
    }
  }

  // Clear all data (for reset)
  Future<void> clearAll() async {
    await _prefs?.clear();
    await initialize();
  }
}
