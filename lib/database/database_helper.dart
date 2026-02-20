import 'package:flutter/foundation.dart';

export 'database_helper_interface.dart';
export 'database_helper_sqlite.dart';

IDatabaseHelper getDatabaseHelper() {
  if (kIsWeb) {
    return SimpleDatabaseHelper();
  }
  return DatabaseHelper.instance;
}
