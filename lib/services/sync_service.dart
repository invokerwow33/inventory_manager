import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import '../models/equipment.dart';
import '../services/logger_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final Dio _dio = Dio();
  static const String _baseUrl = 'http://your-server.com/api'; // Замените на ваш URL
  static const String _lastSyncKey = 'last_sync_timestamp';

  Future<void> syncWithServer() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception('Нет подключения к интернету');
    }

    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncKey) ?? 0;

    try {
      // Отправка измененных данных на сервер
      await _sendLocalChanges();

      // Получение обновлений с сервера
      await _fetchUpdates(lastSync);

      // Обновление времени последней синхронизации
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      throw Exception('Ошибка синхронизации: $e');
    }
  }

  Future<void> _sendLocalChanges() async {
    final dbHelper = DatabaseHelper.instance;
    final localEquipmentData = await dbHelper.getEquipment();
    final localEquipment = localEquipmentData.map((m) => Equipment.fromMap(m)).toList();

    // Фильтруем только измененные записи
    final changedEquipment = localEquipment
        .where((e) => e.updatedAt.millisecondsSinceEpoch > _getLastSyncTime())
        .toList();

    for (final equipment in changedEquipment) {
      try {
        await _dio.post(
          '$_baseUrl/equipment',
          data: equipment.toMap(),
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
      } catch (e) {
        LoggerService().warning('Ошибка отправки оборудования ${equipment.id}: $e');
        // Можно добавить в очередь на повторную отправку
      }
    }
  }

  Future<void> _fetchUpdates(int lastSync) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final response = await _dio.get(
        '$_baseUrl/equipment/updates',
        queryParameters: {'since': lastSync},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        for (final item in data) {
          final equipment = Equipment.fromMap(item);
          // Проверяем, есть ли уже такая запись
          final existingMap = await dbHelper.getEquipmentById(equipment.id);
          final existing = existingMap != null ? Equipment.fromMap(existingMap) : null;

          if (existing == null) {
            await dbHelper.insertEquipment(equipment.toMap());
          } else if (existing.updatedAt.isBefore(equipment.updatedAt)) {
            await dbHelper.updateEquipment(equipment.toMap());
          }
        }
      }
    } catch (e) {
      LoggerService().warning('Ошибка получения обновлений: $e');
    }
  }

  int _getLastSyncTime() {
    // TODO: Реализовать получение времени последней синхронизации
    return 0;
  }

  Future<Map<String, dynamic>> getSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncKey);
    final connectivityResult = await Connectivity().checkConnectivity();

    return {
      'lastSync': lastSync != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSync)
          : null,
      'isOnline': connectivityResult != ConnectivityResult.none,
      'hasPendingChanges': await _hasPendingChanges(),
    };
  }

  Future<bool> _hasPendingChanges() async {
    final dbHelper = DatabaseHelper.instance;
    final localEquipmentData = await dbHelper.getEquipment();
    final localEquipment = localEquipmentData.map((m) => Equipment.fromMap(m)).toList();
    final lastSyncTime = _getLastSyncTime();

    return localEquipment.any(
      (e) => e.updatedAt.millisecondsSinceEpoch > lastSyncTime,
    );
  }
}