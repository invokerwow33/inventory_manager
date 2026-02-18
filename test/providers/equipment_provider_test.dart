import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_manager/models/equipment.dart';
import 'package:inventory_manager/providers/equipment_provider.dart';

void main() {
  group('EquipmentProvider', () {
    late EquipmentProvider provider;

    setUp(() {
      provider = EquipmentProvider();
    });

    test('should have empty equipment list initially', () {
      expect(provider.equipment, isEmpty);
      expect(provider.allEquipment, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });

    test('should calculate statistics correctly', () {
      // Initially all zeros
      expect(provider.statistics['total'], 0);
      expect(provider.statistics['inUse'], 0);
      expect(provider.statistics['inStock'], 0);
    });

    test('should clear filters', () {
      provider.clearFilters();
      expect(provider.equipment, isEmpty);
    });

    test('should clear selection', () {
      provider.clearSelection();
      expect(provider.selectedEquipment, isNull);
    });

    test('should clear error', () {
      provider.clearError();
      expect(provider.error, isNull);
    });
  });

  group('EquipmentProvider Search', () {
    late EquipmentProvider provider;

    setUp(() {
      provider = EquipmentProvider();
    });

    test('should search with empty query clear filters', () {
      provider.search('');
      expect(provider.equipment, isEmpty);
    });
  });
}
