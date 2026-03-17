import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import '../models/user.dart';
import '../models/permission.dart';

/// Экран создания/редактирования пользователя
class EditUserScreen extends StatefulWidget {
  final User? user;

  const EditUserScreen({super.key, this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.user;
  Set<Permission> _selectedPermissions = {};
  bool _isActive = true;
  bool _isLoading = false;

  bool get _isEditMode => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode && widget.user != null) {
      _usernameController.text = widget.user!.username;
      _emailController.text = widget.user!.email ?? '';
      _selectedRole = widget.user!.role;
      _selectedPermissions = widget.user!.permissions.toSet();
      _isActive = widget.user!.isActive;
    } else {
      _selectedRole = UserRole.employee;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      
      String? passwordHash;
      if (_passwordController.text.isNotEmpty) {
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пароли не совпадают')),
          );
          return;
        }
        passwordHash = _hashPassword(_passwordController.text);
      } else if (!_isEditMode) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите пароль')),
        );
        return;
      }

      final userId = widget.user?.id ?? 'usr_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now().toIso8601String();

      final userData = {
        'id': userId,
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'role': _selectedRole.name,
        'permissions': _selectedPermissions.map((p) => p.name).join(','),
        'is_active': _isActive ? 1 : 0,
        'updated_at': now,
      };

      if (passwordHash != null) {
        userData['password_hash'] = passwordHash;
      }

      if (_isEditMode) {
        userData['created_at'] = widget.user!.createdAt.toIso8601String();
        await db.update(
          'users',
          userData,
          where: 'id = ?',
          whereArgs: [userId],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('Пользователь обновлен: ${userData['username']}');
      } else {
        userData['created_at'] = now;
        final result = await db.insert('users', userData, conflictAlgorithm: ConflictAlgorithm.replace);
        print('Пользователь создан: ${userData['username']}, ID=$result');
      }

      // Проверяем что пользователь действительно сохранился
      final checkResult = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      print('Проверка: найдено записей=${checkResult.length}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Пользователь обновлен' : 'Пользователь создан'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Редактирование' : 'Новый пользователь'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveUser,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Основная информация
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Основная информация',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Имя пользователя *',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Введите имя';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<UserRole>(
                              initialValue: _selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'Роль',
                                prefixIcon: Icon(Icons.badge),
                                border: OutlineInputBorder(),
                              ),
                              items: UserRole.values.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Row(
                                    children: [
                                      Icon(role.icon, color: role.color, size: 20),
                                      const SizedBox(width: 8),
                                      Text(role.label),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedRole = value);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Активен'),
                              subtitle: Text(_isActive ? 'Пользователь может входить в систему' : 'Доступ заблокирован'),
                              value: _isActive,
                              onChanged: (value) {
                                setState(() => _isActive = value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Пароль
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Пароль',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_isEditMode) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Не обязательно',
                                      style: TextStyle(fontSize: 10, color: Colors.blue),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: _isEditMode ? 'Новый пароль' : 'Пароль *',
                                prefixIcon: const Icon(Icons.lock),
                                border: const OutlineInputBorder(),
                                helperText: _isEditMode ? 'Оставьте пустым, чтобы не менять' : null,
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: const InputDecoration(
                                labelText: 'Подтверждение пароля',
                                prefixIcon: Icon(Icons.lock_outline),
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Права доступа
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Права доступа',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Выберите права для пользователя',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),
                            _buildPermissionSection(
                              'Оборудование',
                              [
                                Permission.viewEquipment,
                                Permission.createEquipment,
                                Permission.editEquipment,
                                Permission.deleteEquipment,
                              ],
                            ),
                            _buildPermissionSection(
                              'Расходники',
                              [
                                Permission.viewConsumables,
                                Permission.createConsumable,
                                Permission.editConsumable,
                                Permission.deleteConsumable,
                              ],
                            ),
                            _buildPermissionSection(
                              'Задачи',
                              [
                                Permission.viewTasks,
                                Permission.createTask,
                                Permission.editTask,
                                Permission.deleteTask,
                                Permission.assignTask,
                              ],
                            ),
                            _buildPermissionSection(
                              'Пользователи',
                              [
                                Permission.viewUsers,
                                Permission.createUser,
                                Permission.editUser,
                                Permission.deleteUser,
                                Permission.editUserPermissions,
                              ],
                            ),
                            _buildPermissionSection(
                              'Отчеты',
                              [
                                Permission.viewReports,
                                Permission.exportReports,
                              ],
                            ),
                            _buildPermissionSection(
                              'Настройки',
                              [
                                Permission.viewSettings,
                                Permission.editSettings,
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Кнопка сохранения
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveUser,
                      icon: const Icon(Icons.save),
                      label: Text(_isEditMode ? 'Сохранить изменения' : 'Создать пользователя'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPermissionSection(String title, List<Permission> permissions) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: permissions.map((permission) {
              final isSelected = _selectedPermissions.contains(permission);
              return FilterChip(
                label: Text(permission.label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedPermissions.add(permission);
                    } else {
                      _selectedPermissions.remove(permission);
                    }
                  });
                },
                selectedColor: Colors.blue.withOpacity(0.2),
                checkmarkColor: Colors.blue,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.blue : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
