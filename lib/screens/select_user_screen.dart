import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../services/logger_service.dart';

/// Экран выбора пользователя для входа
/// Отображает список активных пользователей
class SelectUserScreen extends StatefulWidget {
  const SelectUserScreen({super.key});

  @override
  State<SelectUserScreen> createState() => _SelectUserScreenState();
}

class _SelectUserScreenState extends State<SelectUserScreen> {
  final LoggerService _logger = LoggerService();
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'users',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'username ASC',
      );

      _logger.info('Загружено пользователей: ${maps.length}');;
      for (var map in maps) {
        _logger.info('  - \${map['username']} (\${map['role']}) active=\${map['is_active']}');
      }

      setState(() {
        _users = maps.map((map) => User.fromMap(map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      _logger.warning('Ошибка загрузки пользователей: $e');;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectUser(User user) async {
    final auth = context.read<AuthProvider>();
    
    // Если у пользователя есть пароль, запрашиваем его
    if (user.passwordHash != null && user.passwordHash!.isNotEmpty) {
      final password = await _showPasswordDialog(user);
      if (password == null) return;
      
      final success = await auth.login(user.username, password);
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Неверный пароль')),
        );
      }
    } else {
      // Вход без пароля
      await auth.loginWithoutPassword(user.id);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  Future<String?> _showPasswordDialog(User user) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Вход: ${user.username}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Пароль',
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
          autofocus: true,
          onSubmitted: (_) {
            Navigator.pop(context, controller.text);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите пользователя'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              ).then((_) => _loadUsers());
            },
            tooltip: 'Добавить пользователя',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? _buildEmptyState()
              : _buildUserList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Нет пользователей',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Создайте первого пользователя\nдля входа в систему',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              ).then((_) => _loadUsers());
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Создать пользователя'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _selectUser(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Аватар
              CircleAvatar(
                radius: 28,
                backgroundColor: user.role.color.withOpacity(0.2),
                child: Icon(
                  user.role.icon,
                  color: user.role.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              
              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: user.role.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: user.role.color.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            user.role.label,
                            style: TextStyle(
                              color: user.role.color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (user.isAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  size: 12,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Админ',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Стрелка
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
