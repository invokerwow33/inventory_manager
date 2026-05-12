import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_manager/screens/backup_screen.dart';
import 'package:inventory_manager/screens/import_screen.dart';
import 'package:inventory_manager/screens/logs_screen.dart';
import 'package:inventory_manager/providers/settings_provider.dart';
import 'package:inventory_manager/services/sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _syncServerUrl;
  bool _isCheckingConnection = false;
  bool? _isServerConnected;

  @override
  void initState() {
    super.initState();
    _loadSyncUrl();
  }

  Future<void> _loadSyncUrl() async {
    final url = await SyncService().getServerUrl();
    setState(() {
      _syncServerUrl = url;
    });
  }

  Future<void> _checkServerConnection() async {
    setState(() {
      _isCheckingConnection = true;
    });
    final isConnected = await SyncService().checkServerConnection();
    setState(() {
      _isServerConnected = isConnected;
      _isCheckingConnection = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isConnected ? 'Сервер доступен' : 'Сервер недоступен'),
          backgroundColor: isConnected ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _showSyncServerDialog() async {
    final controller = TextEditingController(text: _syncServerUrl ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройки сервера синхронизации'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'URL сервера',
                hintText: 'http://localhost:8080/api',
                helperText: 'Введите адрес сервера синхронизации',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            if (_isServerConnected != null)
              Row(
                children: [
                  Icon(
                    _isServerConnected! ? Icons.check_circle : Icons.error,
                    color: _isServerConnected! ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isServerConnected! ? 'Сервер доступен' : 'Сервер недоступен',
                    style: TextStyle(
                      color: _isServerConnected! ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: _isCheckingConnection ? null : _checkServerConnection,
            child: _isCheckingConnection
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Проверить'),
          ),
          TextButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL не может быть пустым'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL должен начинаться с http:// или https://'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, url);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await SyncService().setServerUrl(result);
      final settings = context.read<SettingsProvider>();
      await settings.saveAppSettings(
        settings.appSettings.copyWith(syncServerUrl: result),
      );
      setState(() {
        _syncServerUrl = result;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL сервера сохранён')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        children: [
          // Заголовок
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Общие настройки',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          
          // Синхронизация - Сервер
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Сервер синхронизации'),
            subtitle: Text(_syncServerUrl ?? 'Не настроен'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showSyncServerDialog,
          ),
          
          // Уведомления
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Уведомления'),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
            ),
          ),
          
          // Резервное копирование
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Резервное копирование'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BackupScreen(),
                ),
              );
            },
          ),
          
          // Импорт данных
          ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.green),
            title: const Text('Импорт из CSV/Excel'),
            subtitle: const Text('Загрузить оборудование из файла'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ImportScreen(),
                ),
              );
            },
          ),

          // Логи ошибок
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Логи ошибок'),
            subtitle: const Text('Просмотр зарегистрированных ошибок'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LogsScreen(),
                ),
              );
            },
          ),
          
          const Divider(),
          
          // Информация
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('О приложении'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Inventory Manager'),
                  content: const Text('Версия 1.0\n\nПриложение для управления инвентарем оборудования.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Закрыть'),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Помощь
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Помощь'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Помощь'),
                  content: const Text('Для получения помощи:\n\nEmail: support@example.com\nТелефон: +7 (999) 123-45-67'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Закрыть'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}