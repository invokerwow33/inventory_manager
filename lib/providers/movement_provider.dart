import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/movement.dart';

class MovementProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  List<EquipmentMovement> _movements = [];
  List<EquipmentMovement> _filteredMovements = [];
  EquipmentMovement? _selectedMovement;
  bool _isLoading = false;
  String? _error;
  
  // Cache
  DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Getters
  List<EquipmentMovement> get movements => _filteredMovements.isEmpty ? _movements : _filteredMovements;
  List<EquipmentMovement> get allMovements => _movements;
  EquipmentMovement? get selectedMovement => _selectedMovement;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Statistics
  Map<String, int> get statistics {
    return {
      'total': _movements.length,
      'issue': _movements.where((m) => m.movementType == 'Выдача').length,
      'return': _movements.where((m) => m.movementType == 'Возврат').length,
      'transfer': _movements.where((m) => m.movementType == 'Перемещение').length,
      'writeOff': _movements.where((m) => m.movementType == 'Списание').length,
    };
  }

  Future<void> loadMovements({bool forceRefresh = false}) async {
    if (!forceRefresh && 
        _lastFetch != null && 
        DateTime.now().difference(_lastFetch!) < _cacheDuration &&
        _movements.isNotEmpty) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final data = await _dbHelper.getMovements();
      _movements = data.map((map) => EquipmentMovement.fromMap(map)).toList();
      _filteredMovements = [];
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки перемещений: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addMovement(EquipmentMovement movement) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.addMovement(movement.toMap());
      _movements.insert(0, movement);
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка добавления перемещения: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMovementsByEquipment(dynamic equipmentId) async {
    _setLoading(true);
    _clearError();

    try {
      final data = await _dbHelper.getEquipmentMovements(equipmentId);
      _movements = data.map((map) => EquipmentMovement.fromMap(map)).toList();
      _filteredMovements = [];
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки перемещений оборудования: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<List<EquipmentMovement>> getRecentMovements({int limit = 50}) async {
    try {
      final data = await _dbHelper.getRecentMovements(limit: limit);
      return data.map((map) => EquipmentMovement.fromMap(map)).toList();
    } catch (e) {
      _setError('Ошибка загрузки недавних перемещений: $e');
      return [];
    }
  }

  void filterByType(String? type) {
    if (type == null || type.isEmpty) {
      _filteredMovements = [];
    } else {
      _filteredMovements = _movements.where((m) => m.movementType == type).toList();
    }
    notifyListeners();
  }

  void filterByDateRange(DateTime from, DateTime to) {
    _filteredMovements = _movements.where((m) {
      return m.movementDate.isAfter(from) && m.movementDate.isBefore(to.add(const Duration(days: 1)));
    }).toList();
    notifyListeners();
  }

  void search(String query) {
    if (query.isEmpty) {
      _filteredMovements = [];
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredMovements = _movements.where((m) {
        return m.equipmentName.toLowerCase().contains(lowerQuery) ||
               m.fromLocation.toLowerCase().contains(lowerQuery) ||
               m.toLocation.toLowerCase().contains(lowerQuery) ||
               (m.fromResponsible?.toLowerCase().contains(lowerQuery) ?? false) ||
               (m.toResponsible?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  void clearFilters() {
    _filteredMovements = [];
    notifyListeners();
  }

  void selectMovement(EquipmentMovement? movement) {
    _selectedMovement = movement;
    notifyListeners();
  }

  void clearSelection() {
    _selectedMovement = null;
    notifyListeners();
  }

  Future<String> exportToCSV() async {
    try {
      return await _dbHelper.exportMovementsToCSV();
    } catch (e) {
      _setError('Ошибка экспорта: $e');
      return '';
    }
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
