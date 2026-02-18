import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/employee.dart';

class EmployeeProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  Employee? _selectedEmployee;
  bool _isLoading = false;
  String? _error;
  
  // Cache
  DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Getters
  List<Employee> get employees => _filteredEmployees.isEmpty ? _employees : _filteredEmployees;
  List<Employee> get allEmployees => _employees;
  List<Employee> get activeEmployees => _employees.where((e) => e.isActive).toList();
  Employee? get selectedEmployee => _selectedEmployee;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Statistics
  Map<String, int> get statistics {
    final active = _employees.where((e) => e.isActive).length;
    final inactive = _employees.where((e) => !e.isActive).length;
    return {
      'total': _employees.length,
      'active': active,
      'inactive': inactive,
    };
  }

  Future<void> loadEmployees({bool forceRefresh = false, bool includeInactive = false}) async {
    if (!forceRefresh && 
        _lastFetch != null && 
        DateTime.now().difference(_lastFetch!) < _cacheDuration &&
        _employees.isNotEmpty) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final data = await _dbHelper.getEmployees(includeInactive: includeInactive);
      _employees = data.map((map) => Employee.fromMap(map)).toList();
      _filteredEmployees = [];
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки сотрудников: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addEmployee(Employee employee) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.insertEmployee(employee.toMap());
      _employees.add(employee);
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка добавления сотрудника: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateEmployee(Employee employee) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.updateEmployee(employee.toMap());
      final index = _employees.indexWhere((e) => e.id == employee.id);
      if (index != -1) {
        _employees[index] = employee;
      }
      if (_selectedEmployee?.id == employee.id) {
        _selectedEmployee = employee;
      }
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка обновления сотрудника: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteEmployee(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.deleteEmployee(id);
      // Soft delete - update local state
      final index = _employees.indexWhere((e) => e.id == id);
      if (index != -1) {
        _employees[index] = _employees[index].copyWith(isActive: false);
      }
      if (_selectedEmployee?.id == id) {
        _selectedEmployee = null;
      }
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка удаления сотрудника: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Employee?> getEmployeeById(String id) async {
    try {
      // Check cache first
      final cached = _employees.firstWhere(
        (e) => e.id == id,
        orElse: () => null as Employee,
      );
      if (cached != null) {
        _selectedEmployee = cached;
        notifyListeners();
        return cached;
      }

      final data = await _dbHelper.getEmployeeById(id);
      if (data != null && data.isNotEmpty) {
        _selectedEmployee = Employee.fromMap(data);
        notifyListeners();
        return _selectedEmployee;
      }
      return null;
    } catch (e) {
      _setError('Ошибка получения сотрудника: $e');
      return null;
    }
  }

  void search(String query) {
    if (query.isEmpty) {
      _filteredEmployees = [];
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredEmployees = _employees.where((e) {
        return e.fullName.toLowerCase().contains(lowerQuery) ||
               (e.department?.toLowerCase().contains(lowerQuery) ?? false) ||
               (e.position?.toLowerCase().contains(lowerQuery) ?? false) ||
               (e.employeeNumber?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  void filterByDepartment(String? department) {
    if (department == null || department.isEmpty) {
      _filteredEmployees = [];
    } else {
      _filteredEmployees = _employees.where((e) => e.department == department).toList();
    }
    notifyListeners();
  }

  void filterByStatus(bool? isActive) {
    if (isActive == null) {
      _filteredEmployees = [];
    } else {
      _filteredEmployees = _employees.where((e) => e.isActive == isActive).toList();
    }
    notifyListeners();
  }

  void clearFilters() {
    _filteredEmployees = [];
    notifyListeners();
  }

  void selectEmployee(Employee? employee) {
    _selectedEmployee = employee;
    notifyListeners();
  }

  void clearSelection() {
    _selectedEmployee = null;
    notifyListeners();
  }

  Future<List<String>> getDepartments() async {
    try {
      return await _dbHelper.getDepartments();
    } catch (e) {
      _setError('Ошибка загрузки отделов: $e');
      return [];
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
