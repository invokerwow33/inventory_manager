// Этот файл автоматически выбирает реализацию БД в зависимости от платформы
// - Десктоп/Мобайл: SQLite (database_helper_sqlite.dart)
// - Веб: JSON файлы (database_helper_web.dart)
export 'database_helper_sqlite.dart' 
  if (dart.library.html) 'database_helper_web.dart';
