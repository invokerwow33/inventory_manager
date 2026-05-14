class Employee {
  final String id;
  final String fullName;
  final String position;
  final String? department;
  final String? email;
  final String? phone;
  final List<String> equipmentIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Employee({
    required this.id,
    required this.fullName,
    required this.position,
    this.department,
    this.email,
    this.phone,
    List<String>? equipmentIds,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  }) : equipmentIds = equipmentIds ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'position': position,
      'department': department,
      'email': email,
      'phone': phone,
      'equipmentIds': equipmentIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      position: map['position'] ?? '',
      department: map['department'],
      email: map['email'],
      phone: map['phone'],
      equipmentIds: List<String>.from(map['equipmentIds'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isActive: map['isActive'] ?? true,
    );
  }

  Employee copyWith({
    String? id,
    String? fullName,
    String? position,
    String? department,
    String? email,
    String? phone,
    List<String>? equipmentIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Employee(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      position: position ?? this.position,
      department: department ?? this.department,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      equipmentIds: equipmentIds ?? List.from(this.equipmentIds),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  int get equipmentCount => equipmentIds.length;
}
