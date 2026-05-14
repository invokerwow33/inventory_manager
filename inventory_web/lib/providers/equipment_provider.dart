import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/equipment.dart';
import '../services/storage_service.dart';

class EquipmentProvider extends ChangeNotifier {
  final _storage = StorageService();
  List<Equipment> _equipment = [];
  bool _isLoading = false;
  String? _error;

  List<Equipment> get equipment => _equipment;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Equipment> get availableEquipment => 
    _equipment.where((e) => e.status == EquipmentStatus.available).toList();

  List<Equipment> get inUseEquipment => 
    _equipment.where((e) => e.status == EquipmentStatus.inUse).toList();

  Future<void> loadEquipment() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = _storage.getEquipment();
      _equipment = data.map((item) => Equipment.fromMap(item)).toList();
      debugPrint('[Equipment] Загружено ${_equipment.length} ед. оборудования');
    } catch (e) {
      _error = 'Ошибка загрузки: $e';
      debugPrint('[Equipment] Ошибка загрузки: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addEquipment({
    required String name,
    required String serialNumber,
    String? category,
    String? locationId,
    DateTime? purchaseDate,
    double? price,
    String? description,
  }) async {
    try {
      final item = Equipment(
        id: const Uuid().v4(),
        name: name,
        serialNumber: serialNumber,
        category: category,
        locationId: locationId,
        status: EquipmentStatus.available,
        purchaseDate: purchaseDate ?? DateTime.now(),
        price: price,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _storage.saveEquipment(item.toMap());
      _equipment.add(item);
      
      debugPrint('[Equipment] Добавлено: $name');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка добавления: $e';
      debugPrint('[Equipment] Ошибка добавления: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEquipment(String id, {
    String? name,
    String? serialNumber,
    String? category,
    String? locationId,
    EquipmentStatus? status,
    DateTime? purchaseDate,
    double? price,
    String? description,
  }) async {
    try {
      final index = _equipment.indexWhere((e) => e.id == id);
      if (index < 0) {
        _error = 'Оборудование не найдено';
        notifyListeners();
        return false;
      }

      final item = _equipment[index].copyWith(
        name: name,
        serialNumber: serialNumber,
        category: category,
        locationId: locationId,
        status: status,
        purchaseDate: purchaseDate,
        price: price,
        description: description,
        updatedAt: DateTime.now(),
      );

      await _storage.saveEquipment(item.toMap());
      _equipment[index] = item;
      
      debugPrint('[Equipment] Обновлено: $name');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка обновления: $e';
      debugPrint('[Equipment] Ошибка обновления: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEquipment(String id) async {
    try {
      await _storage.deleteEquipment(id);
      _equipment.removeWhere((e) => e.id == id);
      
      debugPrint('[Equipment] Удалено: $id');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка удаления: $e';
      debugPrint('[Equipment] Ошибка удаления: $e');
      notifyListeners();
      return false;
    }
  }

  // Выдача оборудования сотруднику
  Future<bool> issueToEmployee(String equipmentId, String employeeId) async {
    try {
      final eqIndex = _equipment.indexWhere((e) => e.id == equipmentId);
      if (eqIndex < 0) {
        _error = 'Оборудование не найдено';
        debugPrint('[Equipment] Оборудование не найдено: $equipmentId');
        notifyListeners();
        return false;
      }

      final item = _equipment[eqIndex].copyWith(
        assignedToEmployeeId: employeeId,
        status: EquipmentStatus.inUse,
        updatedAt: DateTime.now(),
      );

      await _storage.saveEquipment(item.toMap());
      _equipment[eqIndex] = item;
      
      debugPrint('[Equipment] Выдано: ${item.name} сотруднику $employeeId');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка выдачи: $e';
      debugPrint('[Equipment] Ошибка выдачи: $e');
      notifyListeners();
      return false;
    }
  }

  // Возврат оборудования
  Future<bool> returnFromEmployee(String equipmentId) async {
    try {
      final eqIndex = _equipment.indexWhere((e) => e.id == equipmentId);
      if (eqIndex < 0) {
        _error = 'Оборудование не найдено';
        debugPrint('[Equipment] Оборудование не найдено: $equipmentId');
        notifyListeners();
        return false;
      }

      final item = _equipment[eqIndex].copyWith(
        assignedToEmployeeId: null,
        status: EquipmentStatus.available,
        updatedAt: DateTime.now(),
      );

      await _storage.saveEquipment(item.toMap());
      _equipment[eqIndex] = item;
      
      debugPrint('[Equipment] Возвращено: ${item.name}');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка возврата: $e';
      debugPrint('[Equipment] Ошибка возврата: $e');
      notifyListeners();
      return false;
    }
  }

  // Перемещение оборудования
  Future<bool> moveEquipment(String equipmentId, String? newLocationId) async {
    try {
      final eqIndex = _equipment.indexWhere((e) => e.id == equipmentId);
      if (eqIndex < 0) {
        _error = 'Оборудование не найдено';
        debugPrint('[Equipment] Оборудование не найдено: $equipmentId');
        notifyListeners();
        return false;
      }

      final item = _equipment[eqIndex].copyWith(
        locationId: newLocationId,
        updatedAt: DateTime.now(),
      );

      await _storage.saveEquipment(item.toMap());
      _equipment[eqIndex] = item;
      
      debugPrint('[Equipment] Перемещено: ${item.name} в локацию $newLocationId');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка перемещения: $e';
      debugPrint('[Equipment] Ошибка перемещения: $e');
      notifyListeners();
      return false;
    }
  }

  Equipment? getById(String id) {
    try {
      return _equipment.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
