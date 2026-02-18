// Web platform uses SimpleDatabaseHelper
// This file exports the same interface as database_helper_sqlite.dart

export 'simple_database_helper.dart' show SimpleDatabaseHelper;

import 'simple_database_helper.dart';

// Extension to make SimpleDatabaseHelper compatible with the unified interface
extension DatabaseHelperWeb on SimpleDatabaseHelper {
  static SimpleDatabaseHelper get instance => SimpleDatabaseHelper();
}
