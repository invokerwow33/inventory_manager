// lib/screens/backup_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  _BackupScreenState createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  bool _isCreatingBackup = false;
  bool _isRestoringBackup = false;
  List<String> _backupFiles = [];

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    try {
      final backups = await _backupService.getBackupFiles();
      setState(() {
        _backupFiles = backups.map((file) => file.path).toList();
      });
    } catch (e) {
      print('Error loading backup files: $e');
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isCreatingBackup = true;
    });

    try {
      await _backupService.createBackup();
      await _loadBackupFiles(); // Обновляем список после создания
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Резервная копия успешно создана'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при создании резервной копии: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingBackup = false;
        });
      }
    }
  }

  Future<void> _restoreBackup() async {
    setState(() {
      _isRestoringBackup = true;
    });

    try {
      await _backupService.restoreBackup();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Резервная копия успешно восстановлена'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при восстановлении: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRestoringBackup = false;
        });
      }
    }
  }

  Future<void> _cleanOldBackups() async {
    try {
      await _backupService.cleanOldBackups(keepLast: 5);
      await _loadBackupFiles(); // Обновляем список после очистки
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Старые резервные копии очищены'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при очистке: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Резервное копирование'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Управление резервными копиями',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            
            // Карточка создания бэкапа
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Создание резервной копии',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Создайте резервную копию всех данных оборудования. '
                      'Файл будет сохранен в папке "Загрузки".',
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isCreatingBackup ? null : _createBackup,
                        icon: _isCreatingBackup
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.backup),
                        label: Text(
                          _isCreatingBackup 
                            ? 'Создание...' 
                            : 'Создать резервную копию',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Карточка восстановления
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Восстановление из резервной копии',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Восстановите данные из ранее созданной резервной копии. '
                      'Текущие данные будут заменены.',
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isRestoringBackup ? null : _restoreBackup,
                        icon: _isRestoringBackup
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.restore),
                        label: Text(
                          _isRestoringBackup 
                            ? 'Восстановление...' 
                            : 'Восстановить из резервной копии',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Список существующих бэкапов
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Существующие резервные копии',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: _loadBackupFiles,
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Обновить список',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      if (_backupFiles.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Резервные копии не найдены',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: _backupFiles.length,
                            itemBuilder: (context, index) {
                              final backupPath = _backupFiles[index];
                              final fileName = backupPath.split('/').last;
                              
                              return ListTile(
                                leading: const Icon(Icons.insert_drive_file),
                                title: Text(fileName),
                                subtitle: Text(backupPath),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    try {
                                      await File(backupPath).delete();
                                      await _loadBackupFiles();
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Ошибка удаления: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _cleanOldBackups,
                          child: const Text('Очистить старые копии (оставить 5 последних)'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}