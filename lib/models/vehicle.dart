import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum VehicleType {
  car('Легковой', Icons.directions_car, Colors.blue),
  truck('Грузовой', Icons.local_shipping, Colors.orange),
  van('Микроавтобус', Icons.airport_shuttle, Colors.green),
  motorcycle('Мотоцикл', Icons.two_wheeler, Colors.red),
  bus('Автобус', Icons.directions_bus, Colors.purple),
  special('Спецтранспорт', Icons.agriculture, Colors.brown),
  trailer('Прицеп', Icons.local_shipping, Colors.grey);

  final String label;
  final IconData icon;
  final Color color;

  const VehicleType(this.label, this.icon, this.color);

  static VehicleType fromString(String value) {
    return VehicleType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => VehicleType.car,
    );
  }
}

enum VehicleStatus {
  available('Доступен', Colors.green, Icons.check_circle),
  inUse('В использовании', Colors.blue, Icons.person),
  maintenance('На обслуживании', Colors.orange, Icons.build),
  repair('В ремонте', Colors.red, Icons.car_repair),
  reserved('Зарезервирован', Colors.purple, Icons.bookmark),
  writtenOff('Списан', Colors.grey, Icons.delete);

  final String label;
  final Color color;
  final IconData icon;

  const VehicleStatus(this.label, this.color, this.icon);

  static VehicleStatus fromString(String value) {
    return VehicleStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => VehicleStatus.available,
    );
  }
}

enum FuelType {
  petrol('Бензин', Icons.local_gas_station, Colors.red),
  diesel('Дизель', Icons.local_gas_station, Colors.green),
  electric('Электро', Icons.bolt, Colors.yellow),
  hybrid('Гибрид', Icons.eco, Colors.teal),
  gas('Газ', Icons.local_fire_department, Colors.orange);

  final String label;
  final IconData icon;
  final Color color;

  const FuelType(this.label, this.icon, this.color);

  static FuelType fromString(String value) {
    return FuelType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => FuelType.petrol,
    );
  }
}

