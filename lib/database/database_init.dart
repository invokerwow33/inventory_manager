import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void initDatabase() {
  // Инициализируем FFI для Windows
  sqfliteFfiInit();
  
  // Устанавливаем фабрику базы данных для Windows
  databaseFactory = databaseFactoryFfi;
}