// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart'; // Добавьте этот импорт
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../screens/database_helper.dart';
import '../models/equipment.dart';

class BackupService {
  // Используйте экземпляр DatabaseHelper напрямую
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<void> createBackup() async {
    try {
      // Получаем все оборудование из базы данных
      final List<Equipment> equipmentList = await _getAllEquipment();
      
      // Преобразуем в JSON
      final List<Map<String, dynamic>> jsonList = equipmentList
          .map((equipment) => equipment.toMap())
          .toList();
      
      final String jsonData = jsonEncode({
        'backupDate': DateTime.now().toIso8601String(),
        'equipmentCount': equipmentList.length,
        'equipment': jsonList,
      });
      
      // Получаем директорию для сохранения
      final Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        throw Exception('Не удалось получить директорию загрузок');
      }
      
      final String backupPath = '${downloadsDir.path}/inventory_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final File backupFile = File(backupPath);
      
      await backupFile.writeAsString(jsonData);
      
      print('Backup создан: $backupPath');
      print('Сохранено записей: ${equipmentList.length}');
      
    } catch (e) {
      print('Ошибка при создании бэкапа: $e');
      rethrow;
    }
  }

  Future<void> restoreBackup() async {
    try {
      // Позволяем пользователю выбрать файл бэкапа
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null) {
        final File backupFile = File(result.files.single.path!);
        final String jsonData = await backupFile.readAsString();
        final Map<String, dynamic> backup = jsonDecode(jsonData);
        
        final List<dynamic> equipmentData = backup['equipment'];
        final List<Equipment> equipmentList = equipmentData
            .map((data) => Equipment.fromMap(Map<String, dynamic>.from(data)))
            .toList();
        
        // Очищаем базу данных и восстанавливаем данные
        await _restoreEquipment(equipmentList);
        
        print('Бэкап восстановлен: ${equipmentList.length} записей');
      }
    } catch (e) {
      print('Ошибка при восстановлении бэкапа: $e');
      rethrow;
    }
  }

  Future<List<Equipment>> _getAllEquipment() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('equipment');
      
      return maps.map((map) => Equipment.fromMap(map)).toList();
    } catch (e) {
      print('Ошибка при получении оборудования: $e');
      return [];
    }
  }

  Future<void> _restoreEquipment(List<Equipment> equipmentList) async {
    try {
      final db = await dbHelper.database;
      
      // Начинаем транзакцию
      await db.transaction((txn) async {
        // Очищаем таблицу
        await txn.delete('equipment');
        
        // Вставляем новые данные
        for (final equipment in equipmentList) {
          await txn.insert(
            'equipment',
            equipment.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      
      print('Восстановлено ${equipmentList.length} записей оборудования');
    } catch (e) {
      print('Ошибка при восстановлении оборудования: $e');
      rethrow;
    }
  }

  // Метод для проверки существования бэкапов
  Future<List<FileSystemEntity>> getBackupFiles() async {
    try {
      final Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) return [];
      
      final List<FileSystemEntity> files = downloadsDir.listSync();
      return files.where((file) {
        return file is File && 
               file.path.endsWith('.json') && 
               file.path.contains('inventory_backup_');
      }).toList();
    } catch (e) {
      print('Ошибка при получении списка бэкапов: $e');
      return [];
    }
  }

  // Метод для удаления старых бэкапов
  Future<void> cleanOldBackups({int keepLast = 5}) async {
    try {
      final List<FileSystemEntity> backups = await getBackupFiles();
      
      if (backups.length > keepLast) {
        // Сортируем по дате изменения (новые в конце)
        backups.sort((a, b) {
          final aStat = a.statSync();
          final bStat = b.statSync();
          return aStat.modified.compareTo(bStat.modified);
        });
        
        // Удаляем самые старые, оставляя только keepLast самых новых
        final int toDelete = backups.length - keepLast;
        for (int i = 0; i < toDelete; i++) {
          await backups[i].delete();
          print('Удален старый бэкап: ${backups[i].path}');
        }
      }
    } catch (e) {
      print('Ошибка при очистке старых бэкапов: $e');
    }
  }
}