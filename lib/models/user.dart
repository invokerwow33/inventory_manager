import 'package:flutter/material.dart';
import 'permission.dart';

enum UserRole {
  admin('Администратор', Colors.red, Icons.admin_panel_settings),
  manager('Менеджер', Colors.orange, Icons.manage_accounts),
  user('Пользователь', Colors.blue, Icons.person),
  employee('Сотрудник', Colors.green, Icons.badge),
  viewer('Наблюдатель', Colors.grey, Icons.visibility),
  cashier('Кассир', Colors.teal, Icons.point_of_sale);

  final String label;
  final Color color;
  final IconData icon;

  const UserRole(this.label, this.color, this.icon);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UserRole.user,
    );
  }

  List<Permission> get defaultPermissions => Role.values
      .firstWhere((r) => r.name == name, orElse: () => Role.employee)
      .permissions;
}

class User {
  String id;
  String username;
  String? email;
  String? passwordHash; // Может быть null для входа без пароля
  UserRole role;
  List<Permission> permissions; // Индивидуальные права
  bool isActive;
  DateTime? lastLogin;
  String? employeeId;
  bool useBiometric;
  DateTime createdAt;
  DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    this.email,
    this.passwordHash,
    this.role = UserRole.user,
    List<Permission>? permissions,
    this.isActive = true,
    this.lastLogin,
    this.employeeId,
    this.useBiometric = false,
    required this.createdAt,
    required this.updatedAt,
  }) : permissions = permissions ?? role.defaultPermissions;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password_hash': passwordHash,
      'role': role.name,
      'permissions': permissions.map((p) => p.name).join(','),
      'is_active': isActive ? 1 : 0,
      'last_login': lastLogin?.toIso8601String(),
      'employee_id': employeeId,
      'use_biometric': useBiometric ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    final role = UserRole.fromString(map['role'] ?? 'user');
    final permissionsStr = map['permissions'] as String?;
    List<Permission>? permissions;
    if (permissionsStr != null && permissionsStr.isNotEmpty) {
      permissions = permissionsStr.split(',').map((p) {
        return Permission.values.firstWhere(
          (perm) => perm.name == p.trim(),
          orElse: () => Permission.viewEquipment,
        );
      }).toList();
    }
    
    return User(
      id: map['id']?.toString() ?? '',
      username: map['username'] ?? '',
      email: map['email'],
      passwordHash: map['password_hash'] ?? map['passwordHash'],
      role: role,
      permissions: permissions,
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      lastLogin: map['last_login'] != null
          ? DateTime.tryParse(map['last_login'])
          : null,
      employeeId: map['employee_id']?.toString(),
      useBiometric: map['use_biometric'] == 1 || map['use_biometric'] == true,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? passwordHash,
    UserRole? role,
    List<Permission>? permissions,
    bool? isActive,
    DateTime? lastLogin,
    String? employeeId,
    bool? useBiometric,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      employeeId: employeeId ?? this.employeeId,
      useBiometric: useBiometric ?? this.useBiometric,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isManager => role == UserRole.manager || role == UserRole.admin;
  
  // Проверка прав
  bool hasPermission(Permission permission) {
    if (isAdmin) return true; // Админ имеет все права
    return permissions.contains(permission);
  }
  
  bool hasPermissions(List<Permission> permissions) {
    if (isAdmin) return true;
    return permissions.every((p) => this.permissions.contains(p));
  }
  
  bool hasAnyPermission(List<Permission> permissions) {
    if (isAdmin) return true;
    return permissions.any((p) => this.permissions.contains(p));
  }
}

class UserSession {
  String id;
  String userId;
  String token;
  DateTime createdAt;
  DateTime expiresAt;
  String? deviceInfo;
  String? ipAddress;

  UserSession({
    required this.id,
    required this.userId,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    this.deviceInfo,
    this.ipAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'token': token,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'device_info': deviceInfo,
      'ip_address': ipAddress,
    };
  }

  factory UserSession.fromMap(Map<String, dynamic> map) {
    return UserSession(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      token: map['token'] ?? '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(map['expires_at'] ?? '') ?? DateTime.now(),
      deviceInfo: map['device_info'],
      ipAddress: map['ip_address'],
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
