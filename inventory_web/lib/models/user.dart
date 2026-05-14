import 'package:flutter/material.dart';

class User {
  final String id;
  final String username;
  final String passwordHash;
  final String fullName;
  final String role; // admin, manager, user
  final DateTime createdAt;
  final bool isActive;

  User({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.fullName,
    required this.role,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'passwordHash': passwordHash,
      'fullName': fullName,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      passwordHash: map['passwordHash'] ?? '',
      fullName: map['fullName'] ?? '',
      role: map['role'] ?? 'user',
      createdAt: DateTime.parse(map['createdAt']),
      isActive: map['isActive'] ?? true,
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? passwordHash,
    String? fullName,
    String? role,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
