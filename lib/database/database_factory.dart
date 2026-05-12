import 'package:flutter/foundation.dart';
import 'database_helper_sqlite.dart';
import 'simple_database_helper.dart';

/// Factory для получения правильной реализации DatabaseHelper
/// в зависимости от платформы (Desktop/Mobile vs Web)
class DatabaseFactory {
  static dynamic _instance;
  static bool _isWeb = kIsWeb;

  /// Получает instance DatabaseHelper для текущей платформы
  static dynamic get instance {
    if (_instance != null) return _instance;
    
    if (_isWeb) {
      _instance = SimpleDatabaseHelper();
    } else {
      _instance = DatabaseHelper.instance;
    }
    return _instance;
  }

  /// Проверяет, работаем ли мы на Web платформе
  static bool get isWeb => _isWeb;

  /// Принудительно устанавливает Web режим (для тестирования)
  static void setWebMode(bool value) {
    _isWeb = value;
    _instance = null;
  }
}
