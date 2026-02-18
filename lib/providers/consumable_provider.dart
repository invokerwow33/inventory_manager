import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/consumable.dart';

class ConsumableProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  List<Consumable> _consumables = [];
  List<Consumable> _filteredConsumables = [];
  List<ConsumableMovement> _movements = [];
  Consumable? _selectedConsumable;
  bool _isLoading = false;
  String? _error;
  
  // Cache
  DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Getters
  List<Consumable> get consumables => _filteredConsumables.isEmpty ? _consumables : _filteredConsumables;
  List<Consumable> get allConsumables => _consumables;
  List<Consumable> get lowStockConsumables => _consumables.where((c) => c.isLowStock).toList();
  List<ConsumableMovement> get movements => _movements;
  Consumable? get selectedConsumable => _selectedConsumable;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Statistics
  Map<String, int> get statistics {
    final lowStock = lowStockConsumables.length;
    return {
      'total': _consumables.length,
      'lowStock': lowStock,
      'normal': _consumables.length - lowStock,
    };
  }

  Future<void> loadConsumables({bool forceRefresh = false}) async {
    if (!forceRefresh && 
        _lastFetch != null && 
        DateTime.now().difference(_lastFetch!) < _cacheDuration &&
        _consumables.isNotEmpty) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final data = await _dbHelper.getConsumables();
      _consumables = data.map((map) => Consumable.fromMap(map)).toList();
      _filteredConsumables = [];
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки расходников: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addConsumable(Consumable consumable) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.insertConsumable(consumable.toMap());
      _consumables.add(consumable);
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка добавления расходника: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateConsumable(Consumable consumable) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.updateConsumable(consumable.toMap());
      final index = _consumables.indexWhere((c) => c.id == consumable.id);
      if (index != -1) {
        _consumables[index] = consumable;
      }
      if (_selectedConsumable?.id == consumable.id) {
        _selectedConsumable = consumable;
      }
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка обновления расходника: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteConsumable(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.deleteConsumable(id);
      _consumables.removeWhere((c) => c.id == id);
      if (_selectedConsumable?.id == id) {
        _selectedConsumable = null;
      }
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка удаления расходника: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Consumable?> getConsumableById(String id) async {
    try {
      // Check cache first
      final cached = _consumables.firstWhere(
        (c) => c.id == id,
        orElse: () => null as Consumable,
      );
      if (cached != null) {
        _selectedConsumable = cached;
        notifyListeners();
        return cached;
      }

      final data = await _dbHelper.getConsumableById(id);
      if (data != null && data.isNotEmpty) {
        _selectedConsumable = Consumable.fromMap(data);
        notifyListeners();
        return _selectedConsumable;
      }
      return null;
    } catch (e) {
      _setError('Ошибка получения расходника: $e');
      return null;
    }
  }

  Future<void> addMovement(ConsumableMovement movement) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.addConsumableMovement(movement.toMap());
      _movements.add(movement);
      
      // Update consumable quantity
      final consumable = await getConsumableById(movement.consumableId);
      if (consumable != null) {
        double newQuantity = consumable.quantity;
        if (movement.isIncoming) {
          newQuantity += movement.quantity;
        } else if (movement.isOutgoing) {
          newQuantity -= movement.quantity;
        }
        
        final updated = consumable.copyWith(quantity: newQuantity);
        await updateConsumable(updated);
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Ошибка добавления движения: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMovements(String? consumableId) async {
    _setLoading(true);
    _clearError();

    try {
      final data = await _dbHelper.getConsumableMovements(consumableId);
      _movements = data.map((map) => ConsumableMovement.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки движений: $e');
    } finally {
      _setLoading(false);
    }
  }

  void search(String query) {
    if (query.isEmpty) {
      _filteredConsumables = [];
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredConsumables = _consumables.where((c) {
        return c.name.toLowerCase().contains(lowerQuery) ||
               c.category.label.toLowerCase().contains(lowerQuery) ||
               (c.supplier?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  void filterByCategory(ConsumableCategory? category) {
    if (category == null) {
      _filteredConsumables = [];
    } else {
      _filteredConsumables = _consumables.where((c) => c.category == category).toList();
    }
    notifyListeners();
  }

  void filterLowStock() {
    _filteredConsumables = _consumables.where((c) => c.isLowStock).toList();
    notifyListeners();
  }

  void clearFilters() {
    _filteredConsumables = [];
    notifyListeners();
  }

  void selectConsumable(Consumable? consumable) {
    _selectedConsumable = consumable;
    notifyListeners();
  }

  void clearSelection() {
    _selectedConsumable = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
