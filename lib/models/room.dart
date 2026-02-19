import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum RoomType {
  office('Офис', Icons.business, Colors.blue),
  warehouse('Склад', Icons.warehouse, Colors.orange),
  server('Серверная', Icons.storage, Colors.purple),
  meeting('Переговорная', Icons.meeting_room, Colors.green),
  laboratory('Лаборатория', Icons.science, Colors.teal),
  production('Производство', Icons.precision_manufacturing, Colors.red),
  archive('Архив', Icons.folder, Colors.brown),
  other('Другое', Icons.room_preferences, Colors.grey);

  final String label;
  final IconData icon;
  final Color color;

  const RoomType(this.label, this.icon, this.color);

  static RoomType fromString(String value) {
    return RoomType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RoomType.other,
    );
  }
}

class Room {
  String id;
  String name;
  String? number;
  RoomType type;
  String? floor;
  String? building;
  String? description;
  String? floorPlanUrl;
  double? area;
  int? capacity;
  String? responsiblePerson;
  List<String>? equipmentIds;
  String? parentRoomId;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  Room({
    required this.id,
    required this.name,
    this.number,
    required this.type,
    this.floor,
    this.building,
    this.description,
    this.floorPlanUrl,
    this.area,
    this.capacity,
    this.responsiblePerson,
    this.equipmentIds,
    this.parentRoomId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'type': type.name,
      'floor': floor,
      'building': building,
      'description': description,
      'floor_plan_url': floorPlanUrl,
      'area': area,
      'capacity': capacity,
      'responsible_person': responsiblePerson,
      'equipment_ids': equipmentIds?.join(','),
      'parent_room_id': parentRoomId,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      number: map['number'],
      type: RoomType.fromString(map['type'] ?? 'other'),
      floor: map['floor'],
      building: map['building'],
      description: map['description'],
      floorPlanUrl: map['floor_plan_url'],
      area: map['area']?.toDouble(),
      capacity: map['capacity'],
      responsiblePerson: map['responsible_person'],
      equipmentIds: map['equipment_ids']?.toString().split(',').where((s) => s.isNotEmpty).toList(),
      parentRoomId: map['parent_room_id']?.toString(),
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Room copyWith({
    String? id,
    String? name,
    String? number,
    RoomType? type,
    String? floor,
    String? building,
    String? description,
    String? floorPlanUrl,
    double? area,
    int? capacity,
    String? responsiblePerson,
    List<String>? equipmentIds,
    String? parentRoomId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      type: type ?? this.type,
      floor: floor ?? this.floor,
      building: building ?? this.building,
      description: description ?? this.description,
      floorPlanUrl: floorPlanUrl ?? this.floorPlanUrl,
      area: area ?? this.area,
      capacity: capacity ?? this.capacity,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      equipmentIds: equipmentIds ?? this.equipmentIds,
      parentRoomId: parentRoomId ?? this.parentRoomId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName {
    if (number != null && number!.isNotEmpty) {
      return '$name ($number)';
    }
    return name;
  }
}

class RoomEquipment {
  String id;
  String roomId;
  String equipmentId;
  String equipmentName;
  String? inventoryNumber;
  DateTime placedAt;
  DateTime? removedAt;
  String? notes;
  DateTime createdAt;

  RoomEquipment({
    required this.id,
    required this.roomId,
    required this.equipmentId,
    required this.equipmentName,
    this.inventoryNumber,
    required this.placedAt,
    this.removedAt,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_id': roomId,
      'equipment_id': equipmentId,
      'equipment_name': equipmentName,
      'inventory_number': inventoryNumber,
      'placed_at': placedAt.toIso8601String(),
      'removed_at': removedAt?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RoomEquipment.fromMap(Map<String, dynamic> map) {
    return RoomEquipment(
      id: map['id']?.toString() ?? '',
      roomId: map['room_id']?.toString() ?? '',
      equipmentId: map['equipment_id']?.toString() ?? '',
      equipmentName: map['equipment_name'] ?? '',
      inventoryNumber: map['inventory_number'],
      placedAt: DateTime.tryParse(map['placed_at'] ?? '') ?? DateTime.now(),
      removedAt: map['removed_at'] != null
          ? DateTime.tryParse(map['removed_at'])
          : null,
      notes: map['notes'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isCurrent => removedAt == null;

  String get formattedPlacedDate {
    return DateFormat('dd.MM.yyyy').format(placedAt);
  }

  String get formattedRemovedDate {
    return removedAt != null
        ? DateFormat('dd.MM.yyyy').format(removedAt!)
        : 'Текущее';
  }
}

class InventoryAudit {
  String id;
  String roomId;
  String roomName;
  DateTime auditDate;
  String conductedBy;
  String status;
  List<String>? expectedEquipmentIds;
  List<String>? foundEquipmentIds;
  List<String>? missingEquipmentIds;
  List<String>? unexpectedEquipmentIds;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;

  InventoryAudit({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.auditDate,
    required this.conductedBy,
    this.status = 'in_progress',
    this.expectedEquipmentIds,
    this.foundEquipmentIds,
    this.missingEquipmentIds,
    this.unexpectedEquipmentIds,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_id': roomId,
      'room_name': roomName,
      'audit_date': auditDate.toIso8601String(),
      'conducted_by': conductedBy,
      'status': status,
      'expected_equipment_ids': expectedEquipmentIds?.join(','),
      'found_equipment_ids': foundEquipmentIds?.join(','),
      'missing_equipment_ids': missingEquipmentIds?.join(','),
      'unexpected_equipment_ids': unexpectedEquipmentIds?.join(','),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InventoryAudit.fromMap(Map<String, dynamic> map) {
    return InventoryAudit(
      id: map['id']?.toString() ?? '',
      roomId: map['room_id']?.toString() ?? '',
      roomName: map['room_name'] ?? '',
      auditDate: DateTime.tryParse(map['audit_date'] ?? '') ?? DateTime.now(),
      conductedBy: map['conducted_by'] ?? '',
      status: map['status'] ?? 'in_progress',
      expectedEquipmentIds: map['expected_equipment_ids']?.toString().split(',').where((s) => s.isNotEmpty).toList(),
      foundEquipmentIds: map['found_equipment_ids']?.toString().split(',').where((s) => s.isNotEmpty).toList(),
      missingEquipmentIds: map['missing_equipment_ids']?.toString().split(',').where((s) => s.isNotEmpty).toList(),
      unexpectedEquipmentIds: map['unexpected_equipment_ids']?.toString().split(',').where((s) => s.isNotEmpty).toList(),
      notes: map['notes'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get formattedAuditDate {
    return DateFormat('dd.MM.yyyy HH:mm').format(auditDate);
  }

  int get foundCount => foundEquipmentIds?.length ?? 0;
  int get expectedCount => expectedEquipmentIds?.length ?? 0;
  int get missingCount => missingEquipmentIds?.length ?? 0;
  int get unexpectedCount => unexpectedEquipmentIds?.length ?? 0;

  double get accuracyPercent {
    if (expectedCount == 0) return 0;
    return (foundCount / expectedCount) * 100;
  }
}
