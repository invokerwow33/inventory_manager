import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/consumable.dart';
import '../services/storage_service.dart';

class ConsumableProvider extends ChangeNotifier {
  final _storage = StorageService();
  List<Consumable> _consumables = [];
  bool _isLoading = false;
  String? _error;

  List<Consumable> get consumables => _consumables;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Consumable> get lowStockConsumables => 
    _consumables.where((c) => c.isLowStock).toList();

  Future<void> loadConsumables() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = _storage.getConsumables();
      _consumables = data.map((item) => Consumable.fromMap(item)).toList();
      debugPrint('[Consumable] Загружено ${_consumables.length} ед. расходников');
    } catch (e) {
      _error = 'Ошибка загрузки: $e';
      debugPrint('[Consumable] Ошибка загрузки: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addConsumable({
    required String name,
    required String category,
    required int quantity,
    required int minQuantity,
    String? unit,
    String? locationId,
    double? pricePerUnit,
    String? description,
  }) async {
    try {
      final item = Consumable(
        id: const Uuid().v4(),
        name: name,
        category: category,
        quantity: quantity,
        minQuantity: minQuantity,
        unit: unit,
        locationId: locationId,
        pricePerUnit: pricePerUnit,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _storage.saveConsumable(item.toMap());
      _consumables.add(item);
      
      debugPrint('[Consumable] Добавлено: $name');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка добавления: $e';
      debugPrint('[Consumable] Ошибка добавления: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateConsumable(String id, {
    String? name,
    String? category,
    int? quantity,
    int? minQuantity,
    String? unit,
    String? locationId,
    double? pricePerUnit,
    String? description,
  }) async {
    try {
      final index = _consumables.indexWhere((c) => c.id == id);
      if (index < 0) {
        _error = 'Расходник не найден';
        notifyListeners();
        return false;
      }

      final item = _consumables[index].copyWith(
        name: name,
        category: category,
        quantity: quantity,
        minQuantity: minQuantity,
        unit: unit,
        locationId: locationId,
        pricePerUnit: pricePerUnit,
        description: description,
        updatedAt: DateTime.now(),
      );

      await _storage.saveConsumable(item.toMap());
      _consumables[index] = item;
      
      debugPrint('[Consumable] Обновлено: $name');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка обновления: $e';
      debugPrint('[Consumable] Ошибка обновления: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteConsumable(String id) async {
    try {
      await _storage.deleteConsumable(id);
      _consumables.removeWhere((c) => c.id == id);
      
      debugPrint('[Consumable] Удалено: $id');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка удаления: $e';
      debugPrint('[Consumable] Ошибка удаления: $e');
      notifyListeners();
      return false;
    }
  }

  // Изменение количества
  Future<bool> adjustQuantity(String id, int delta) async {
    try {
      final index = _consumables.indexWhere((c) => c.id == id);
      if (index < 0) {
        _error = 'Расходник не найден';
        notifyListeners();
        return false;
      }

      final newQuantity = _consumables[index].quantity + delta;
      if (newQuantity < 0) {
        _error = 'Недостаточно на складе';
        notifyListeners();
        return false;
      }

      final item = _consumables[index].copyWith(
        quantity: newQuantity,
        updatedAt: DateTime.now(),
      );

      await _storage.saveConsumable(item.toMap());
      _consumables[index] = item;
      
      debugPrint('[Consumable] Количество изменено: ${item.name} на $delta');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка изменения количества: $e';
      debugPrint('[Consumable] Ошибка изменения количества: $e');
      notifyListeners();
      return false;
    }
  }

  Consumable? getById(String id) {
    try {
      return _consumables.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
