// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:inventory_manager/database/simple_database_helper.dart';
import 'package:inventory_manager/screens/backup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

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
          
          // ИСПРАВЛЕНИЕ БАЗЫ ДАННЫХ - ДОБАВЬТЕ ЭТОТ БЛОК
          ListTile(
            leading: const Icon(Icons.build, color: Colors.orange),
            title: const Text('Исправить базу данных'),
            subtitle: const Text('Исправить проблемы с типами данных'),
            onTap: () async {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Исправление базы данных'),
                  content: const Text('Вы уверены, что хотите исправить типы данных в базе?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final dbHelper = SimpleDatabaseHelper();
                        await dbHelper.fixDatabase();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('База данных исправлена')),
                        );
                      },
                      child: const Text('Исправить'),
                    ),
                  ],
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