class Vehicle {
  String id;
  String make;
  String model;
  int year;
  String? vin;
  String licensePlate;
  VehicleType type;
  VehicleStatus status;
  FuelType fuelType;
  String? color;
  double? mileage;
  DateTime? lastService;
  DateTime? nextService;
  String? employeeId;
  String? employeeName;
  String? department;
  String? parkingLocation;
  double? fuelCapacity;
  double? averageConsumption;
  DateTime? insuranceExpiry;
  DateTime? inspectionExpiry;
  List<String>? documents;
  String? notes;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    this.vin,
    required this.licensePlate,
    required this.type,
    this.status = VehicleStatus.available,
    required this.fuelType,
    this.color,
    this.mileage,
    this.lastService,
    this.nextService,
    this.employeeId,
    this.employeeName,
    this.department,
    this.parkingLocation,
    this.fuelCapacity,
    this.averageConsumption,
    this.insuranceExpiry,
    this.inspectionExpiry,
    this.documents,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'vin': vin,
      'license_plate': licensePlate,
      'type': type.name,
      'status': status.name,
      'fuel_type': fuelType.name,
      'color': color,
      'mileage': mileage,
      'last_service': lastService?.toIso8601String(),
      'next_service': nextService?.toIso8601String(),
      'employee_id': employeeId,
      'employee_name': employeeName,
      'department': department,
      'parking_location': parkingLocation,
      'fuel_capacity': fuelCapacity,
      'average_consumption': averageConsumption,
      'insurance_expiry': insuranceExpiry?.toIso8601String(),
      'inspection_expiry': inspectionExpiry?.toIso8601String(),
      'documents': documents?.join(','),
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id']?.toString() ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? DateTime.now().year,
      vin: map['vin'],
      licensePlate: map['license_plate'] ?? '',
      type: VehicleType.fromString(map['type'] ?? 'car'),
      status: VehicleStatus.fromString(map['status'] ?? 'available'),
      fuelType: FuelType.fromString(map['fuel_type'] ?? 'petrol'),
      color: map['color'],
      mileage: map['mileage']?.toDouble(),
      lastService: map['last_service'] != null
          ? DateTime.tryParse(map['last_service'])
          : null,
      nextService: map['next_service'] != null
          ? DateTime.tryParse(map['next_service'])
          : null,
      employeeId: map['employee_id']?.toString(),
      employeeName: map['employee_name'],
      department: map['department'],
      parkingLocation: map['parking_location'],
      fuelCapacity: map['fuel_capacity']?.toDouble(),
      averageConsumption: map['average_consumption']?.toDouble(),
      insuranceExpiry: map['insurance_expiry'] != null
          ? DateTime.tryParse(map['insurance_expiry'])
          : null,
      inspectionExpiry: map['inspection_expiry'] != null
          ? DateTime.tryParse(map['inspection_expiry'])
          : null,
      documents: map['documents']?.toString().split(',').where((s) => s.isNotEmpty).toList(),
      notes: map['notes'],
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Vehicle copyWith({
    String? id,
    String? make,
    String? model,
    int? year,
    String? vin,
    String? licensePlate,
    VehicleType? type,
    VehicleStatus? status,
    FuelType? fuelType,
    String? color,
    double? mileage,
    DateTime? lastService,
    DateTime? nextService,
    String? employeeId,
    String? employeeName,
    String? department,
    String? parkingLocation,
    double? fuelCapacity,
    double? averageConsumption,
    DateTime? insuranceExpiry,
    DateTime? inspectionExpiry,
    List<String>? documents,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      vin: vin ?? this.vin,
      licensePlate: licensePlate ?? this.licensePlate,
      type: type ?? this.type,
      status: status ?? this.status,
      fuelType: fuelType ?? this.fuelType,
      color: color ?? this.color,
      mileage: mileage ?? this.mileage,
      lastService: lastService ?? this.lastService,
      nextService: nextService ?? this.nextService,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      department: department ?? this.department,
      parkingLocation: parkingLocation ?? this.parkingLocation,
      fuelCapacity: fuelCapacity ?? this.fuelCapacity,
      averageConsumption: averageConsumption ?? this.averageConsumption,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      inspectionExpiry: inspectionExpiry ?? this.inspectionExpiry,
      documents: documents ?? this.documents,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName => '$make $model $year';
  String get fullName => '$make $model ($licensePlate)';

  bool get isServiceDue {
    if (nextService == null) return false;
    return DateTime.now().isAfter(nextService!);
  }

  bool get isInsuranceExpired {
    if (insuranceExpiry == null) return false;
    return DateTime.now().isAfter(insuranceExpiry!);
  }

  bool get isInspectionExpired {
    if (inspectionExpiry == null) return false;
    return DateTime.now().isAfter(inspectionExpiry!);
  }

  bool get isExpiringSoon {
    final now = DateTime.now();
    if (insuranceExpiry != null) {
      final daysUntilInsurance = insuranceExpiry!.difference(now).inDays;
      if (daysUntilInsurance <= 30 && daysUntilInsurance > 0) return true;
    }
    if (inspectionExpiry != null) {
      final daysUntilInspection = inspectionExpiry!.difference(now).inDays;
      if (daysUntilInspection <= 30 && daysUntilInspection > 0) return true;
    }
    return false;
  }
}

class VehicleUsageRecord {
  String id;
  String vehicleId;
  String vehicleName;
  String licensePlate;
  String employeeId;
  String employeeName;
  DateTime startTime;
  DateTime? endTime;
  double? startMileage;
  double? endMileage;
  String? purpose;
  String? route;
  double? fuelUsed;
  List<String>? photos;
  String? notes;
  DateTime createdAt;

  VehicleUsageRecord({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.licensePlate,
    required this.employeeId,
    required this.employeeName,
    required this.startTime,
    this.endTime,
    this.startMileage,
    this.endMileage,
    this.purpose,
    this.route,
    this.fuelUsed,
    this.photos,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'vehicle_name': vehicleName,
      'license_plate': licensePlate,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'start_mileage': startMileage,
      'end_mileage': endMileage,
      'purpose': purpose,
      'route': route,
      'fuel_used': fuelUsed,
      'photos': photos?.join(','),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory VehicleUsageRecord.fromMap(Map<String, dynamic> map) {
    return VehicleUsageRecord(
      id: map['id']?.toString() ?? '',
      vehicleId: map['vehicle_id']?.toString() ?? '',
      vehicleName: map['vehicle_name'] ?? '',
      licensePlate: map['license_plate'] ?? '',
      employeeId: map['employee_id']?.toString() ?? '',
      employeeName: map['employee_name'] ?? '',
      startTime: DateTime.tryParse(map['start_time'] ?? '') ?? DateTime.now(),
      endTime: map['end_time'] != null
          ? DateTime.tryParse(map['end_time'])
          : null,
      startMileage: map['start_mileage']?.toDouble(),
      endMileage: map['end_mileage']?.toDouble(),
      purpose: map['purpose'],
      route: map['route'],
      fuelUsed: map['fuel_used']?.toDouble(),
      photos: map['photos']?.toString().split(',').where((s) => s.isNotEmpty).toList(),
      notes: map['notes'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isActive => endTime == null;

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  double? get distanceDriven {
    if (startMileage == null || endMileage == null) return null;
    return endMileage! - startMileage!;
  }

  String get formattedStartTime {
    return DateFormat('dd.MM.yyyy HH:mm').format(startTime);
  }

  String get formattedEndTime {
    return endTime != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(endTime!)
        : 'В поездке';
  }

  String get formattedDuration {
    final dur = duration;
    if (dur == null) return 'В поездке';
    final hours = dur.inHours;
    final minutes = dur.inMinutes % 60;
    return '${hours}ч ${minutes}мин';
  }
}

class VehicleExpense {
  String id;
  String vehicleId;
  String vehicleName;
  DateTime date;
  String category;
  double amount;
  String? description;
  String? documentNumber;
  List<String>? attachments;
  DateTime createdAt;

  VehicleExpense({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.date,
    required this.category,
    required this.amount,
    this.description,
    this.documentNumber,
    this.attachments,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'vehicle_name': vehicleName,
      'date': date.toIso8601String(),
      'category': category,
      'amount': amount,
      'description': description,
      'document_number': documentNumber,
      'attachments': attachments?.join(','),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory VehicleExpense.fromMap(Map<String, dynamic> map) {
    return VehicleExpense(
      id: map['id']?.toString() ?? '',
      vehicleId: map['vehicle_id']?.toString() ?? '',
      vehicleName: map['vehicle_name'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      category: map['category'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      description: map['description'],
      documentNumber: map['document_number'],
      attachments: map['attachments']?.toString().split(',').where((s) => s.isNotEmpty).toList(),
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get formattedDate {
    return DateFormat('dd.MM.yyyy').format(date);
  }
}
