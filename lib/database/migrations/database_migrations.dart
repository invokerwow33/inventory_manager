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
      CREATE TABLE IF NOT EXISTS sync_queue(
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
    await db.execute('DROP TABLE IF EXISTS sync_queue');
  }
}

class MigrationV5 extends Migration {
  MigrationV5() : super(5, 'Add room_equipment junction table');

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS room_equipment(
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
    await db.execute('DROP TABLE IF EXISTS room_equipment');
  }
}

class MigrationV6 extends Migration {
  MigrationV6() : super(6, 'Add tasks and task_comments tables');

  @override
  Future<void> up(Database db) async {
    // Tasks table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        created_by TEXT NOT NULL,
        created_by_name TEXT NOT NULL,
        assigned_to TEXT,
        assigned_to_name TEXT,
        status TEXT DEFAULT 'pending',
        priority TEXT DEFAULT 'normal',
        created_at TEXT NOT NULL,
        due_date TEXT,
        started_at TEXT,
        completed_at TEXT,
        notes TEXT
      )
    ''');

    // Task comments table (chat)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_comments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id TEXT NOT NULL,
        author_id TEXT NOT NULL,
        author_name TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_system INTEGER DEFAULT 0,
        FOREIGN KEY (task_id) REFERENCES tasks(id)
      )
    ''');

    // Index for faster lookups (ignore errors if index exists)
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_task_comments_task_id ON task_comments(task_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status)');
    } catch (_) {
      // Ignore index errors
    }
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS task_comments');
    await db.execute('DROP TABLE IF EXISTS tasks');
  }
}

class MigrationV7 extends Migration {
  MigrationV7() : super(7, 'Add permissions column to users table');

  @override
  Future<void> up(Database db) async {
    try {
      await db.execute('ALTER TABLE users ADD COLUMN permissions TEXT');
    } catch (_) {
      // Column might already exist
    }
  }

  @override
  Future<void> down(Database db) async {
    // SQLite doesn't support DROP COLUMN, so we just do nothing
  }
}

class MigrationV8 extends Migration {
  MigrationV8() : super(8, 'Add updated_at column to tasks table');

  @override
  Future<void> up(Database db) async {
    try {
      await db.execute('ALTER TABLE tasks ADD COLUMN updated_at TEXT');
    } catch (_) {
      // Column might already exist
    }
  }

  @override
  Future<void> down(Database db) async {
    // SQLite doesn't support DROP COLUMN, so we just do nothing
  }
}

class MigrationV9 extends Migration {
  MigrationV9() : super(9, 'Add database indexes for performance');

  @override
  Future<void> up(Database db) async {
    // Tasks table indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_created_by ON tasks(created_by)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to_status ON tasks(assigned_to, status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date)');
    
    // Consumables table indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_consumables_category ON consumables(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_consumables_low_stock ON consumables(min_quantity, quantity)');
    
    // Users table indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_users_role ON users(role)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active)');
    
    // Note: equipment table doesn't have category column, skipping those indexes
    // Note: equipment table doesn't have status column, skipping those indexes
  }

  @override
  Future<void> down(Database db) async {
    // Drop indexes
    await db.execute('DROP INDEX IF EXISTS idx_tasks_created_by');
    await db.execute('DROP INDEX IF EXISTS idx_tasks_assigned_to_status');
    await db.execute('DROP INDEX IF EXISTS idx_tasks_created_at');
    await db.execute('DROP INDEX IF EXISTS idx_tasks_due_date');
    await db.execute('DROP INDEX IF EXISTS idx_consumables_category');
    await db.execute('DROP INDEX IF EXISTS idx_consumables_low_stock');
    await db.execute('DROP INDEX IF EXISTS idx_users_role');
    await db.execute('DROP INDEX IF EXISTS idx_users_active');
  }
}

class DatabaseMigrationManager {
  static final List<Migration> migrations = [
    MigrationV2(),
    MigrationV3(),
    MigrationV4(),
    MigrationV5(),
    MigrationV6(),
    MigrationV7(),
    MigrationV8(),
    MigrationV9(),
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
