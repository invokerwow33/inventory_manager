import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/logger_service.dart';

class Equipment {
  String id;
  String name;
  EquipmentType type;
  String? serialNumber;
  String? inventoryNumber;
  String? manufacturer;
  String? model;
  DateTime? purchaseDate;
  double? purchasePrice;
  String? department;
  String? responsiblePerson;
  String? location;  
  EquipmentStatus status;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;

  Equipment({
    required this.id,
    required this.name,
    required this.type,
    this.serialNumber,
    this.inventoryNumber,
    this.manufacturer,
    this.model,
    this.purchaseDate,
    this.purchasePrice,
    this.department,
    this.responsiblePerson,
    this.location,
    this.status = EquipmentStatus.inUse,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'serial_number': serialNumber,
      'inventory_number': inventoryNumber,
      'manufacturer': manufacturer,
      'model': model,
      'purchase_date': purchaseDate?.toIso8601String(),
      'purchase_price': purchasePrice,
      'department': department,
      'responsible_person': responsiblePerson,
      'location': location,
      'status': status.toString().split('.').last,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id: map['id'],
      name: map['name'],
      type: EquipmentType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () {
          LoggerService().warning('Unknown equipment type: ${map['type']}, defaulting to computer');
          return EquipmentType.computer;
        },
      ),
      serialNumber: map['serialNumber'] ?? map['serial_number'],
      inventoryNumber: map['inventoryNumber'] ?? map['inventory_number'],
      manufacturer: map['manufacturer'],
      model: map['model'],
      purchaseDate: map['purchaseDate'] != null || map['purchase_date'] != null
          ? DateTime.tryParse(map['purchaseDate'] ?? map['purchase_date'] ?? '')
          : null,
      purchasePrice: map['purchasePrice'] ?? map['purchase_price'],
      department: map['department'],
      responsiblePerson: map['responsiblePerson'] ?? map['responsible_person'],
      location: map['location'],
      status: EquipmentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () {
          LoggerService().warning('Unknown equipment status: ${map['status']}, defaulting to inUse');
          return EquipmentStatus.inUse;
        },
      ),
      notes: map['notes'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get formattedPurchaseDate {
    return purchaseDate != null
        ? DateFormat('dd.MM.yyyy').format(purchaseDate!)
        : 'Не указано';
  }

  String get formattedPrice {
    return purchasePrice != null
        ? '${purchasePrice!.toStringAsFixed(2)} ₽'
        : 'Не указано';
  }
}

enum EquipmentType {
  computer('Компьютер', Icons.computer),
  laptop('Ноутбук', Icons.laptop),
  monitor('Монитор', Icons.monitor),
  printer('Принтер', Icons.print),
  scanner('Сканер', Icons.scanner),
  server('Сервер', Icons.storage),
  network('Сетевое оборудование', Icons.lan),
  peripheral('Периферия', Icons.keyboard),
  other('Другое', Icons.devices_other);

  final String label;
  final IconData icon;

  const EquipmentType(this.label, this.icon);
}

enum EquipmentStatus {
  inUse('В использовании', Colors.green),
  inStock('На складе', Colors.blue),
  underRepair('В ремонте', Colors.orange),
  writtenOff('Списано', Colors.red),
  reserved('Зарезервировано', Colors.purple);

  final String label;
  final Color color;

  const EquipmentStatus(this.label, this.color);
}