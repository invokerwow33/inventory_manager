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
  static const String _defaultUrl = 'http://localhost:8080/api';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _syncUrlKey = 'sync_server_url';

  /// Получает URL сервера синхронизации из настроек
  Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_syncUrlKey) ?? _defaultUrl;
  }

  /// Сохраняет URL сервера синхронизации
  Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncUrlKey, url);
  }

  /// Проверяет доступность сервера
  Future<bool> checkServerConnection([String? url]) async {
    try {
      final serverUrl = url ?? await getServerUrl();
      final response = await _dio.get(
        '$serverUrl/health',
        options: Options(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      LoggerService().warning('Сервер синхронизации недоступен: $e');
      return false;
    }
  }

  Future<void> syncWithServer() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception('Нет подключения к интернету');
    }

    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncKey) ?? 0;
    final baseUrl = await getServerUrl();

    // Проверяем доступность сервера
    final isServerAvailable = await checkServerConnection(baseUrl);
    if (!isServerAvailable) {
      throw Exception('Сервер синхронизации недоступен: $baseUrl');
    }

    try {
      // Отправка измененных данных на сервер
      await _sendLocalChanges(baseUrl);

      // Получение обновлений с сервера
      await _fetchUpdates(baseUrl, lastSync);

      // Обновление времени последней синхронизации
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      throw Exception('Ошибка синхронизации: $e');
    }
  }

  Future<void> _sendLocalChanges(String baseUrl) async {
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
          '$baseUrl/equipment',
          data: equipment.toMap(),
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
      } catch (e) {
        LoggerService().warning('Ошибка отправки оборудования ${equipment.id}: $e');
        // Можно добавить в очередь на повторную отправку
      }
    }
  }

  Future<void> _fetchUpdates(String baseUrl, int lastSync) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final response = await _dio.get(
        '$baseUrl/equipment/updates',
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