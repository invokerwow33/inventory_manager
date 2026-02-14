// Этот файл переключает базу данных в зависимости от платформы
// Для десктопа: SQLite (sqflite)
// Для веба: JSON файлы (SimpleDatabaseHelper)
import 'database_stub.dart'
    if (dart.library.io) 'database_io.dart'
    if (dart.library.html) 'database_web.dart';
