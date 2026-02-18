import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SimpleDatabaseHelper {
  static final SimpleDatabaseHelper _instance = SimpleDatabaseHelper._internal();
  factory SimpleDatabaseHelper() => _instance;
  SimpleDatabaseHelper._internal();

  List<Map<String, dynamic>> _equipment = [];
  List<Map<String, dynamic>> _movements = [];
  late File _databaseFile;
  late File _movementsFile;
  bool _isInitialized = false;
  
  // Кэш для производительности
  List<Map<String, dynamic>>? _equipmentCache;
  DateTime? _cacheTimestamp;
  final Duration _cacheDuration = const Duration(minutes: 5);

  Future<void> initDatabase() async {
    if (_isInitialized) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      _databaseFile = File('${directory.path}/inventory.json');
      _movementsFile = File('${directory.path}/movements.json');
      
      if (await _databaseFile.exists()) {
        final content = await _databaseFile.readAsString();
        if (content.isNotEmpty) {
          final data = jsonDecode(content);
          _equipment = List<Map<String, dynamic>>.from(data);
          
          // Автоматически исправляем данные при загрузке
          await _fixAllDataTypes();
        } else {
          _equipment = [];
        }
      } else {
        _equipment = [];
        await _saveToFile();
      }
      
      // Загрузка перемещений
      if (await _movementsFile.exists()) {
        final content = await _movementsFile.readAsString();
        if (content.isNotEmpty) {
          final data = jsonDecode(content);
          _movements = List<Map<String, dynamic>>.from(data);
        } else {
          _movements = [];
        }
      } else {
        _movements = [];
        await _saveMovementsToFile();
      }
      
      _isInitialized = true;
      print('База данных инициализирована. Оборудование: ${_equipment.length}, Перемещений: ${_movements.length}');
    } catch (e) {
      print('Ошибка инициализации базы данных: $e');
      _equipment = [];
      _movements = [];
      _isInitialized = true;
    }
  }

  // ГАРАНТИРУЕТ, что все значения - строки
  String _ensureString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  // Поиск оборудования по инвентарному номеру
  Future<List<Map<String, dynamic>>> searchEquipmentByInventoryNumber(String inventoryNumber) async {
    if (!_isInitialized) await initDatabase();
    
    if (inventoryNumber.isEmpty) return [];
    
    final query = inventoryNumber.toLowerCase();
    return _equipment.where((item) {
      return (item['inventory_number']?.toString().toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // Поиск оборудования по названию
  Future<List<Map<String, dynamic>>> searchEquipmentByName(String name) async {
    if (!_isInitialized) await initDatabase();
    
    if (name.isEmpty) return [];
    
    final query = name.toLowerCase();
    return _equipment.where((item) {
      return (item['name']?.toString().toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // Исправляет все типы данных в базе
  Future<void> _fixAllDataTypes() async {
    bool changed = false;
    
    for (int i = 0; i < _equipment.length; i++) {
      final item = _equipment[i];
      final fixedItem = <String, dynamic>{
        // ID может быть int или String (например, "eq_17") - сохраняем как есть
        'id': item['id'],
        'name': _ensureString(item['name']),
        'category': _ensureString(item['category']),
        'serial_number': _ensureString(item['serial_number']),
        'inventory_number': _ensureString(item['inventory_number']),
        'status': _ensureString(item['status']),
        'location': _ensureString(item['location']),
        'notes': _ensureString(item['notes']),
        'purchase_date': item['purchase_date']?.toString(),
        'responsible_person': _ensureString(item['responsible_person']),
        'created_at': _ensureString(item['created_at']),
      };
      
      if (item.containsKey('updated_at') && item['updated_at'] != null) {
        fixedItem['updated_at'] = _ensureString(item['updated_at']);
      }
      
      if (!_mapsEqual(item, fixedItem)) {
        _equipment[i] = fixedItem;
        changed = true;
      }
    }
    
    if (changed) {
      await _saveToFile();
      print('Типы данных автоматически исправлены');
    }
  }

  bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (_ensureString(a[key]) != _ensureString(b[key])) return false;
    }
    return true;
  }

  Future<void> _saveToFile() async {
    try {
      await _databaseFile.writeAsString(jsonEncode(_equipment));
      // Очищаем кэш при сохранении
      _equipmentCache = null;
      _cacheTimestamp = null;
      print('Данные сохранены. Всего записей: ${_equipment.length}');
    } catch (e) {
      print('Ошибка сохранения в файл: $e');
    }
  }

  Future<void> _saveMovementsToFile() async {
    try {
      await _movementsFile.writeAsString(jsonEncode(_movements));
      print('Перемещения сохранены. Всего: ${_movements.length}');
    } catch (e) {
      print('Ошибка сохранения перемещений: $e');
    }
  }

  // Метод с кэшированием
  Future<List<Map<String, dynamic>>> getEquipment({bool forceRefresh = false}) async {
    if (!_isInitialized) await initDatabase();
    
    // Проверяем кэш
    if (!forceRefresh && 
        _equipmentCache != null && 
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      print('Используем кэшированные данные');
      return List.from(_equipmentCache!);
    }
    
    // Обновляем кэш
    _equipmentCache = List.from(_equipment);
    _cacheTimestamp = DateTime.now();
    print('Данные загружены и закэшированы');
    
    return List.from(_equipment);
  }

  // НОВЫЙ МЕТОД: безопасное обновление с гарантией типов
  Future<int> safeUpdateEquipment(Map<String, dynamic> equipment) async {
    if (!_isInitialized) await initDatabase();
    
    final index = _equipment.indexWhere((item) => item['id'] == equipment['id']);
    if (index != -1) {
      final existing = _equipment[index];
      
      // Создаем полностью новую запись
      final updated = <String, dynamic>{
        'id': equipment['id'],
        'name': _ensureString(equipment['name'] ?? existing['name']),
        'category': _ensureString(equipment['category'] ?? existing['category']),
        'serial_number': _ensureString(equipment['serial_number'] ?? existing['serial_number']),
        'inventory_number': _ensureString(equipment['inventory_number'] ?? existing['inventory_number']),
        'status': _ensureString(equipment['status'] ?? existing['status']),
        'location': _ensureString(equipment['location'] ?? existing['location']),
        'notes': _ensureString(equipment['notes'] ?? existing['notes']),
        'purchase_date': equipment['purchase_date'] ?? existing['purchase_date'],
        'responsible_person': _ensureString(equipment['responsible_person'] ?? existing['responsible_person']),
        'created_at': _ensureString(existing['created_at']),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      _equipment[index] = updated;
      await _saveToFile();
      print('Оборудование безопасно обновлено. ID: ${equipment['id']}');
      return 1;
    }
    return 0;
  }

  // Старый метод обновления (для обратной совместимости)
  Future<int> updateEquipment(Map<String, dynamic> equipment) async {
    return await safeUpdateEquipment(equipment);
  }

  // Генерирует новый ID для оборудования
  // Поддерживает как числовые ID (для старых записей), так и строковые с префиксом "eq_" (для новых)
  dynamic _generateEquipmentId() {
    if (_equipment.isEmpty) {
      return 1;
    }
    
    final lastId = _equipment.last['id'];
    
    // Если последний ID - строка с префиксом "eq_", продолжаем эту нумерацию
    if (lastId is String && lastId.startsWith('eq_')) {
      final number = int.tryParse(lastId.substring(3)) ?? 0;
      return 'eq_${number + 1}';
    }
    
    // Если последний ID - число или строка-число, продолжаем числовую нумерацию
    if (lastId is int) {
      return lastId + 1;
    }
    
    // Пытаемся парсить как число (для строковых чисел)
    final parsed = int.tryParse(lastId.toString());
    if (parsed != null) {
      return parsed + 1;
    }
    
    // По умолчанию начинаем с числового ID
    return 1;
  }

  Future<dynamic> insertEquipment(Map<String, dynamic> equipment) async {
    if (!_isInitialized) await initDatabase();
    
    // Используем предоставленный ID или генерируем новый
    final dynamic newId = equipment['id'] ?? _generateEquipmentId();
    
    final newEquipment = <String, dynamic>{
      'id': newId,
      'name': _ensureString(equipment['name']),
      'category': _ensureString(equipment['category']),
      'serial_number': _ensureString(equipment['serial_number']),
      'inventory_number': _ensureString(equipment['inventory_number']),
      'status': _ensureString(equipment['status'] ?? 'На складе'),
      'location': _ensureString(equipment['location']),
      'notes': _ensureString(equipment['notes']),
      'purchase_date': equipment['purchase_date'],
      'responsible_person': _ensureString(equipment['responsible_person']),
      'created_at': DateTime.now().toIso8601String(),
    };
    
    _equipment.add(newEquipment);
    await _saveToFile();
    print('Оборудование добавлено. ID: ${newEquipment['id']}');
    return newEquipment['id'];
  }

  Future<Map<String, dynamic>?> getEquipmentById(dynamic id) async {
    if (!_isInitialized) await initDatabase();
    return _equipment.firstWhere(
      (item) => item['id'] == id,
      orElse: () => {},
    );
  }

  Future<int> deleteEquipment(dynamic id) async {
    if (!_isInitialized) await initDatabase();
    
    final initialLength = _equipment.length;
    _equipment.removeWhere((item) => item['id'] == id);
    if (_equipment.length != initialLength) {
      await _saveToFile();
      print('Оборудование удалено. ID: $id');
      return 1;
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> searchEquipment(String query) async {
    if (!_isInitialized) await initDatabase();
    
    if (query.isEmpty) return getEquipment();
    
    final lowerQuery = query.toLowerCase();
    return _equipment.where((item) {
      return (item['name']?.toString().toLowerCase().contains(lowerQuery) ?? false) ||
             (item['serial_number']?.toString().toLowerCase().contains(lowerQuery) ?? false) ||
             (item['inventory_number']?.toString().toLowerCase().contains(lowerQuery) ?? false) ||
             (item['category']?.toString().toLowerCase().contains(lowerQuery) ?? false) ||
             (item['responsible_person']?.toString().toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  Future<int> getEquipmentCount() async {
    if (!_isInitialized) await initDatabase();
    return _equipment.length;
  }

  // === МЕТОДЫ ДЛЯ ПЕРЕМЕЩЕНИЙ ===

  Future<int> addMovement(Map<String, dynamic> movement) async {
    if (!_isInitialized) await initDatabase();
    
    final newMovement = Map<String, dynamic>.from(movement);
    newMovement['id'] = _movements.isEmpty ? 1 : (_movements.last['id'] as int) + 1;
    newMovement['created_at'] = DateTime.now().toIso8601String();
    
    // Гарантируем правильные типы данных
    // equipment_id может быть int (старые записи) или String (новые с префиксом "eq_")
    final safeMovement = <String, dynamic>{
      'id': newMovement['id'],
      'equipment_id': newMovement['equipment_id'],
      'equipment_name': _ensureString(newMovement['equipment_name']),
      'from_location': _ensureString(newMovement['from_location']),
      'to_location': _ensureString(newMovement['to_location']),
      'from_responsible': _ensureString(newMovement['from_responsible']),
      'to_responsible': _ensureString(newMovement['to_responsible']),
      'movement_date': _ensureString(newMovement['movement_date']),
      'movement_type': _ensureString(newMovement['movement_type']),
      'document_number': _ensureString(newMovement['document_number']),
      'notes': _ensureString(newMovement['notes']),
      'created_at': _ensureString(newMovement['created_at']),
    };
    
    _movements.add(safeMovement);
    await _saveMovementsToFile();
    print('Перемещение добавлено. ID: ${safeMovement['id']}');
    return safeMovement['id'];
  }

  Future<List<Map<String, dynamic>>> getMovements() async {
    if (!_isInitialized) await initDatabase();
    return List.from(_movements);
  }

  Future<List<Map<String, dynamic>>> getEquipmentMovements(dynamic equipmentId) async {
    if (!_isInitialized) await initDatabase();
    final filtered = _movements
        .where((movement) => movement['equipment_id'] == equipmentId)
        .toList();
    
    // Сортируем по дате (новые сверху)
    filtered.sort((a, b) {
      final dateA = DateTime.parse(a['movement_date'] ?? a['created_at']);
      final dateB = DateTime.parse(b['movement_date'] ?? b['created_at']);
      return dateB.compareTo(dateA);
    });
    
    return filtered;
  }

  Future<List<Map<String, dynamic>>> getRecentMovements({int limit = 50}) async {
    if (!_isInitialized) await initDatabase();
    
    // Сортируем по дате (новые сверху)
    final sorted = List<Map<String, dynamic>>.from(_movements)
      ..sort((a, b) {
        final dateA = DateTime.parse(a['movement_date'] ?? a['created_at']);
        final dateB = DateTime.parse(b['movement_date'] ?? b['created_at']);
        return dateB.compareTo(dateA);
      });
    
    return sorted.take(limit).toList();
  }

  Future<String> exportMovementsToCSV() async {
    if (!_isInitialized) await initDatabase();
    
    final csvData = StringBuffer();
    
    // Заголовки
    csvData.writeln('ID,Дата,Тип,Оборудование,ID оборудования,Откуда,Куда,Ответственный от,Ответственный кому,Номер документа,Примечания');
    
    // Данные
    for (final movement in _movements) {
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
    if (!_isInitialized) await initDatabase();
    _movements.clear();
    await _saveMovementsToFile();
    print('Все перемещения очищены');
  }

  // === ОСТАЛЬНЫЕ МЕТОДЫ ===

  Future<Map<String, int>> getStatistics() async {
    if (!_isInitialized) await initDatabase();
    
    final stats = {
      'total': _equipment.length,
      'in_use': _equipment.where((item) => item['status'] == 'В использовании').length,
      'in_stock': _equipment.where((item) => item['status'] == 'На складе').length,
      'under_repair': _equipment.where((item) => item['status'] == 'В ремонте').length,
    };
    
    return stats;
  }

  Future<String> exportToCSV() async {
    if (!_isInitialized) await initDatabase();
    
    final csvData = StringBuffer();
    
    csvData.writeln('ID,Название,Категория,Серийный номер,Инвентарный номер,Статус,Ответственный,Местоположение,Дата покупки,Примечания');
    
    for (final item in _equipment) {
      final row = [
        item['id']?.toString() ?? '',
        '"${item['name']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${item['category']?.toString().replaceAll('"', '""') ?? ''}"',
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

  Future<void> clearAllData() async {
    if (!_isInitialized) await initDatabase();
    _equipment.clear();
    _movements.clear();
    await _saveToFile();
    await _saveMovementsToFile();
  }

  Future<void> saveToFile() async {
    await _saveToFile();
  }

  Future<Map<String, int>> getCategoryStats() async {
    if (!_isInitialized) await initDatabase();
  
    final categoryStats = <String, int>{};
    for (final item in _equipment) {
      final category = item['category']?.toString() ?? 'Не указана';
      categoryStats[category] = (categoryStats[category] ?? 0) + 1;
    }
    return categoryStats;
  }

  // Метод для ручного исправления
  Future<void> fixDatabase() async {
    if (!_isInitialized) await initDatabase();
    await _fixAllDataTypes();
    print('База данных исправлена вручную');
  }

  // Метод для обновления кэша
  Future<void> refreshCache() async {
    _equipmentCache = null;
    _cacheTimestamp = null;
    await getEquipment(forceRefresh: true);
    print('Кэш обновлен');
  }

  // Быстрый доступ к часто используемым данным
  Future<Map<String, List<Map<String, dynamic>>>> getQuickStatsData() async {
    if (!_isInitialized) await initDatabase();
    
    return {
      'in_use': _equipment.where((item) => item['status'] == 'В использовании').take(10).toList(),
      'in_stock': _equipment.where((item) => item['status'] == 'На складе').take(10).toList(),
      'recent': _equipment.take(10).toList(),
      'recent_movements': await getRecentMovements(limit: 10),
    };
  }
}