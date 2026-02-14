import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/simple_database_helper.dart';
import '../models/equipment.dart';

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
    final localEquipment = await DatabaseHelper.instance.getAllEquipment();
    
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
        print('Ошибка отправки оборудования ${equipment.id}: $e');
        // Можно добавить в очередь на повторную отправку
      }
    }
  }

  Future<void> _fetchUpdates(int lastSync) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/equipment/updates',
        queryParameters: {'since': lastSync},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        for (final item in data) {
          final equipment = Equipment.fromMap(item);
          // Проверяем, есть ли уже такая запись
          final existing = await DatabaseHelper.instance.getEquipment(equipment.id);
          
          if (existing == null) {
            await DatabaseHelper.instance.insertEquipment(equipment);
          } else if (existing.updatedAt.isBefore(equipment.updatedAt)) {
            await DatabaseHelper.instance.updateEquipment(equipment);
          }
        }
      }
    } catch (e) {
      print('Ошибка получения обновлений: $e');
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
    final localEquipment = await DatabaseHelper.instance.getAllEquipment();
    final lastSyncTime = _getLastSyncTime();
    
    return localEquipment.any(
      (e) => e.updatedAt.millisecondsSinceEpoch > lastSyncTime,
    );
  }
}