import 'package:flutter/material.dart';

/// Кинозал
class CinemaHall {
  String id;
  String name;
  String? description;
  int totalSeats;
  double? screenWidth;
  double? screenHeight;
  String? projectorType;
  String? soundSystem;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  CinemaHall({
    required this.id,
    required this.name,
    this.description,
    this.totalSeats = 0,
    this.screenWidth,
    this.screenHeight,
    this.projectorType,
    this.soundSystem,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'total_seats': totalSeats,
      'screen_width': screenWidth,
      'screen_height': screenHeight,
      'projector_type': projectorType,
      'sound_system': soundSystem,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CinemaHall.fromMap(Map<String, dynamic> map) {
    return CinemaHall(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      totalSeats: map['total_seats'] ?? 0,
      screenWidth: map['screen_width'] != null ? (map['screen_width'] as num).toDouble() : null,
      screenHeight: map['screen_height'] != null ? (map['screen_height'] as num).toDouble() : null,
      projectorType: map['projector_type'],
      soundSystem: map['sound_system'],
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  CinemaHall copyWith({
    String? id,
    String? name,
    String? description,
    int? totalSeats,
    double? screenWidth,
    double? screenHeight,
    String? projectorType,
    String? soundSystem,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CinemaHall(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      totalSeats: totalSeats ?? this.totalSeats,
      screenWidth: screenWidth ?? this.screenWidth,
      screenHeight: screenHeight ?? this.screenHeight,
      projectorType: projectorType ?? this.projectorType,
      soundSystem: soundSystem ?? this.soundSystem,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Тип места
enum SeatType {
  standard('Стандарт', Colors.blue, 1.0),
  vip('VIP', Colors.purple, 1.5),
  premium('Премиум', Colors.amber, 2.0);

  final String label;
  final Color color;
  final double priceModifier;

  const SeatType(this.label, this.color, this.priceModifier);

  static SeatType fromString(String value) {
    return SeatType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SeatType.standard,
    );
  }
}

/// Место в кинозале
class Seat {
  String id;
  String hallId;
  int row;
  int seatNumber;
  SeatType seatType;
  double priceModifier;
  bool isAccessible;
  String status; // available, occupied, broken
  DateTime createdAt;
  DateTime updatedAt;

  Seat({
    required this.id,
    required this.hallId,
    required this.row,
    required this.seatNumber,
    this.seatType = SeatType.standard,
    this.priceModifier = 1.0,
    this.isAccessible = false,
    this.status = 'available',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hall_id': hallId,
      'row': row,
      'seat_number': seatNumber,
      'seat_type': seatType.name,
      'price_modifier': priceModifier,
      'is_accessible': isAccessible ? 1 : 0,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Seat.fromMap(Map<String, dynamic> map) {
    return Seat(
      id: map['id']?.toString() ?? '',
      hallId: map['hall_id']?.toString() ?? '',
      row: map['row'] ?? 0,
      seatNumber: map['seat_number'] ?? 0,
      seatType: SeatType.fromString(map['seat_type'] ?? 'standard'),
      priceModifier: map['price_modifier'] ?? 1.0,
      isAccessible: map['is_accessible'] == 1 || map['is_accessible'] == true,
      status: map['status'] ?? 'available',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Seat copyWith({
    String? id,
    String? hallId,
    int? row,
    int? seatNumber,
    SeatType? seatType,
    double? priceModifier,
    bool? isAccessible,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Seat(
      id: id ?? this.id,
      hallId: hallId ?? this.hallId,
      row: row ?? this.row,
      seatNumber: seatNumber ?? this.seatNumber,
      seatType: seatType ?? this.seatType,
      priceModifier: priceModifier ?? this.priceModifier,
      isAccessible: isAccessible ?? this.isAccessible,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get label => 'Ряд $row, Место $seatNumber';
}
