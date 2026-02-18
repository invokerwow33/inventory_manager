import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_manager/models/consumable.dart';

void main() {
  group('Consumable', () {
    test('should create Consumable correctly', () {
      final consumable = Consumable(
        id: 'cons_1',
        name: 'A4 Paper',
        category: ConsumableCategory.paper,
        unit: ConsumableUnit.reams,
        quantity: 50,
        minQuantity: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(consumable.id, 'cons_1');
      expect(consumable.name, 'A4 Paper');
      expect(consumable.category, ConsumableCategory.paper);
      expect(consumable.unit, ConsumableUnit.reams);
      expect(consumable.quantity, 50);
      expect(consumable.minQuantity, 10);
      expect(consumable.isLowStock, false);
    });

    test('should detect low stock correctly', () {
      final lowStock = Consumable(
        id: 'cons_1',
        name: 'Staples',
        category: ConsumableCategory.stationery,
        unit: ConsumableUnit.boxes,
        quantity: 5,
        minQuantity: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(lowStock.isLowStock, true);

      final normalStock = Consumable(
        id: 'cons_2',
        name: 'Pens',
        category: ConsumableCategory.stationery,
        unit: ConsumableUnit.pieces,
        quantity: 100,
        minQuantity: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(normalStock.isLowStock, false);

      final exactMin = Consumable(
        id: 'cons_3',
        name: 'Paper clips',
        category: ConsumableCategory.stationery,
        unit: ConsumableUnit.packs,
        quantity: 10,
        minQuantity: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(exactMin.isLowStock, true);
    });

    test('should convert to and from Map', () {
      final now = DateTime.now();
      final consumable = Consumable(
        id: 'cons_1',
        name: 'Toner Cartridge',
        category: ConsumableCategory.cartridges,
        unit: ConsumableUnit.pieces,
        quantity: 5,
        minQuantity: 2,
        supplier: 'HP',
        notes: 'Black toner',
        createdAt: now,
        updatedAt: now,
      );

      final map = consumable.toMap();
      expect(map['id'], 'cons_1');
      expect(map['name'], 'Toner Cartridge');
      expect(map['category'], 'cartridges');
      expect(map['unit'], 'pieces');
      expect(map['quantity'], 5);
      expect(map['min_quantity'], 2);

      final restoredConsumable = Consumable.fromMap(map);
      expect(restoredConsumable.id, consumable.id);
      expect(restoredConsumable.name, consumable.name);
      expect(restoredConsumable.category, consumable.category);
      expect(restoredConsumable.quantity, consumable.quantity);
    });

    test('should handle unknown category and unit', () {
      final map = {
        'id': 'cons_1',
        'name': 'Unknown',
        'category': 'unknown_category',
        'unit': 'unknown_unit',
        'quantity': 10,
        'min_quantity': 5,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final consumable = Consumable.fromMap(map);
      expect(consumable.category, ConsumableCategory.other);
      expect(consumable.unit, ConsumableUnit.pieces);
    });

    test('copyWith should create copy with updated fields', () {
      final consumable = Consumable(
        id: 'cons_1',
        name: 'Paper',
        category: ConsumableCategory.paper,
        unit: ConsumableUnit.reams,
        quantity: 50,
        minQuantity: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = consumable.copyWith(
        quantity: 30,
        supplier: 'Office Depot',
      );

      expect(updated.id, consumable.id);
      expect(updated.name, consumable.name);
      expect(updated.quantity, 30);
      expect(updated.supplier, 'Office Depot');
      expect(updated.minQuantity, consumable.minQuantity);
    });
  });

  group('ConsumableCategory', () {
    test('should have correct labels and icons', () {
      expect(ConsumableCategory.stationery.label, 'Канцелярия');
      expect(ConsumableCategory.stationery.icon, Icons.edit);
      expect(ConsumableCategory.stationery.color, Colors.blue);

      expect(ConsumableCategory.cartridges.label, 'Картриджи и чернила');
      expect(ConsumableCategory.cartridges.icon, Icons.print);
      expect(ConsumableCategory.cartridges.color, Colors.black);
    });
  });

  group('ConsumableUnit', () {
    test('should have correct labels', () {
      expect(ConsumableUnit.pieces.shortLabel, 'шт');
      expect(ConsumableUnit.pieces.fullLabel, 'штук');

      expect(ConsumableUnit.kg.shortLabel, 'кг');
      expect(ConsumableUnit.kg.fullLabel, 'килограмм');
    });
  });

  group('ConsumableMovement', () {
    test('should create movement correctly', () {
      final movement = ConsumableMovement(
        consumableId: 'cons_1',
        consumableName: 'Paper',
        quantity: 10,
        operationType: 'расход',
        operationDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(movement.consumableId, 'cons_1');
      expect(movement.quantity, 10);
      expect(movement.isIncoming, false);
      expect(movement.isOutgoing, true);
    });

    test('should detect operation type correctly', () {
      final incoming = ConsumableMovement(
        consumableId: 'cons_1',
        consumableName: 'Paper',
        quantity: 20,
        operationType: 'приход',
        operationDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(incoming.isIncoming, true);
      expect(incoming.isOutgoing, false);
    });

    test('should format operation type correctly', () {
      final incoming = ConsumableMovement(
        consumableId: 'cons_1',
        consumableName: 'Paper',
        quantity: 20,
        operationType: 'приход',
        operationDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(incoming.formattedOperationType, '📥 Приход');

      final outgoing = ConsumableMovement(
        consumableId: 'cons_1',
        consumableName: 'Paper',
        quantity: 5,
        operationType: 'расход',
        operationDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(outgoing.formattedOperationType, '📤 Расход');
    });

    test('should convert to and from Map', () {
      final now = DateTime.now();
      final movement = ConsumableMovement(
        id: 1,
        consumableId: 'cons_1',
        consumableName: 'Paper',
        quantity: 10,
        operationType: 'расход',
        operationDate: now,
        employeeId: 'emp_1',
        employeeName: 'Иванов И.И.',
        documentNumber: 'DOC001',
        notes: 'Test notes',
        createdAt: now,
      );

      final map = movement.toMap();
      expect(map['id'], 1);
      expect(map['consumable_id'], 'cons_1');
      expect(map['quantity'], 10);
      expect(map['operation_type'], 'расход');

      final restoredMovement = ConsumableMovement.fromMap(map);
      expect(restoredMovement.id, movement.id);
      expect(restoredMovement.consumableId, movement.consumableId);
      expect(restoredMovement.quantity, movement.quantity);
    });
  });
}
