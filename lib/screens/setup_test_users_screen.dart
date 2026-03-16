import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../providers/auth_provider.dart';

/// Экран для создания тестовых пользователей
/// Используйте только для тестирования!
class SetupTestUsersScreen extends StatefulWidget {
  const SetupTestUsersScreen({super.key});

  @override
  State<SetupTestUsersScreen> createState() => _SetupTestUsersScreenState();
}

class _SetupTestUsersScreenState extends State<SetupTestUsersScreen> {
  final _dbHelper = DatabaseHelper.instance;
  bool _isLoading = false;
  bool _isCompleted = false;
  String? _error;

  Future<void> _createTestUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final db = await _dbHelper.database;

      // Создаем админа
      final adminId = 'admin_${DateTime.now().millisecondsSinceEpoch}';
      final adminHash = BCrypt.hashpw('admin123', BCrypt.gensalt(logRounds: 4));
      
      await db.insert(
        'users',
        {
          'id': adminId,
          'username': 'admin',
          'email': 'admin@company.com',
          'password_hash': adminHash,
          'role': 'admin',
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Создаем сотрудника
      final employeeId = 'emp_${DateTime.now().millisecondsSinceEpoch}';
      final employeeHash = BCrypt.hashpw('user123', BCrypt.gensalt(logRounds: 4));
      
      await db.insert(
        'users',
        {
          'id': employeeId,
          'username': 'employee',
          'email': 'employee@company.com',
          'password_hash': employeeHash,
          'role': 'user',
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      setState(() {
        _isLoading = false;
        _isCompleted = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Ошибка: $e';
      });
    }
  }

  Future<void> _quickLogin(String username, String password) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(username, password);
    
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка входа')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать тестовых пользователей'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.people,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Создание тестовых пользователей',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Будут созданы два пользователя для тестирования системы задач:',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  _buildUserCard(
                    'Администратор',
                    'admin',
                    'admin123',
                    'Создание задач, назначение исполнителей, просмотр всех задач',
                    Icons.admin_panel_settings,
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildUserCard(
                    'Сотрудник',
                    'employee',
                    'user123',
                    'Просмотр своих задач, изменение статусов, общение в чате',
                    Icons.person,
                    Colors.green,
                  ),
                  const SizedBox(height: 32),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else if (_isCompleted)
                    Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Пользователи созданы!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Выберите пользователя для входа:',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        // Кнопка входа за админа
                        SizedBox(
                          width: double.maxFinite,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _quickLogin('admin', 'admin123');
                            },
                            icon: const Icon(Icons.admin_panel_settings),
                            label: const Text('Войти как Администратор'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Кнопка входа за сотрудника
                        SizedBox(
                          width: double.maxFinite,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _quickLogin('employee', 'user123');
                            },
                            icon: const Icon(Icons.person),
                            label: const Text('Войти как Сотрудник'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            context.read<AuthProvider>().logout();
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text('Вернуться на страницу входа'),
                        ),
                      ],
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _createTestUsers,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Создать пользователей'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(
    String title,
    String username,
    String password,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Логин: $username',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Пароль: $password',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
