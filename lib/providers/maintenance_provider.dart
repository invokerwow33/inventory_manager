import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/maintenance.dart';

class MaintenanceProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  List<MaintenanceRecord> _records = [];
  List<MaintenanceSchedule> _schedules = [];
  List<MaintenanceRecord> _overdue = [];
  List<MaintenanceRecord> _upcoming = [];
  MaintenanceRecord? _selectedRecord;
  bool _isLoading = false;
  String? _error;
  
  DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Getters
  List<MaintenanceRecord> get records => _records;
  List<MaintenanceSchedule> get schedules => _schedules;
  List<MaintenanceRecord> get overdue => _overdue;
  List<MaintenanceRecord> get upcoming => _upcoming;
  MaintenanceRecord? get selectedRecord => _selectedRecord;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Statistics
  Map<String, int> get statistics {
    return {
      'total': _records.length,
      'scheduled': _records.where((r) => r.status == MaintenanceStatus.scheduled).length,
      'inProgress': _records.where((r) => r.status == MaintenanceStatus.inProgress).length,
      'completed': _records.where((r) => r.status == MaintenanceStatus.completed).length,
      'overdue': _overdue.length,
    };
  }

  Future<void> loadMaintenanceRecords({String? equipmentId, bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration &&
        _records.isNotEmpty) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final data = await _dbHelper.getMaintenanceRecords(equipmentId: equipmentId);
      _records = data.map((m) => MaintenanceRecord.fromMap(m)).toList();
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки записей обслуживания: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadOverdueMaintenance() async {
    _setLoading(true);
    try {
      final data = await _dbHelper.getOverdueMaintenance();
      _overdue = data.map((m) => MaintenanceRecord.fromMap(m)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки просроченных записей: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUpcomingMaintenance({int days = 7}) async {
    _setLoading(true);
    try {
      final data = await _dbHelper.getUpcomingMaintenance(days: days);
      _upcoming = data.map((m) => MaintenanceRecord.fromMap(m)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки предстоящих записей: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addMaintenanceRecord(MaintenanceRecord record) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.insertMaintenanceRecord(record.toMap());
      _records.add(record);
      _lastFetch = DateTime.now();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Ошибка добавления записи обслуживания: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateMaintenanceRecord(MaintenanceRecord record) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.updateMaintenanceRecord(record.toMap());
      final index = _records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _records[index] = record;
      }
      if (_selectedRecord?.id == record.id) {
        _selectedRecord = record;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Ошибка обновления записи: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> completeMaintenance(
    String recordId, {
    DateTime? completedDate,
    String? performedBy,
    double? cost,
    String? notes,
  }) async {
    try {
      final record = _records.firstWhere((r) => r.id == recordId);
      final updated = record.copyWith(
        status: MaintenanceStatus.completed,
        completedDate: completedDate ?? DateTime.now(),
        performedBy: performedBy ?? record.performedBy,
        cost: cost ?? record.cost,
        notes: notes ?? record.notes,
        updatedAt: DateTime.now(),
      );
      return await updateMaintenanceRecord(updated);
    } catch (e) {
      _setError('Ошибка завершения обслуживания: $e');
      return false;
    }
  }

  Future<bool> cancelMaintenance(String recordId, {String? reason}) async {
    try {
      final record = _records.firstWhere((r) => r.id == recordId);
      final updated = record.copyWith(
        status: MaintenanceStatus.cancelled,
        notes: reason ?? record.notes,
        updatedAt: DateTime.now(),
      );
      return await updateMaintenanceRecord(updated);
    } catch (e) {
      _setError('Ошибка отмены обслуживания: $e');
      return false;
    }
  }

  Future<bool> startMaintenance(String recordId) async {
    try {
      final record = _records.firstWhere((r) => r.id == recordId);
      final updated = record.copyWith(
        status: MaintenanceStatus.inProgress,
        updatedAt: DateTime.now(),
      );
      return await updateMaintenanceRecord(updated);
    } catch (e) {
      _setError('Ошибка начала обслуживания: $e');
      return false;
    }
  }

  List<MaintenanceRecord> getRecordsByEquipment(String equipmentId) {
    return _records.where((r) => r.equipmentId == equipmentId).toList();
  }

  List<MaintenanceRecord> getRecordsByType(MaintenanceType type) {
    return _records.where((r) => r.type == type).toList();
  }

  List<MaintenanceRecord> getRecordsByStatus(MaintenanceStatus status) {
    return _records.where((r) => r.status == status).toList();
  }

  double getTotalMaintenanceCost({DateTime? from, DateTime? to}) {
    var filtered = _records.where((r) => r.status == MaintenanceStatus.completed);
    
    if (from != null) {
      filtered = filtered.where((r) => 
        r.completedDate != null && r.completedDate!.isAfter(from));
    }
    if (to != null) {
      filtered = filtered.where((r) => 
        r.completedDate != null && r.completedDate!.isBefore(to));
    }
    
    return filtered.fold(0.0, (sum, r) => sum + (r.cost ?? 0));
  }

  Map<MaintenanceType, int> getMaintenanceByType() {
    final result = <MaintenanceType, int>{};
    for (final record in _records) {
      result[record.type] = (result[record.type] ?? 0) + 1;
    }
    return result;
  }

  void selectRecord(MaintenanceRecord? record) {
    _selectedRecord = record;
    notifyListeners();
  }

  void clearSelection() {
    _selectedRecord = null;
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
