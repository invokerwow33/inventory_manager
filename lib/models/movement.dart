import 'package:intl/intl.dart';

class EquipmentMovement {
  int? id;
  int equipmentId;
  String equipmentName;
  String fromLocation;
  String toLocation;
  String? fromResponsible;
  String? toResponsible;
  DateTime movementDate;
  String movementType; // "Перемещение", "Выдача", "Возврат", "Списание"
  String? documentNumber; // Номер акта/накладной
  String? notes;
  DateTime createdAt;

  EquipmentMovement({
    this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.fromLocation,
    required this.toLocation,
    this.fromResponsible,
    this.toResponsible,
    required this.movementDate,
    required this.movementType,
    this.documentNumber,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'equipment_id': equipmentId,
      'equipment_name': equipmentName,
      'from_location': fromLocation,
      'to_location': toLocation,
      'from_responsible': fromResponsible,
      'to_responsible': toResponsible,
      'movement_date': movementDate.toIso8601String(),
      'movement_type': movementType,
      'document_number': documentNumber,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EquipmentMovement.fromMap(Map<String, dynamic> map) {
    return EquipmentMovement(
      id: map['id'],
      equipmentId: map['equipment_id'],
      equipmentName: map['equipment_name'] ?? '',
      fromLocation: map['from_location'] ?? '',
      toLocation: map['to_location'] ?? '',
      fromResponsible: map['from_responsible'],
      toResponsible: map['to_responsible'],
      movementDate: DateTime.parse(map['movement_date']),
      movementType: map['movement_type'] ?? 'Перемещение',
      documentNumber: map['document_number'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  String get formattedDate {
    return DateFormat('dd.MM.yyyy HH:mm').format(movementDate);
  }

  String get formattedMovementType {
    switch (movementType) {
      case 'Перемещение':
        return '📦 Перемещение';
      case 'Выдача':
        return '📤 Выдача';
      case 'Возврат':
        return '📥 Возврат';
      case 'Списание':
        return '🗑️ Списание';
      default:
        return movementType;
    }
  }
}