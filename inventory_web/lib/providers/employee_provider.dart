import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/employee.dart';
import '../services/storage_service.dart';

class EmployeeProvider extends ChangeNotifier {
  final _storage = StorageService();
  List<Employee> _employees = [];
  bool _isLoading = false;
  String? _error;

  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Employee> get activeEmployees => 
    _employees.where((e) => e.isActive).toList();

  Future<void> loadEmployees() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = _storage.getEmployees();
      _employees = data.map((item) => Employee.fromMap(item)).toList();
      debugPrint('[Employee] Загружено ${_employees.length} сотрудников');
    } catch (e) {
      _error = 'Ошибка загрузки: $e';
      debugPrint('[Employee] Ошибка загрузки: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addEmployee({
    required String fullName,
    required String position,
    String? department,
    String? email,
    String? phone,
  }) async {
    try {
      final item = Employee(
        id: const Uuid().v4(),
        fullName: fullName,
        position: position,
        department: department,
        email: email,
        phone: phone,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _storage.saveEmployee(item.toMap());
      _employees.add(item);
      
      debugPrint('[Employee] Добавлен: $fullName');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка добавления: $e';
      debugPrint('[Employee] Ошибка добавления: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmployee(String id, {
    String? fullName,
    String? position,
    String? department,
    String? email,
    String? phone,
    bool? isActive,
  }) async {
    try {
      final index = _employees.indexWhere((e) => e.id == id);
      if (index < 0) {
        _error = 'Сотрудник не найден';
        notifyListeners();
        return false;
      }

      final item = _employees[index].copyWith(
        fullName: fullName,
        position: position,
        department: department,
        email: email,
        phone: phone,
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      await _storage.saveEmployee(item.toMap());
      _employees[index] = item;
      
      debugPrint('[Employee] Обновлен: $fullName');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка обновления: $e';
      debugPrint('[Employee] Ошибка обновления: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEmployee(String id) async {
    try {
      await _storage.deleteEmployee(id);
      _employees.removeWhere((e) => e.id == id);
      
      debugPrint('[Employee] Удален: $id');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка удаления: $e';
      debugPrint('[Employee] Ошибка удаления: $e');
      notifyListeners();
      return false;
    }
  }

  // Выдача оборудования сотруднику
  Future<bool> issueEquipment(String employeeId, String equipmentId) async {
    try {
      final index = _employees.indexWhere((e) => e.id == employeeId);
      if (index < 0) {
        _error = 'Сотрудник не найден';
        notifyListeners();
        return false;
      }

      final employee = _employees[index];
      if (employee.equipmentIds.contains(equipmentId)) {
        _error = 'Оборудование уже выдано';
        notifyListeners();
        return false;
      }

      final updatedEquipmentIds = List<String>.from(employee.equipmentIds)
        ..add(equipmentId);

      final item = employee.copyWith(
        equipmentIds: updatedEquipmentIds,
        updatedAt: DateTime.now(),
      );

      await _storage.saveEmployee(item.toMap());
      _employees[index] = item;
      
      debugPrint('[Employee] Оборудование $equipmentId выдано сотруднику $employeeId');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка выдачи оборудования: $e';
      debugPrint('[Employee] Ошибка выдачи: $e');
      notifyListeners();
      return false;
    }
  }

  // Возврат оборудования от сотрудника
  Future<bool> returnEquipment(String employeeId, String equipmentId) async {
    try {
      final index = _employees.indexWhere((e) => e.id == employeeId);
      if (index < 0) {
        _error = 'Сотрудник не найден';
        notifyListeners();
        return false;
      }

      final employee = _employees[index];
      if (!employee.equipmentIds.contains(equipmentId)) {
        _error = 'Оборудование не числится за сотрудником';
        notifyListeners();
        return false;
      }

      final updatedEquipmentIds = List<String>.from(employee.equipmentIds)
        ..remove(equipmentId);

      final item = employee.copyWith(
        equipmentIds: updatedEquipmentIds,
        updatedAt: DateTime.now(),
      );

      await _storage.saveEmployee(item.toMap());
      _employees[index] = item;
      
      debugPrint('[Employee] Оборудование $equipmentId возвращено от сотрудника $employeeId');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка возврата оборудования: $e';
      debugPrint('[Employee] Ошибка возврата: $e');
      notifyListeners();
      return false;
    }
  }

  Employee? getById(String id) {
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
