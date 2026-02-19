import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum PhoneType {
  mobile('Мобильный', Icons.smartphone, Colors.blue),
  landline('Стационарный', Icons.phone, Colors.green),
  ip('IP-телефон', Icons.router, Colors.purple),
  softphone('Софтфон', Icons.computer, Colors.orange),
  fax('Факс', Icons.print, Colors.grey);

  final String label;
  final IconData icon;
  final Color color;

  const PhoneType(this.label, this.icon, this.color);

  static PhoneType fromString(String value) {
    return PhoneType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PhoneType.mobile,
    );
  }
}

enum PhoneStatus {
  active('Активен', Colors.green),
  suspended('Приостановлен', Colors.orange),
  blocked('Заблокирован', Colors.red),
  reserved('Зарезервирован', Colors.blue),
  cancelled('Отменен', Colors.grey);

  final String label;
  final Color color;

  const PhoneStatus(this.label, this.color);

  static PhoneStatus fromString(String value) {
    return PhoneStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PhoneStatus.active,
    );
  }
}

enum SimStatus {
  active('Активна', Colors.green),
  inactive('Неактивна', Colors.grey),
  blocked('Заблокирована', Colors.red),
  expired('Истекла', Colors.orange);

  final String label;
  final Color color;

  const SimStatus(this.label, this.color);

  static SimStatus fromString(String value) {
    return SimStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SimStatus.inactive,
    );
  }
}

