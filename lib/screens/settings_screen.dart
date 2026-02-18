import 'package:flutter/material.dart';
import 'package:inventory_manager/screens/backup_screen.dart';
import 'package:inventory_manager/screens/import_screen.dart';
import 'package:inventory_manager/screens/logs_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
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