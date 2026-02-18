import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Employee {
  String id;
  String fullName;
  String? department;
  String? position;
  String? email;
  String? phone;
  String? employeeNumber;
  String? notes;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  Employee({
    required this.id,
    required this.fullName,
    this.department,
    this.position,
    this.email,
    this.phone,
    this.employeeNumber,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'department': department,
      'position': position,
      'email': email,
      'phone': phone,
      'employee_number': employeeNumber,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name'] ?? map['name'] ?? '',
      department: map['department'],
      position: map['position'],
      email: map['email'],
      phone: map['phone'],
      employeeNumber: map['employee_number'] ?? map['employeeNumber'],
      notes: map['notes'],
      isActive: map['is_active'] ?? map['isActive'] ?? true,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '??';
  }

  String get displayName => fullName;

  String get displayInfo {
    final parts = <String>[];
    if (position != null && position!.isNotEmpty) parts.add(position!);
    if (department != null && department!.isNotEmpty) parts.add(department!);
    return parts.join(' • ');
  }

  Employee copyWith({
    String? id,
    String? fullName,
    String? department,
    String? position,
    String? email,
    String? phone,
    String? employeeNumber,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      department: department ?? this.department,
      position: position ?? this.position,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class EmployeeEquipment {
  final String equipmentId;
  final String equipmentName;
  final String? inventoryNumber;
  final DateTime issuedAt;
  final DateTime? returnedAt;
  final String? documentNumber;

  EmployeeEquipment({
    required this.equipmentId,
    required this.equipmentName,
    this.inventoryNumber,
    required this.issuedAt,
    this.returnedAt,
    this.documentNumber,
  });

  bool get isActive => returnedAt == null;
}

class EmployeeMovementSummary {
  final String movementType;
  final String equipmentName;
  final String? inventoryNumber;
  final DateTime date;
  final String? documentNumber;
  final String? fromLocation;
  final String? toLocation;

  EmployeeMovementSummary({
    required this.movementType,
    required this.equipmentName,
    this.inventoryNumber,
    required this.date,
    this.documentNumber,
    this.fromLocation,
    this.toLocation,
  });

  String get formattedDate {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String get formattedDateTime {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  IconData get icon {
    switch (movementType) {
      case 'Выдача':
        return Icons.arrow_forward;
      case 'Возврат':
        return Icons.arrow_back;
      case 'Перемещение':
        return Icons.swap_horiz;
      case 'Списание':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  Color get color {
    switch (movementType) {
      case 'Выдача':
        return Colors.green;
      case 'Возврат':
        return Colors.blue;
      case 'Перемещение':
        return Colors.orange;
      case 'Списание':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
