import 'package:flutter/material.dart';

class Consumable {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final int minQuantity;
  final String? unit;
  final String? locationId;
  final double? pricePerUnit;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Consumable({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.minQuantity,
    this.unit,
    this.locationId,
    this.pricePerUnit,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'unit': unit,
      'locationId': locationId,
      'pricePerUnit': pricePerUnit,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Consumable.fromMap(Map<String, dynamic> map) {
    return Consumable(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      quantity: map['quantity'] ?? 0,
      minQuantity: map['minQuantity'] ?? 0,
      unit: map['unit'],
      locationId: map['locationId'],
      pricePerUnit: map['pricePerUnit']?.toDouble(),
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Consumable copyWith({
    String? id,
    String? name,
    String? category,
    int? quantity,
    int? minQuantity,
    String? unit,
    String? locationId,
    double? pricePerUnit,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Consumable(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      unit: unit ?? this.unit,
      locationId: locationId ?? this.locationId,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isLowStock => quantity <= minQuantity;

  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'бумага':
        return Icons.description;
      case 'картриджи':
        return Icons.print;
      case 'ручки':
        return Icons.edit;
      case 'папки':
        return Icons.folder;
      case 'прочее':
      default:
        return Icons.inventory_2_outlined;
    }
  }

  Color get categoryColor {
    switch (category.toLowerCase()) {
      case 'бумага':
        return Colors.lightBlueAccent;
      case 'картриджи':
        return Colors.black87;
      case 'ручки':
        return Colors.green;
      case 'папки':
        return Colors.orange;
      case 'прочее':
      default:
        return Colors.grey;
    }
  }
}
