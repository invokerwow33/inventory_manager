import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum KeyType {
  room('Ключ от помещения', Icons.door_front_door, Colors.brown),
  cabinet('Ключ от шкафа', Icons.storage, Colors.orange),
  safe('Ключ от сейфа', Icons.lock, Colors.red),
  car('Ключ от автомобиля', Icons.car_rental, Colors.blue),
  entrance('Пропуск', Icons.badge, Colors.green),
  electronic('Электронный ключ', Icons.nfc, Colors.purple),
  master('Мастер-ключ', Icons.vpn_key, Colors.deepOrange),
  other('Другой', Icons.key, Colors.grey);

  final String label;
  final IconData icon;
  final Color color;

  const KeyType(this.label, this.icon, this.color);

  static KeyType fromString(String value) {
    return KeyType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => KeyType.other,
    );
  }
}

enum KeyStatus {
  available('Доступен', Colors.green, Icons.check_circle),
  issued('Выдан', Colors.orange, Icons.person),
  lost('Утрачен', Colors.red, Icons.error),
  damaged('Поврежден', Colors.grey, Icons.broken_image),
  retired('Списан', Colors.black, Icons.delete);

  final String label;
  final Color color;
  final IconData icon;

  const KeyStatus(this.label, this.color, this.icon);

  static KeyStatus fromString(String value) {
    return KeyStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => KeyStatus.available,
    );
  }
}

class KeyItem {
  String id;
  String name;
  String keyNumber;
  KeyType type;
  KeyStatus status;
  String? roomId;
  String? roomName;
  String? description;
  String? accessLevel;
  int? copiesCount;
  List<String>? restrictions;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  KeyItem({
    required this.id,
    required this.name,
    required this.keyNumber,
    required this.type,
    this.status = KeyStatus.available,
    this.roomId,
    this.roomName,
    this.description,
    this.accessLevel,
    this.copiesCount,
    this.restrictions,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'key_number': keyNumber,
      'type': type.name,
      'status': status.name,
      'room_id': roomId,
      'room_name': roomName,
      'description': description,
      'access_level': accessLevel,
      'copies_count': copiesCount,
      'restrictions': restrictions?.join(','),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory KeyItem.fromMap(Map<String, dynamic> map) {
    return KeyItem(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      keyNumber: map['key_number'] ?? '',
      type: KeyType.fromString(map['type'] ?? 'other'),
      status: KeyStatus.fromString(map['status'] ?? 'available'),
      roomId: map['room_id']?.toString(),
      roomName: map['room_name'],
      description: map['description'],
      accessLevel: map['access_level'],
      copiesCount: map['copies_count'],
      restrictions: map['restrictions']?.toString().split(',').where((s) => s.isNotEmpty).toList(),
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  KeyItem copyWith({
    String? id,
    String? name,
    String? keyNumber,
    KeyType? type,
    KeyStatus? status,
    String? roomId,
    String? roomName,
    String? description,
    String? accessLevel,
    int? copiesCount,
    List<String>? restrictions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KeyItem(
      id: id ?? this.id,
      name: name ?? this.name,
      keyNumber: keyNumber ?? this.keyNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      description: description ?? this.description,
      accessLevel: accessLevel ?? this.accessLevel,
      copiesCount: copiesCount ?? this.copiesCount,
      restrictions: restrictions ?? this.restrictions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class KeyIssueRecord {
  String id;
  String keyId;
  String keyName;
  String keyNumber;
  String employeeId;
  String employeeName;
  DateTime issuedAt;
  DateTime? returnedAt;
  String? issuedBy;
  String? receivedBy;
  String? documentNumber;
  String? purpose;
  String? notes;
  DateTime createdAt;

  KeyIssueRecord({
    required this.id,
    required this.keyId,
    required this.keyName,
    required this.keyNumber,
    required this.employeeId,
    required this.employeeName,
    required this.issuedAt,
    this.returnedAt,
    this.issuedBy,
    this.receivedBy,
    this.documentNumber,
    this.purpose,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'key_id': keyId,
      'key_name': keyName,
      'key_number': keyNumber,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'issued_at': issuedAt.toIso8601String(),
      'returned_at': returnedAt?.toIso8601String(),
      'issued_by': issuedBy,
      'received_by': receivedBy,
      'document_number': documentNumber,
      'purpose': purpose,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory KeyIssueRecord.fromMap(Map<String, dynamic> map) {
    return KeyIssueRecord(
      id: map['id']?.toString() ?? '',
      keyId: map['key_id']?.toString() ?? '',
      keyName: map['key_name'] ?? '',
      keyNumber: map['key_number'] ?? '',
      employeeId: map['employee_id']?.toString() ?? '',
      employeeName: map['employee_name'] ?? '',
      issuedAt: DateTime.tryParse(map['issued_at'] ?? '') ?? DateTime.now(),
      returnedAt: map['returned_at'] != null
          ? DateTime.tryParse(map['returned_at'])
          : null,
      issuedBy: map['issued_by'],
      receivedBy: map['received_by'],
      documentNumber: map['document_number'],
      purpose: map['purpose'],
      notes: map['notes'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isActive => returnedAt == null;

  String get formattedIssuedDate {
    return DateFormat('dd.MM.yyyy HH:mm').format(issuedAt);
  }

  String get formattedReturnedDate {
    return returnedAt != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(returnedAt!)
        : 'Не возвращен';
  }

  int? get daysSinceIssued {
    return DateTime.now().difference(issuedAt).inDays;
  }

  int? get daysUntilDue(DateTime dueDate) {
    return dueDate.difference(DateTime.now()).inDays;
  }
}
