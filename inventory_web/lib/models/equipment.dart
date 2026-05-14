import 'package:flutter/material.dart';

enum EquipmentStatus { available, inUse, maintenance, retired }

class Equipment {
  final String id;
  final String name;
  final String serialNumber;
  final String? category;
  final String? locationId;
  final String? assignedToEmployeeId;
  final EquipmentStatus status;
  final DateTime purchaseDate;
  final double? price;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Equipment({
    required this.id,
    required this.name,
    required this.serialNumber,
    this.category,
    this.locationId,
    this.assignedToEmployeeId,
    required this.status,
    required this.purchaseDate,
    this.price,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'serialNumber': serialNumber,
      'category': category,
      'locationId': locationId,
      'assignedToEmployeeId': assignedToEmployeeId,
      'status': status.name,
      'purchaseDate': purchaseDate.toIso8601String(),
      'price': price,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      category: map['category'],
      locationId: map['locationId'],
      assignedToEmployeeId: map['assignedToEmployeeId'],
      status: EquipmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => EquipmentStatus.available,
      ),
      purchaseDate: DateTime.parse(map['purchaseDate']),
      price: map['price']?.toDouble(),
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Equipment copyWith({
    String? id,
    String? name,
    String? serialNumber,
    String? category,
    String? locationId,
    String? assignedToEmployeeId,
    EquipmentStatus? status,
    DateTime? purchaseDate,
    double? price,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      serialNumber: serialNumber ?? this.serialNumber,
      category: category ?? this.category,
      locationId: locationId ?? this.locationId,
      assignedToEmployeeId: assignedToEmployeeId ?? this.assignedToEmployeeId,
      status: status ?? this.status,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      price: price ?? this.price,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAvailable => status == EquipmentStatus.available;
  
  IconData get statusIcon {
    switch (status) {
      case EquipmentStatus.available:
        return Icons.check_circle_outline;
      case EquipmentStatus.inUse:
        return Icons.person_outline;
      case EquipmentStatus.maintenance:
        return Icons.build_outlined;
      case EquipmentStatus.retired:
        return Icons.cancel_outlined;
    }
  }

  Color get statusColor {
    switch (status) {
      case EquipmentStatus.available:
        return Colors.green;
      case EquipmentStatus.inUse:
        return Colors.blue;
      case EquipmentStatus.maintenance:
        return Colors.orange;
      case EquipmentStatus.retired:
        return Colors.red;
    }
  }
}
