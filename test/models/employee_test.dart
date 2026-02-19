import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_manager/models/employee.dart';

void main() {
  group('Employee', () {
    test('should create Employee with default isActive', () {
      final employee = Employee(
        id: 'emp_1',
        fullName: 'Иванов Иван Иванович',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(employee.id, 'emp_1');
      expect(employee.fullName, 'Иванов Иван Иванович');
      expect(employee.isActive, true);
    });

    test('should calculate initials correctly for full name', () {
      final employee = Employee(
        id: 'emp_1',
        fullName: 'Иванов Иван Иванович',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(employee.initials, 'ИИ');
    });

    test('should calculate initials correctly for single name', () {
      final employee = Employee(
        id: 'emp_1',
        fullName: 'Иванов',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(employee.initials, 'И');
    });

    test('should return ?? for empty name', () {
      final employee = Employee(
        id: 'emp_1',
        fullName: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(employee.initials, '??');
    });

    test('should convert to and from Map', () {
      final now = DateTime.now();
      final employee = Employee(
        id: 'emp_1',
        fullName: 'Иванов Иван Иванович',
        department: 'IT',
        position: 'Разработчик',
        email: 'ivan@example.com',
        phone: '+79001234567',
        employeeNumber: 'EMP001',
        notes: 'Test notes',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = employee.toMap();
      expect(map['id'], 'emp_1');
      expect(map['full_name'], 'Иванов Иван Иванович');
      expect(map['department'], 'IT');
      expect(map['position'], 'Разработчик');
      expect(map['email'], 'ivan@example.com');
      expect(map['is_active'], 1);

      final restoredEmployee = Employee.fromMap(map);
      expect(restoredEmployee.id, employee.id);
      expect(restoredEmployee.fullName, employee.fullName);
      expect(restoredEmployee.department, employee.department);
      expect(restoredEmployee.isActive, employee.isActive);
    });

    test('should handle Map with alternative field names', () {
      final map = {
        'id': 'emp_1',
        'name': 'Иванов Иван',  // alternative to full_name
        'department': 'IT',
        'isActive': false,  // alternative to is_active
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final employee = Employee.fromMap(map);
      expect(employee.fullName, 'Иванов Иван');
      expect(employee.isActive, false);
    });

    test('copyWith should create copy with updated fields', () {
      final employee = Employee(
        id: 'emp_1',
        fullName: 'Иванов Иван Иванович',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updatedEmployee = employee.copyWith(
        fullName: 'Петров Петр Петрович',
        department: 'HR',
      );

      expect(updatedEmployee.id, employee.id);
      expect(updatedEmployee.fullName, 'Петров Петр Петрович');
      expect(updatedEmployee.department, 'HR');
      expect(updatedEmployee.position, employee.position);
    });

    test('should display correct displayInfo', () {
      final employee1 = Employee(
        id: 'emp_1',
        fullName: 'Иванов Иван',
        position: 'Разработчик',
        department: 'IT',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(employee1.displayInfo, 'Разработчик • IT');

      final employee2 = Employee(
        id: 'emp_2',
        fullName: 'Петров Петр',
        position: 'Менеджер',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(employee2.displayInfo, 'Менеджер');

      final employee3 = Employee(
        id: 'emp_3',
        fullName: 'Сидоров Сидор',
        department: 'Бухгалтерия',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(employee3.displayInfo, 'Бухгалтерия');
    });
  });

  group('EmployeeEquipment', () {
    test('should determine isActive correctly', () {
      final activeEquipment = EmployeeEquipment(
        equipmentId: 'eq_1',
        equipmentName: 'Laptop',
        issuedAt: DateTime.now(),
      );
      expect(activeEquipment.isActive, true);

      final inactiveEquipment = EmployeeEquipment(
        equipmentId: 'eq_2',
        equipmentName: 'Monitor',
        issuedAt: DateTime.now(),
        returnedAt: DateTime.now(),
      );
      expect(inactiveEquipment.isActive, false);
    });
  });

  group('EmployeeMovementSummary', () {
    test('should format date correctly', () {
      final movement = EmployeeMovementSummary(
        movementType: 'Выдача',
        equipmentName: 'Laptop',
        date: DateTime(2023, 6, 15, 14, 30),
      );

      expect(movement.formattedDate, '15.06.2023');
      expect(movement.formattedDateTime, '15.06.2023 14:30');
    });

    test('should return correct icon and color', () {
      final issue = EmployeeMovementSummary(
        movementType: 'Выдача',
        equipmentName: 'Laptop',
        date: DateTime.now(),
      );

      expect(issue.icon, Icons.arrow_forward);
      expect(issue.color, isNotNull);
    });
  });
}
