import 'package:flutter/material.dart';

enum UserRole {
  admin('Администратор', Colors.red, Icons.admin_panel_settings),
  manager('Менеджер', Colors.orange, Icons.manage_accounts),
  user('Пользователь', Colors.blue, Icons.person);

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
}

class User {
  String id;
  String username;
  String? email;
  String passwordHash;
  UserRole role;
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
    required this.passwordHash,
    this.role = UserRole.user,
    this.isActive = true,
    this.lastLogin,
    this.employeeId,
    this.useBiometric = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password_hash': passwordHash,
      'role': role.name,
      'is_active': isActive ? 1 : 0,
      'last_login': lastLogin?.toIso8601String(),
      'employee_id': employeeId,
      'use_biometric': useBiometric ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString() ?? '',
      username: map['username'] ?? '',
      email: map['email'],
      passwordHash: map['password_hash'] ?? map['passwordHash'] ?? '',
      role: UserRole.fromString(map['role'] ?? 'user'),
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
