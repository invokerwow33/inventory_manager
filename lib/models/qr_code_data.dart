import 'dart:convert';

import 'package:inventory_manager/models/equipment.dart';

class QRCodeData {
  final String equipmentId;
  final String name;
  final String? serialNumber;
  final String? inventoryNumber;
  final DateTime createdAt;

  QRCodeData({
    required this.equipmentId,
    required this.name,
    this.serialNumber,
    this.inventoryNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'equipmentId': equipmentId,
      'name': name,
      'serialNumber': serialNumber,
      'inventoryNumber': inventoryNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory QRCodeData.fromJson(Map<String, dynamic> json) {
    return QRCodeData(
      equipmentId: json['equipmentId'],
      name: json['name'],
      serialNumber: json['serialNumber'],
      inventoryNumber: json['inventoryNumber'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String toEncodedString() {
    return base64Encode(utf8.encode(jsonEncode(toJson())));
  }

  static QRCodeData? fromEncodedString(String encoded) {
    try {
      final decoded = utf8.decode(base64Decode(encoded));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      return QRCodeData.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  static QRCodeData fromEquipment(Equipment equipment) {
    return QRCodeData(
      equipmentId: equipment.id,
      name: equipment.name,
      serialNumber: equipment.serialNumber,
      inventoryNumber: equipment.inventoryNumber,
      createdAt: DateTime.now(),
    );
  }
}