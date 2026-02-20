import 'package:sqflite/sqflite.dart';

abstract class Migration {
  final int version;
  final String description;
  
  Migration(this.version, this.description);
  
  Future<void> up(Database db);
  Future<void> down(Database db);
}

class MigrationV2 extends Migration {
  MigrationV2() : super(2, 'Add barcode and qr_code to equipment');
  
  @override
  Future<void> up(Database db) async {
    await db.execute('ALTER TABLE equipment ADD COLUMN barcode TEXT');
    await db.execute('ALTER TABLE equipment ADD COLUMN qr_code TEXT');
  }
  
  @override
  Future<void> down(Database db) async {
    await db.execute('ALTER TABLE equipment DROP COLUMN barcode');
    await db.execute('ALTER TABLE equipment DROP COLUMN qr_code');
  }
}

class MigrationV3 extends Migration {
  MigrationV3() : super(3, 'Add geolocation to equipment');
  
  @override
  Future<void> up(Database db) async {
    await db.execute('ALTER TABLE equipment ADD COLUMN geolocation TEXT');
  }
  
  @override
  Future<void> down(Database db) async {
    await db.execute('ALTER TABLE equipment DROP COLUMN geolocation');
  }
}

class MigrationV4 extends Migration {
  MigrationV4() : super(4, 'Add sync_queue table');
  
  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE sync_queue(
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT,
        status TEXT DEFAULT 'pending',
        retry_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }
  
  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE sync_queue');
  }
}

class MigrationV5 extends Migration {
  MigrationV5() : super(5, 'Add room_equipment junction table');
  
  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE room_equipment(
        id TEXT PRIMARY KEY,
        room_id TEXT NOT NULL,
        equipment_id TEXT NOT NULL,
        assigned_at TEXT NOT NULL,
        removed_at TEXT,
        FOREIGN KEY (room_id) REFERENCES rooms(id),
        FOREIGN KEY (equipment_id) REFERENCES equipment(id)
      )
    ''');
  }
  
  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE room_equipment');
  }
}

class DatabaseMigrationManager {
  static final List<Migration> migrations = [
    MigrationV2(),
    MigrationV3(),
    MigrationV4(),
    MigrationV5(),
  ];
  
  static Migration? getMigration(int version) {
    try {
      return migrations.firstWhere((m) => m.version == version);
    } catch (_) {
      return null;
    }
  }
  
  static Future<void> runMigrations(Database db, int oldVersion, int newVersion) async {
    for (int i = oldVersion; i < newVersion; i++) {
      final migration = getMigration(i + 1);
      if (migration != null) {
        await migration.up(db);
      }
    }
  }
  
  static Future<void> runDowngrade(Database db, int oldVersion, int newVersion) async {
    for (int i = oldVersion - 1; i >= newVersion; i--) {
      final migration = getMigration(i);
      if (migration != null) {
        await migration.down(db);
      }
    }
  }
}
