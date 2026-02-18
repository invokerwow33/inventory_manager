import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_manager/models/equipment.dart';

void main() {
  group('Equipment', () {
    test('should create Equipment with default status', () {
      final equipment = Equipment(
        id: 'eq_1',
        name: 'Test Equipment',
        type: EquipmentType.computer,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(equipment.id, 'eq_1');
      expect(equipment.name, 'Test Equipment');
      expect(equipment.type, EquipmentType.computer);
      expect(equipment.status, EquipmentStatus.inUse);
    });

    test('should convert to and from Map', () {
      final now = DateTime.now();
      final equipment = Equipment(
        id: 'eq_1',
        name: 'Test Equipment',
        type: EquipmentType.laptop,
        serialNumber: 'SN123456',
        inventoryNumber: 'INV001',
        manufacturer: 'Dell',
        model: 'Latitude 5510',
        purchaseDate: now,
        purchasePrice: 50000.0,
        department: 'IT',
        responsiblePerson: 'Иванов И.И.',
        location: 'Офис 101',
        status: EquipmentStatus.inStock,
        notes: 'Test notes',
        createdAt: now,
        updatedAt: now,
      );

      final map = equipment.toMap();
      expect(map['id'], 'eq_1');
      expect(map['name'], 'Test Equipment');
      expect(map['type'], 'laptop');
      expect(map['serialNumber'], 'SN123456');
      expect(map['inventoryNumber'], 'INV001');
      expect(map['status'], 'inStock');

      final restoredEquipment = Equipment.fromMap(map);
      expect(restoredEquipment.id, equipment.id);
      expect(restoredEquipment.name, equipment.name);
      expect(restoredEquipment.type, equipment.type);
      expect(restoredEquipment.status, equipment.status);
    });

    test('should format purchase date correctly', () {
      final equipment = Equipment(
        id: 'eq_1',
        name: 'Test',
        type: EquipmentType.computer,
        purchaseDate: DateTime(2023, 6, 15),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(equipment.formattedPurchaseDate, '15.06.2023');
    });

    test('should return "Не указано" when no purchase date', () {
      final equipment = Equipment(
        id: 'eq_1',
        name: 'Test',
        type: EquipmentType.computer,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(equipment.formattedPurchaseDate, 'Не указано');
    });

    test('should format price correctly', () {
      final equipment = Equipment(
        id: 'eq_1',
        name: 'Test',
        type: EquipmentType.computer,
        purchasePrice: 123456.78,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(equipment.formattedPrice, '123456.78 ₽');
    });

    test('should return "Не указано" when no price', () {
      final equipment = Equipment(
        id: 'eq_1',
        name: 'Test',
        type: EquipmentType.computer,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(equipment.formattedPrice, 'Не указано');
    });

    test('should parse EquipmentType correctly', () {
      final map = {
        'id': 'eq_1',
        'name': 'Test',
        'type': 'laptop',
        'status': 'inUse',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final equipment = Equipment.fromMap(map);
      expect(equipment.type, EquipmentType.laptop);
    });

    test('should default to computer when type is unknown', () {
      final map = {
        'id': 'eq_1',
        'name': 'Test',
        'type': 'unknown_type',
        'status': 'inUse',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final equipment = Equipment.fromMap(map);
      expect(equipment.type, EquipmentType.computer);
    });

    test('should default to inUse when status is unknown', () {
      final map = {
        'id': 'eq_1',
        'name': 'Test',
        'type': 'computer',
        'status': 'unknown_status',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final equipment = Equipment.fromMap(map);
      expect(equipment.status, EquipmentStatus.inUse);
    });
  });

  group('EquipmentType', () {
    test('should have correct labels and icons', () {
      expect(EquipmentType.computer.label, 'Компьютер');
      expect(EquipmentType.computer.icon, Icons.computer);
      expect(EquipmentType.laptop.label, 'Ноутбук');
      expect(EquipmentType.laptop.icon, Icons.laptop);
    });
  });

  group('EquipmentStatus', () {
    test('should have correct labels and colors', () {
      expect(EquipmentStatus.inUse.label, 'В использовании');
      expect(EquipmentStatus.inUse.color, Colors.green);
      expect(EquipmentStatus.inStock.label, 'На складе');
      expect(EquipmentStatus.inStock.color, Colors.blue);
    });
  });
}
