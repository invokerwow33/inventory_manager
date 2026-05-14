import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Consumable {
  String id;
  String name;
  ConsumableCategory category;
  ConsumableUnit unit;
  double quantity;
  double minQuantity;
  String? supplier;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;

  Consumable({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.quantity,
    required this.minQuantity,
    this.supplier,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => quantity <= minQuantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.toString().split('.').last,
      'unit': unit.toString().split('.').last,
      'quantity': quantity,
      'min_quantity': minQuantity,
      'supplier': supplier,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Consumable.fromMap(Map<String, dynamic> map) {
    return Consumable(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      category: ConsumableCategory.values.firstWhere(
        (e) => e.toString().split('.').last == map['category'],
        orElse: () => ConsumableCategory.other,
      ),
      unit: ConsumableUnit.values.firstWhere(
        (e) => e.toString().split('.').last == map['unit'],
        orElse: () => ConsumableUnit.pieces,
      ),
      quantity: (map['quantity'] ?? 0).toDouble(),
      minQuantity: (map['min_quantity'] ?? 0).toDouble(),
      supplier: map['supplier'],
      notes: map['notes'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Consumable copyWith({
    String? id,
    String? name,
    ConsumableCategory? category,
    ConsumableUnit? unit,
    double? quantity,
    double? minQuantity,
    String? supplier,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Consumable(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      supplier: supplier ?? this.supplier,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum ConsumableCategory {
  stationery('Канцелярия', Icons.edit, Colors.blue),
  cartridges('Картриджи и чернила', Icons.print, Colors.black87),
  paper('Бумага', Icons.description, Colors.lightBlueAccent),
  office('Офисные принадлежности', Icons.work, Colors.orange),
  cleaning('Хозяйственные товары', Icons.cleaning_services, Colors.green),
  it('IT-расходники', Icons.computer, Colors.purple),
  furniture('Мебельные комплектующие', Icons.chair, Colors.brown),
  other('Другое', Icons.inventory_2, Colors.grey);

  final String label;
  final IconData icon;
  final Color color;

  const ConsumableCategory(this.label, this.icon, this.color);
}

enum ConsumableUnit {
  pieces('шт', 'штук'),
  kg('кг', 'килограмм'),
  meters('м', 'метров'),
  liters('л', 'литров'),
  packs('упак', 'упаковок'),
  boxes('кор', 'коробок'),
  reams('пач', 'пачек'),
  rolls('рул', 'рулонов');

  final String shortLabel;
  final String fullLabel;

  const ConsumableUnit(this.shortLabel, this.fullLabel);
}

class ConsumableMovement {
  int? id;
  String consumableId;
  String consumableName;
  double quantity;
  String operationType; // "приход" или "расход"
  DateTime operationDate;
  String? employeeId;
  String? employeeName;
  String? documentNumber;
  String? notes;
  DateTime createdAt;

  ConsumableMovement({
    this.id,
    required this.consumableId,
    required this.consumableName,
    required this.quantity,
    required this.operationType,
    required this.operationDate,
    this.employeeId,
    this.employeeName,
    this.documentNumber,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'consumable_id': consumableId,
      'consumable_name': consumableName,
      'quantity': quantity,
      'operation_type': operationType,
      'operation_date': operationDate.toIso8601String(),
      'employee_id': employeeId,
      'employee_name': employeeName,
      'document_number': documentNumber,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ConsumableMovement.fromMap(Map<String, dynamic> map) {
    return ConsumableMovement(
      id: map['id'],
      consumableId: map['consumable_id']?.toString() ?? '',
      consumableName: map['consumable_name'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      operationType: map['operation_type'] ?? 'расход',
      operationDate: DateTime.tryParse(map['operation_date'] ?? '') ?? DateTime.now(),
      employeeId: map['employee_id']?.toString(),
      employeeName: map['employee_name'],
      documentNumber: map['document_number'],
      notes: map['notes'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get formattedDate {
    return DateFormat('dd.MM.yyyy HH:mm').format(operationDate);
  }

  String get formattedOperationType {
    switch (operationType) {
      case 'приход':
        return '📥 Приход';
      case 'расход':
        return '📤 Расход';
      default:
        return operationType;
    }
  }

  bool get isIncoming => operationType == 'приход';
  bool get isOutgoing => operationType == 'расход';
}