class PhoneNumber {
  String id;
  String number;
  String? extension;
  PhoneType type;
  PhoneStatus status;
  String? employeeId;
  String? employeeName;
  String? department;
  String? location;
  DateTime? assignedAt;
  DateTime? releasedAt;
  double? monthlyCost;
  String? operator;
  String? tariff;
  String? notes;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  PhoneNumber({
    required this.id,
    required this.number,
    this.extension,
    required this.type,
    this.status = PhoneStatus.active,
    this.employeeId,
    this.employeeName,
    this.department,
    this.location,
    this.assignedAt,
    this.releasedAt,
    this.monthlyCost,
    this.operator,
    this.tariff,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'extension': extension,
      'type': type.name,
      'status': status.name,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'department': department,
      'location': location,
      'assigned_at': assignedAt?.toIso8601String(),
      'released_at': releasedAt?.toIso8601String(),
      'monthly_cost': monthlyCost,
      'operator': operator,
      'tariff': tariff,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PhoneNumber.fromMap(Map<String, dynamic> map) {
    return PhoneNumber(
      id: map['id']?.toString() ?? '',
      number: map['number'] ?? '',
      extension: map['extension'],
      type: PhoneType.fromString(map['type'] ?? 'mobile'),
      status: PhoneStatus.fromString(map['status'] ?? 'active'),
      employeeId: map['employee_id']?.toString(),
      employeeName: map['employee_name'],
      department: map['department'],
      location: map['location'],
      assignedAt: map['assigned_at'] != null
          ? DateTime.tryParse(map['assigned_at'])
          : null,
      releasedAt: map['released_at'] != null
          ? DateTime.tryParse(map['released_at'])
          : null,
      monthlyCost: map['monthly_cost']?.toDouble(),
      operator: map['operator'],
      tariff: map['tariff'],
      notes: map['notes'],
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  PhoneNumber copyWith({
    String? id,
    String? number,
    String? extension,
    PhoneType? type,
    PhoneStatus? status,
    String? employeeId,
    String? employeeName,
    String? department,
    String? location,
    DateTime? assignedAt,
    DateTime? releasedAt,
    double? monthlyCost,
    String? operator,
    String? tariff,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PhoneNumber(
      id: id ?? this.id,
      number: number ?? this.number,
      extension: extension ?? this.extension,
      type: type ?? this.type,
      status: status ?? this.status,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      department: department ?? this.department,
      location: location ?? this.location,
      assignedAt: assignedAt ?? this.assignedAt,
      releasedAt: releasedAt ?? this.releasedAt,
      monthlyCost: monthlyCost ?? this.monthlyCost,
      operator: operator ?? this.operator,
      tariff: tariff ?? this.tariff,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAssigned => employeeId != null;

  String get displayNumber {
    if (extension != null && extension!.isNotEmpty) {
      return '$number (доб. $extension)';
    }
    return number;
  }

  String get formattedNumber {
    if (number.length == 11 && number.startsWith('7')) {
      return '+7 (${number.substring(1, 4)}) ${number.substring(4, 7)}-${number.substring(7, 9)}-${number.substring(9, 11)}';
    }
    if (number.length == 10) {
      return '+7 (${number.substring(0, 3)}) ${number.substring(3, 6)}-${number.substring(6, 8)}-${number.substring(8, 10)}';
    }
    return number;
  }
}

class SimCard {
  String id;
  String iccid;
  String? imsi;
  String? pin;
  String? puk;
  String? phoneNumber;
  SimStatus status;
  String? operator;
  String? tariff;
  DateTime? activationDate;
  DateTime? expirationDate;
  double? balance;
  double? monthlyLimit;
  String? employeeId;
  String? employeeName;
  String? deviceImei;
  String? notes;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  SimCard({
    required this.id,
    required this.iccid,
    this.imsi,
    this.pin,
    this.puk,
    this.phoneNumber,
    this.status = SimStatus.inactive,
    this.operator,
    this.tariff,
    this.activationDate,
    this.expirationDate,
    this.balance,
    this.monthlyLimit,
    this.employeeId,
    this.employeeName,
    this.deviceImei,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'iccid': iccid,
      'imsi': imsi,
      'pin': pin,
      'puk': puk,
      'phone_number': phoneNumber,
      'status': status.name,
      'operator': operator,
      'tariff': tariff,
      'activation_date': activationDate?.toIso8601String(),
      'expiration_date': expirationDate?.toIso8601String(),
      'balance': balance,
      'monthly_limit': monthlyLimit,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'device_imei': deviceImei,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SimCard.fromMap(Map<String, dynamic> map) {
    return SimCard(
      id: map['id']?.toString() ?? '',
      iccid: map['iccid'] ?? '',
      imsi: map['imsi'],
      pin: map['pin'],
      puk: map['puk'],
      phoneNumber: map['phone_number'],
      status: SimStatus.fromString(map['status'] ?? 'inactive'),
      operator: map['operator'],
      tariff: map['tariff'],
      activationDate: map['activation_date'] != null
          ? DateTime.tryParse(map['activation_date'])
          : null,
      expirationDate: map['expiration_date'] != null
          ? DateTime.tryParse(map['expiration_date'])
          : null,
      balance: map['balance']?.toDouble(),
      monthlyLimit: map['monthly_limit']?.toDouble(),
      employeeId: map['employee_id']?.toString(),
      employeeName: map['employee_name'],
      deviceImei: map['device_imei'],
      notes: map['notes'],
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final daysUntil = expirationDate!.difference(DateTime.now()).inDays;
    return daysUntil <= 30 && daysUntil > 0;
  }

  String get formattedExpirationDate {
    return expirationDate != null
        ? DateFormat('dd.MM.yyyy').format(expirationDate!)
        : 'Не указано';
  }

  String get maskedIccid {
    if (iccid.length <= 8) return iccid;
    return '${iccid.substring(0, 4)}****${iccid.substring(iccid.length - 4)}';
  }
}

class PhoneCallRecord {
  int? id;
  String phoneId;
  String phoneNumber;
  String callType;
  String? destinationNumber;
  int duration;
  DateTime callDate;
  double? cost;
  String? notes;
  DateTime createdAt;

  PhoneCallRecord({
    this.id,
    required this.phoneId,
    required this.phoneNumber,
    required this.callType,
    this.destinationNumber,
    required this.duration,
    required this.callDate,
    this.cost,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone_id': phoneId,
      'phone_number': phoneNumber,
      'call_type': callType,
      'destination_number': destinationNumber,
      'duration': duration,
      'call_date': callDate.toIso8601String(),
      'cost': cost,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PhoneCallRecord.fromMap(Map<String, dynamic> map) {
    return PhoneCallRecord(
      id: map['id'],
      phoneId: map['phone_id']?.toString() ?? '',
      phoneNumber: map['phone_number'] ?? '',
      callType: map['call_type'] ?? '',
      destinationNumber: map['destination_number'],
      duration: map['duration'] ?? 0,
      callDate: DateTime.tryParse(map['call_date'] ?? '') ?? DateTime.now(),
      cost: map['cost']?.toDouble(),
      notes: map['notes'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    return DateFormat('dd.MM.yyyy HH:mm').format(callDate);
  }
}
