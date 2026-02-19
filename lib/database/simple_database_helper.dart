import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class SimpleDatabaseHelper {
  static final SimpleDatabaseHelper _instance = SimpleDatabaseHelper._internal();
  factory SimpleDatabaseHelper() => _instance;
  SimpleDatabaseHelper._internal();

  List<Map<String, dynamic>> _equipment = [];
  List<Map<String, dynamic>> _movements = [];
  List<Map<String, dynamic>> _consumables = [];
  List<Map<String, dynamic>> _consumableMovements = [];
  List<Map<String, dynamic>> _employees = [];
  
  late File _databaseFile;
  late File _movementsFile;
  late File _consumablesFile;
  late File _consumableMovementsFile;
  late File _employeesFile;
  bool _isInitialized = false;
  
  // Кэш для производительности
  List<Map<String, dynamic>>? _equipmentCache;
  DateTime? _cacheTimestamp;
  final Duration _cacheDuration = AppConstants.equipmentCacheDuration;

  Future<void> initDatabase() async {
    if (_isInitialized) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      _databaseFile = File('${directory.path}/inventory.json');
      _movementsFile = File('${directory.path}/movements.json');
      _consumablesFile = File('${directory.path}/consumables.json');
      _consumableMovementsFile = File('${directory.path}/consumable_movements.json');
      _employeesFile = File('${directory.path}/employees.json');
      
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
      
      // Загрузка расходников
      if (await _consumablesFile.exists()) {
        final content = await _consumablesFile.readAsString();
        if (content.isNotEmpty) {
          final data = jsonDecode(content);
          _consumables = List<Map<String, dynamic>>.from(data);
        } else {
          _consumables = [];
        }
      } else {
        _consumables = [];
        await _saveConsumablesToFile();
      }
      
      // Загрузка движений расходников
      if (await _consumableMovementsFile.exists()) {
        final content = await _consumableMovementsFile.readAsString();
        if (content.isNotEmpty) {
          final data = jsonDecode(content);
          _consumableMovements = List<Map<String, dynamic>>.from(data);
        } else {
          _consumableMovements = [];
        }
      } else {
        _consumableMovements = [];
        await _saveConsumableMovementsToFile();
      }
      
      // Загрузка сотрудников
      if (await _employeesFile.exists()) {
        final content = await _employeesFile.readAsString();
        if (content.isNotEmpty) {
          final data = jsonDecode(content);
          _employees = List<Map<String, dynamic>>.from(data);
        } else {
          _employees = [];
        }
      } else {
        _employees = [];
        await _saveEmployeesToFile();
      }
      
      _isInitialized = true;
      print('База данных инициализирована. Оборудование: ${_equipment.length}, Перемещений: ${_movements.length}, Расходников: ${_consumables.length}, Сотрудников: ${_employees.length}');
    } catch (e) {
      print('Ошибка инициализации базы данных: $e');
      _equipment = [];
      _movements = [];
      _consumables = [];
      _consumableMovements = [];
      _employees = [];
      _isInitialized = true;
    }
  }

  // ГАРАНТИРУЕТ, что все значения - строки
  String _ensureString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  // Safely compares IDs regardless of type (int or String)
  // Handles backward compatibility with mixed ID types
  bool _idsMatch(dynamic first, dynamic second) {
    return first?.toString() == second?.toString();
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

      // ID должен быть String - конвертируем int в String для совместимости
      final dynamic rawId = item['id'];
      final String fixedId = rawId?.toString() ?? '';

      final fixedItem = <String, dynamic>{
        'id': item['id'].toString(),
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

    // Validate input
    final validationError = Validators.validateEquipment(equipment);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final index = _equipment.indexWhere((item) => _idsMatch(item['id'], equipment['id']));
    if (index != -1) {
      final existing = _equipment[index];

      // Создаем полностью новую запись
      // ID всегда сохраняем как String для консистентности
      final updated = <String, dynamic>{
        'id': _ensureString(equipment['id'] ?? existing['id']),
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
  // Всегда возвращает String для консистентности типов
  String _generateEquipmentId() {
    if (_equipment.isEmpty) {
      return '${AppConstants.equipmentIdPrefix}1';
    }

    final lastId = _equipment.last['id'] ?? '';

    // Если последний ID - строка с префиксом, продолжаем эту нумерацию
    if (lastId is String && lastId.startsWith(AppConstants.equipmentIdPrefix)) {
      final prefixLength = AppConstants.equipmentIdPrefix.length;
      final number = int.tryParse(lastId.substring(prefixLength)) ?? 0;
      return '${AppConstants.equipmentIdPrefix}${number + 1}';
    }

    // Если последний ID - число или строка-число, преобразуем в формат с префиксом
    int? lastNumber;
    if (lastId is int) {
      lastNumber = lastId;
    } else {
      lastNumber = int.tryParse(lastId.toString());
    }

    if (lastNumber != null) {
      return '${AppConstants.equipmentIdPrefix}${lastNumber + 1}';
    }

    // По умолчанию начинаем с eq_1
    return '${AppConstants.equipmentIdPrefix}1';
  }

  Future<String> insertEquipment(Map<String, dynamic> equipment) async {
    if (!_isInitialized) await initDatabase();

    // Validate input
    final validationError = Validators.validateEquipment(equipment);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    // Используем предоставленный ID или генерируем новый
    // Всегда сохраняем как String для консистентности
    final String newId = equipment['id']?.toString() ?? _generateEquipmentId();

    final newEquipment = <String, dynamic>{
      'id': newId,
      'name': _ensureString(equipment['name']),
      'category': _ensureString(equipment['category']),
      'serial_number': _ensureString(equipment['serial_number']),
      'inventory_number': _ensureString(equipment['inventory_number']),
      'status': _ensureString(equipment['status'] ?? AppConstants.equipmentStatusInStock),
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
      (item) => _idsMatch(item['id'], id),
      orElse: () => {},
    );
  }

  Future<int> deleteEquipment(dynamic id) async {
    if (!_isInitialized) await initDatabase();
    
    final initialLength = _equipment.length;
    _equipment.removeWhere((item) => _idsMatch(item['id'], id));
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

    // Validate input
    final validationError = Validators.validateMovement(movement);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final newMovement = Map<String, dynamic>.from(movement);
    newMovement['id'] = _movements.isEmpty
        ? 1
        : (_movements.last['id'] as int? ?? 0) + 1;
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
        .where((movement) => _idsMatch(movement['equipment_id'], equipmentId))
        .toList();

    // Сортируем по дате (новые сверху)
    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a['movement_date'] ?? a['created_at'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['movement_date'] ?? b['created_at'] ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    return filtered;
  }

  Future<List<Map<String, dynamic>>> getRecentMovements({int limit = 50}) async {
    if (!_isInitialized) await initDatabase();

    // Сортируем по дате (новые сверху)
    final sorted = List<Map<String, dynamic>>.from(_movements)
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a['movement_date'] ?? a['created_at'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['movement_date'] ?? b['created_at'] ?? '') ?? DateTime.now();
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
      'in_use': _equipment.where((item) => item['status'] == AppConstants.equipmentStatusInUse).length,
      'in_stock': _equipment.where((item) => item['status'] == AppConstants.equipmentStatusInStock).length,
      'under_repair': _equipment.where((item) => item['status'] == AppConstants.equipmentStatusUnderRepair).length,
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
    _consumables.clear();
    _consumableMovements.clear();
    _employees.clear();
    await _saveToFile();
    await _saveMovementsToFile();
    await _saveConsumablesToFile();
    await _saveConsumableMovementsToFile();
    await _saveEmployeesToFile();
  }

  // === МЕТОДЫ СОХРАНЕНИЯ ДЛЯ НОВЫХ СУЩНОСТЕЙ ===

  Future<void> _saveConsumablesToFile() async {
    try {
      await _consumablesFile.writeAsString(jsonEncode(_consumables));
      print('Расходники сохранены. Всего: ${_consumables.length}');
    } catch (e) {
      print('Ошибка сохранения расходников: $e');
    }
  }

  Future<void> _saveConsumableMovementsToFile() async {
    try {
      await _consumableMovementsFile.writeAsString(jsonEncode(_consumableMovements));
      print('Движения расходников сохранены. Всего: ${_consumableMovements.length}');
    } catch (e) {
      print('Ошибка сохранения движений расходников: $e');
    }
  }

  Future<void> _saveEmployeesToFile() async {
    try {
      await _employeesFile.writeAsString(jsonEncode(_employees));
      print('Сотрудники сохранены. Всего: ${_employees.length}');
    } catch (e) {
      print('Ошибка сохранения сотрудников: $e');
    }
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
      'in_use': _equipment.where((item) => item['status'] == AppConstants.equipmentStatusInUse).take(10).toList(),
      'in_stock': _equipment.where((item) => item['status'] == AppConstants.equipmentStatusInStock).take(10).toList(),
      'recent': _equipment.take(10).toList(),
      'recent_movements': await getRecentMovements(limit: 10),
    };
  }

  // === МЕТОДЫ ДЛЯ ФИЛЬТРАЦИИ ОТЧЕТОВ ===

  /// Получение уникальных категорий для фильтра
  Future<List<String>> getCategories() async {
    if (!_isInitialized) await initDatabase();
    
    final categories = _equipment
        .map((item) => item['category']?.toString().trim() ?? 'Не указана')
        .where((cat) => cat.isNotEmpty)
        .toSet()
        .toList();
    
    categories.sort();
    return categories;
  }

  /// Комплексная фильтрация оборудования
  Future<List<Map<String, dynamic>>> filterEquipment({
    String? category,
    List<String>? statuses,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? searchQuery,
  }) async {
    if (!_isInitialized) await initDatabase();
    
    return _equipment.where((item) {
      // Фильтр по категории
      if (category != null && category.isNotEmpty && category != 'Все категории') {
        final itemCategory = item['category']?.toString().trim() ?? 'Не указана';
        if (itemCategory != category) return false;
      }
      
      // Фильтр по статусам
      if (statuses != null && statuses.isNotEmpty) {
        final itemStatus = item['status']?.toString() ?? '';
        if (!statuses.contains(itemStatus)) return false;
      }
      
      // Фильтр по дате создания (от)
      if (dateFrom != null) {
        final createdAt = DateTime.tryParse(item['created_at']?.toString() ?? '');
        if (createdAt != null && createdAt.isBefore(dateFrom)) return false;
      }
      
      // Фильтр по дате создания (до)
      if (dateTo != null) {
        final createdAt = DateTime.tryParse(item['created_at']?.toString() ?? '');
        if (createdAt != null && createdAt.isAfter(dateTo.add(const Duration(days: 1)))) return false;
      }
      
      // Фильтр по поисковому запросу
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final name = item['name']?.toString().toLowerCase() ?? '';
        final inventoryNumber = item['inventory_number']?.toString().toLowerCase() ?? '';
        final serialNumber = item['serial_number']?.toString().toLowerCase() ?? '';
        
        if (!name.contains(query) && 
            !inventoryNumber.contains(query) && 
            !serialNumber.contains(query)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  /// Экспорт списка оборудования в CSV
  Future<String> exportEquipmentListToCSV(List<Map<String, dynamic>> equipmentList) async {
    final csvData = StringBuffer();
    
    csvData.writeln('ID,Название,Категория,Серийный номер,Инвентарный номер,Статус,Ответственный,Местоположение,Дата покупки,Примечания');
    
    for (final item in equipmentList) {
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

  // === МЕТОДЫ ДЛЯ РАСХОДНИКОВ ===

  Future<List<Map<String, dynamic>>> getConsumables() async {
    if (!_isInitialized) await initDatabase();
    return List.from(_consumables);
  }

  Future<Map<String, dynamic>?> getConsumableById(String id) async {
    if (!_isInitialized) await initDatabase();
    try {
      return _consumables.firstWhere((item) => item['id']?.toString() == id);
    } catch (e) {
      return null;
    }
  }

  Future<String> insertConsumable(Map<String, dynamic> consumable) async {
    if (!_isInitialized) await initDatabase();

    // Validate input
    final validationError = Validators.validateConsumable(consumable);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final newId = consumable['id'] ?? '${AppConstants.consumableIdPrefix}${DateTime.now().millisecondsSinceEpoch}';
    final newConsumable = <String, dynamic>{
      'id': newId,
      'name': _ensureString(consumable['name']),
      'category': _ensureString(consumable['category']),
      'unit': _ensureString(consumable['unit']),
      'quantity': (consumable['quantity'] ?? 0).toDouble(),
      'min_quantity': (consumable['min_quantity'] ?? 0).toDouble(),
      'supplier': _ensureString(consumable['supplier']),
      'notes': _ensureString(consumable['notes']),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    _consumables.add(newConsumable);
    await _saveConsumablesToFile();
    return newId.toString();
  }

  Future<int> updateConsumable(Map<String, dynamic> consumable) async {
    if (!_isInitialized) await initDatabase();

    // Validate input
    final validationError = Validators.validateConsumable(consumable);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final index = _consumables.indexWhere((item) => item['id']?.toString() == consumable['id']?.toString());
    if (index != -1) {
      final existing = _consumables[index];
      final updated = <String, dynamic>{
        'id': existing['id'],
        'name': _ensureString(consumable['name'] ?? existing['name']),
        'category': _ensureString(consumable['category'] ?? existing['category']),
        'unit': _ensureString(consumable['unit'] ?? existing['unit']),
        'quantity': (consumable['quantity'] ?? existing['quantity'] ?? 0).toDouble(),
        'min_quantity': (consumable['min_quantity'] ?? existing['min_quantity'] ?? 0).toDouble(),
        'supplier': _ensureString(consumable['supplier'] ?? existing['supplier']),
        'notes': _ensureString(consumable['notes'] ?? existing['notes']),
        'created_at': existing['created_at'],
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      _consumables[index] = updated;
      await _saveConsumablesToFile();
      return 1;
    }
    return 0;
  }

  Future<int> deleteConsumable(String id) async {
    if (!_isInitialized) await initDatabase();
    
    final initialLength = _consumables.length;
    _consumables.removeWhere((item) => item['id']?.toString() == id);
    if (_consumables.length != initialLength) {
      await _saveConsumablesToFile();
      return 1;
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> searchConsumables(String query) async {
    if (!_isInitialized) await initDatabase();
    
    if (query.isEmpty) return getConsumables();
    
    final lowerQuery = query.toLowerCase();
    return _consumables.where((item) {
      return (item['name']?.toString().toLowerCase().contains(lowerQuery) ?? false) ||
             (item['category']?.toString().toLowerCase().contains(lowerQuery) ?? false) ||
             (item['supplier']?.toString().toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getLowStockConsumables() async {
    if (!_isInitialized) await initDatabase();
    
    return _consumables.where((item) {
      final quantity = (item['quantity'] ?? 0).toDouble();
      final minQuantity = (item['min_quantity'] ?? 0).toDouble();
      return quantity <= minQuantity && minQuantity > 0;
    }).toList();
  }

  // === МЕТОДЫ ДЛЯ ДВИЖЕНИЯ РАСХОДНИКОВ ===

  Future<int> addConsumableMovement(Map<String, dynamic> movement) async {
    if (!_isInitialized) await initDatabase();

    // Validate input
    final validationError = Validators.validateConsumableMovement(movement);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final newId = _consumableMovements.isEmpty
        ? 1
        : (_consumableMovements.last['id'] as int? ?? 0) + 1;
    final newMovement = <String, dynamic>{
      'id': newId,
      'consumable_id': _ensureString(movement['consumable_id']),
      'consumable_name': _ensureString(movement['consumable_name']),
      'quantity': (movement['quantity'] ?? 0).toDouble(),
      'operation_type': _ensureString(movement['operation_type']),
      'operation_date': movement['operation_date']?.toString() ?? DateTime.now().toIso8601String(),
      'employee_id': movement['employee_id'] != null ? _ensureString(movement['employee_id']) : null,
      'employee_name': movement['employee_name'] != null ? _ensureString(movement['employee_name']) : null,
      'document_number': _ensureString(movement['document_number']),
      'notes': _ensureString(movement['notes']),
      'created_at': DateTime.now().toIso8601String(),
    };
    
    _consumableMovements.add(newMovement);
    await _saveConsumableMovementsToFile();
    
    // Обновляем количество расходника
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
        
        final updatedConsumable = Map<String, dynamic>.from(consumable);
        updatedConsumable['quantity'] = newQuantity;
        updatedConsumable['updated_at'] = DateTime.now().toIso8601String();
        await updateConsumable(updatedConsumable);
      }
    }
    
    return newId;
  }

  Future<List<Map<String, dynamic>>> getConsumableMovements(String? consumableId) async {
    if (!_isInitialized) await initDatabase();
    
    var filtered = List<Map<String, dynamic>>.from(_consumableMovements);
    
    if (consumableId != null && consumableId.isNotEmpty) {
      filtered = filtered.where((m) => m['consumable_id']?.toString() == consumableId).toList();
    }
    
    // Сортируем по дате (новые сверху)
    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a['operation_date']?.toString() ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['operation_date']?.toString() ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });
    
    return filtered;
  }

  // === МЕТОДЫ ДЛЯ СОТРУДНИКОВ ===

  Future<List<Map<String, dynamic>>> getEmployees({bool includeInactive = false}) async {
    if (!_isInitialized) await initDatabase();
    
    if (includeInactive) {
      return List.from(_employees);
    }
    
    return _employees.where((item) => item['is_active'] != false).toList();
  }

  Future<Map<String, dynamic>?> getEmployeeById(String id) async {
    if (!_isInitialized) await initDatabase();
    try {
      return _employees.firstWhere((item) => item['id']?.toString() == id);
    } catch (e) {
      return null;
    }
  }

  Future<String> insertEmployee(Map<String, dynamic> employee) async {
    if (!_isInitialized) await initDatabase();

    // Validate input
    final validationError = Validators.validateEmployee(employee);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final newId = employee['id'] ?? '${AppConstants.employeeIdPrefix}${DateTime.now().millisecondsSinceEpoch}';
    final newEmployee = <String, dynamic>{
      'id': newId,
      'full_name': _ensureString(employee['full_name'] ?? employee['name']),
      'department': _ensureString(employee['department']),
      'position': _ensureString(employee['position']),
      'email': _ensureString(employee['email']),
      'phone': _ensureString(employee['phone']),
      'employee_number': _ensureString(employee['employee_number'] ?? employee['employeeNumber']),
      'notes': _ensureString(employee['notes']),
      'is_active': employee['is_active'] ?? employee['isActive'] ?? true,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    _employees.add(newEmployee);
    await _saveEmployeesToFile();
    return newId.toString();
  }

  Future<int> updateEmployee(Map<String, dynamic> employee) async {
    if (!_isInitialized) await initDatabase();

    // Validate input
    final validationError = Validators.validateEmployee(employee);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final index = _employees.indexWhere((item) => item['id']?.toString() == employee['id']?.toString());
    if (index != -1) {
      final existing = _employees[index];
      final updated = <String, dynamic>{
        'id': existing['id'],
        'full_name': _ensureString(employee['full_name'] ?? employee['name'] ?? existing['full_name']),
        'department': _ensureString(employee['department'] ?? existing['department']),
        'position': _ensureString(employee['position'] ?? existing['position']),
        'email': _ensureString(employee['email'] ?? existing['email']),
        'phone': _ensureString(employee['phone'] ?? existing['phone']),
        'employee_number': _ensureString(employee['employee_number'] ?? employee['employeeNumber'] ?? existing['employee_number']),
        'notes': _ensureString(employee['notes'] ?? existing['notes']),
        'is_active': employee['is_active'] ?? employee['isActive'] ?? existing['is_active'] ?? true,
        'created_at': existing['created_at'],
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      _employees[index] = updated;
      await _saveEmployeesToFile();
      return 1;
    }
    return 0;
  }

  Future<int> deleteEmployee(String id) async {
    if (!_isInitialized) await initDatabase();
    
    // Soft delete - помечаем как неактивного
    final employee = await getEmployeeById(id);
    if (employee != null) {
      final updated = Map<String, dynamic>.from(employee);
      updated['is_active'] = false;
      updated['updated_at'] = DateTime.now().toIso8601String();
      return await updateEmployee(updated);
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> searchEmployees(String query) async {
    if (!_isInitialized) await initDatabase();
    
    if (query.isEmpty) return getEmployees();
    
    final lowerQuery = query.toLowerCase();
    return _employees.where((item) {
      final isActive = item['is_active'] ?? true;
      if (!isActive) return false;
      
      return (item['full_name']?.toString().toLowerCase().contains(lowerQuery) ?? false) ||
             (item['department']?.toString().toLowerCase().contains(lowerQuery) ?? false) ||
             (item['position']?.toString().toLowerCase().contains(lowerQuery) ?? false) ||
             (item['employee_number']?.toString().toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getEmployeeMovements(String employeeId) async {
    if (!_isInitialized) await initDatabase();
    
    final filtered = _movements.where((movement) {
      final toResponsible = movement['to_responsible']?.toString().toLowerCase() ?? '';
      final fromResponsible = movement['from_responsible']?.toString().toLowerCase() ?? '';
      
      // Получаем имя сотрудника
      final employee = _employees.firstWhere(
        (e) => e['id']?.toString() == employeeId,
        orElse: () => {},
      );
      
      if (employee.isEmpty) return false;
      
      final employeeName = employee['full_name']?.toString().toLowerCase() ?? '';
      return toResponsible.contains(employeeName) || fromResponsible.contains(employeeName);
    }).toList();
    
    // Сортируем по дате (новые сверху)
    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a['movement_date']?.toString() ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['movement_date']?.toString() ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });
    
    return filtered;
  }

  Future<List<String>> getDepartments() async {
    if (!_isInitialized) await initDatabase();
    
    final departments = _employees
        .map((item) => item['department']?.toString().trim() ?? '')
        .where((dept) => dept.isNotEmpty)
        .toSet()
        .toList();
    
    departments.sort();
    return departments;
  }

  // === МЕТОДЫ ДЛЯ МАССОВЫХ ОПЕРАЦИЙ ===

  Future<List<int>> performBulkMovement({
    required List<String> equipmentIds,
    required String movementType,
    required String toLocation,
    String? toResponsible,
    String? documentNumber,
    String? notes,
    DateTime? movementDate,
  }) async {
    if (!_isInitialized) await initDatabase();
    
    final results = <int>[];
    final date = movementDate ?? DateTime.now();
    
    for (final equipmentId in equipmentIds) {
      final equipment = await getEquipmentById(equipmentId);
      if (equipment == null || equipment.isEmpty) continue;
      
      final movement = {
        'equipment_id': equipmentId,
        'equipment_name': equipment['name'] ?? '',
        'from_location': equipment['location'] ?? '',
        'to_location': toLocation,
        'from_responsible': equipment['responsible_person'] ?? '',
        'to_responsible': toResponsible ?? '',
        'movement_date': date.toIso8601String(),
        'movement_type': movementType,
        'document_number': documentNumber ?? '',
        'notes': notes ?? '',
      };
      
      final movementId = await addMovement(movement);
      results.add(movementId);
      
      // Обновляем оборудование
      final updatedEquipment = Map<String, dynamic>.from(equipment);
      updatedEquipment['location'] = toLocation;
      if (toResponsible != null && toResponsible.isNotEmpty) {
        updatedEquipment['responsible_person'] = toResponsible;
      }
      
      // Обновляем статус в зависимости от типа операции
      switch (movementType) {
        case AppConstants.movementTypeIssue:
          updatedEquipment['status'] = AppConstants.equipmentStatusInUse;
          break;
        case AppConstants.movementTypeReturn:
          updatedEquipment['status'] = AppConstants.equipmentStatusInStock;
          break;
        case AppConstants.movementTypeWriteOff:
          updatedEquipment['status'] = AppConstants.equipmentStatusWrittenOff;
          break;
      }
      
      await safeUpdateEquipment(updatedEquipment);
    }
    
    return results;
  }

  // === СТАТИСТИКА ===

  Future<Map<String, int>> getConsumableStats() async {
    if (!_isInitialized) await initDatabase();
    
    final lowStock = await getLowStockConsumables();
    
    return {
      'total': _consumables.length,
      'low_stock': lowStock.length,
    };
  }

  Future<Map<String, int>> getEmployeeStats() async {
    if (!_isInitialized) await initDatabase();
    
    final active = _employees.where((e) => e['is_active'] != false).length;
    final inactive = _employees.where((e) => e['is_active'] == false).length;
    
    return {
      'total': _employees.length,
      'active': active,
      'inactive': inactive,
    };
  }

  // === USER METHODS (Stubs for SimpleDatabaseHelper) ===
  
  Future<List<Map<String, dynamic>>> getUsers({bool includeInactive = false}) async {
    return [];
  }

  Future<Map<String, dynamic>?> getUserById(String id) async {
    return null;
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    return null;
  }

  Future<String> insertUser(Map<String, dynamic> user) async {
    return '';
  }

  Future<int> updateUser(Map<String, dynamic> user) async {
    return 0;
  }

  Future<int> deleteUser(String id) async {
    return 0;
  }

  Future<void> updateLastLogin(String userId) async {}

  // === AUDIT LOG METHODS (Stubs) ===
  
  Future<int> addAuditLog(Map<String, dynamic> log) async {
    return 0;
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({
    int limit = 100,
    int offset = 0,
    String? userId,
    String? entityType,
    String? actionType,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    return [];
  }

  // === MAINTENANCE METHODS (Stubs) ===
  
  Future<List<Map<String, dynamic>>> getMaintenanceRecords({String? equipmentId}) async {
    return [];
  }

  Future<String> insertMaintenanceRecord(Map<String, dynamic> record) async {
    return '';
  }

  Future<int> updateMaintenanceRecord(Map<String, dynamic> record) async {
    return 0;
  }

  Future<List<Map<String, dynamic>>> getOverdueMaintenance() async {
    return [];
  }

  Future<List<Map<String, dynamic>>> getUpcomingMaintenance({int days = 7}) async {
    return [];
  }

  // === ROOM METHODS (Stubs) ===
  
  Future<List<Map<String, dynamic>>> getRooms() async {
    return [];
  }

  Future<Map<String, dynamic>?> getRoomById(String id) async {
    return null;
  }

  Future<String> insertRoom(Map<String, dynamic> room) async {
    return '';
  }

  Future<int> updateRoom(Map<String, dynamic> room) async {
    return 0;
  }

  // === VEHICLE METHODS (Stubs) ===
  
  Future<List<Map<String, dynamic>>> getVehicles() async {
    return [];
  }

  Future<Map<String, dynamic>?> getVehicleById(String id) async {
    return null;
  }

  Future<String> insertVehicle(Map<String, dynamic> vehicle) async {
    return '';
  }

  Future<int> updateVehicle(Map<String, dynamic> vehicle) async {
    return 0;
  }

  // === SYNC QUEUE METHODS (Stubs) ===
  
  Future<String> addToSyncQueue(Map<String, dynamic> item) async {
    return '';
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems({int limit = 100}) async {
    return [];
  }

  Future<int> updateSyncItemStatus(String id, String status, {String? errorMessage}) async {
    return 0;
  }

  Future<int> incrementRetryCount(String id) async {
    return 0;
  }

  Future<int> deleteSyncItem(String id) async {
    return 0;
  }

  // === SETTINGS METHODS (Stubs) ===
  
  Future<Map<String, dynamic>?> getAppSettings() async {
    return null;
  }

  Future<void> saveAppSettings(Map<String, dynamic> settings) async {}
}