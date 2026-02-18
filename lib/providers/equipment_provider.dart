import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/equipment.dart';

class EquipmentProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  List<Equipment> _equipment = [];
  List<Equipment> _filteredEquipment = [];
  Equipment? _selectedEquipment;
  bool _isLoading = false;
  String? _error;
  
  // Cache
  DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Getters
  List<Equipment> get equipment => _filteredEquipment.isEmpty ? _equipment : _filteredEquipment;
  List<Equipment> get allEquipment => _equipment;
  Equipment? get selectedEquipment => _selectedEquipment;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Statistics
  Map<String, int> get statistics {
    return {
      'total': _equipment.length,
      'inUse': _equipment.where((e) => e.status == EquipmentStatus.inUse).length,
      'inStock': _equipment.where((e) => e.status == EquipmentStatus.inStock).length,
      'underRepair': _equipment.where((e) => e.status == EquipmentStatus.underRepair).length,
      'writtenOff': _equipment.where((e) => e.status == EquipmentStatus.writtenOff).length,
      'reserved': _equipment.where((e) => e.status == EquipmentStatus.reserved).length,
    };
  }

  Future<void> loadEquipment({bool forceRefresh = false}) async {
    if (!forceRefresh && 
        _lastFetch != null && 
        DateTime.now().difference(_lastFetch!) < _cacheDuration &&
        _equipment.isNotEmpty) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final data = await _dbHelper.getEquipment();
      _equipment = data.map((map) => Equipment.fromMap(map)).toList();
      _filteredEquipment = [];
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки оборудования: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addEquipment(Equipment equipment) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.insertEquipment(equipment.toMap());
      _equipment.add(equipment);
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка добавления оборудования: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateEquipment(Equipment equipment) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.updateEquipment(equipment.toMap());
      final index = _equipment.indexWhere((e) => e.id == equipment.id);
      if (index != -1) {
        _equipment[index] = equipment;
      }
      if (_selectedEquipment?.id == equipment.id) {
        _selectedEquipment = equipment;
      }
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка обновления оборудования: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteEquipment(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.deleteEquipment(id);
      _equipment.removeWhere((e) => e.id == id);
      if (_selectedEquipment?.id == id) {
        _selectedEquipment = null;
      }
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка удаления оборудования: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Equipment?> getEquipmentById(String id) async {
    try {
      // Check cache first
      final cached = _equipment.firstWhere(
        (e) => e.id == id,
        orElse: () => null as Equipment,
      );
      if (cached != null) {
        _selectedEquipment = cached;
        notifyListeners();
        return cached;
      }

      final data = await _dbHelper.getEquipmentById(id);
      if (data != null && data.isNotEmpty) {
        _selectedEquipment = Equipment.fromMap(data);
        notifyListeners();
        return _selectedEquipment;
      }
      return null;
    } catch (e) {
      _setError('Ошибка получения оборудования: $e');
      return null;
    }
  }

  void search(String query) {
    if (query.isEmpty) {
      _filteredEquipment = [];
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredEquipment = _equipment.where((e) {
        return e.name.toLowerCase().contains(lowerQuery) ||
               (e.serialNumber?.toLowerCase().contains(lowerQuery) ?? false) ||
               (e.inventoryNumber?.toLowerCase().contains(lowerQuery) ?? false) ||
               (e.department?.toLowerCase().contains(lowerQuery) ?? false) ||
               (e.responsiblePerson?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  void filterByStatus(EquipmentStatus? status) {
    if (status == null) {
      _filteredEquipment = [];
    } else {
      _filteredEquipment = _equipment.where((e) => e.status == status).toList();
    }
    notifyListeners();
  }

  void filterByType(EquipmentType? type) {
    if (type == null) {
      _filteredEquipment = [];
    } else {
      _filteredEquipment = _equipment.where((e) => e.type == type).toList();
    }
    notifyListeners();
  }

  void clearFilters() {
    _filteredEquipment = [];
    notifyListeners();
  }

  void selectEquipment(Equipment? equipment) {
    _selectedEquipment = equipment;
    notifyListeners();
  }

  void clearSelection() {
    _selectedEquipment = null;
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
