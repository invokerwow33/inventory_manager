import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> initDatabase() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'inventory.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Equipment table
    await db.execute('''
      CREATE TABLE equipment(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT,
        serial_number TEXT,
        inventory_number TEXT,
        manufacturer TEXT,
        model TEXT,
        department TEXT,
        responsible_person TEXT,
        purchase_date TEXT,
        purchase_price REAL,
        current_value REAL,
        amortization_rate REAL,
        status TEXT,
        location TEXT,
        room_id TEXT,
        photos TEXT,
        barcode TEXT,
        qr_code TEXT,
        geolocation TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Employees table
    await db.execute('''
      CREATE TABLE employees(
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        department TEXT,
        position TEXT,
        email TEXT,
        phone TEXT,
        employee_number TEXT,
        hire_date TEXT,
        termination_date TEXT,
        is_on_leave INTEGER DEFAULT 0,
        leave_start TEXT,
        leave_end TEXT,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Consumables table
    await db.execute('''
      CREATE TABLE consumables(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT,
        unit TEXT,
        quantity REAL DEFAULT 0,
        min_quantity REAL DEFAULT 0,
        supplier TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Movements table
    await db.execute('''
      CREATE TABLE movements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        equipment_id TEXT,
        equipment_name TEXT,
        from_location TEXT,
        to_location TEXT,
        from_responsible TEXT,
        to_responsible TEXT,
        movement_date TEXT,
        movement_type TEXT,
        document_number TEXT,
        photos TEXT,
        geolocation TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Consumable movements table
    await db.execute('''
      CREATE TABLE consumable_movements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        consumable_id TEXT,
        consumable_name TEXT,
        quantity REAL,
        operation_type TEXT,
        operation_date TEXT,
        employee_id TEXT,
        employee_name TEXT,
        document_number TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Users table
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        email TEXT,
        password_hash TEXT NOT NULL,
        role TEXT DEFAULT 'user',
        is_active INTEGER DEFAULT 1,
        last_login TEXT,
        employee_id TEXT,
        use_biometric INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Audit logs table
    await db.execute('''
      CREATE TABLE audit_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        username TEXT,
        action_type TEXT,
        entity_type TEXT,
        entity_id TEXT,
        entity_name TEXT,
        old_values TEXT,
        new_values TEXT,
        description TEXT,
        timestamp TEXT NOT NULL,
        ip_address TEXT,
        user_agent TEXT,
        session_id TEXT
      )
    ''');

    // Data versions table
    await db.execute('''
      CREATE TABLE data_versions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT,
        entity_id TEXT,
        version_number INTEGER,
        data TEXT,
        changed_by TEXT,
        changed_at TEXT,
        change_description TEXT
      )
    ''');

    // Maintenance records table
    await db.execute('''
      CREATE TABLE maintenance_records(
        id TEXT PRIMARY KEY,
        equipment_id TEXT,
        equipment_name TEXT,
        type TEXT,
        status TEXT,
        description TEXT,
        scheduled_date TEXT,
        completed_date TEXT,
        performed_by TEXT,
        cost REAL,
        notes TEXT,
        photos TEXT,
        reminder_days INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Maintenance schedules table
    await db.execute('''
      CREATE TABLE maintenance_schedules(
        id TEXT PRIMARY KEY,
        equipment_id TEXT,
        equipment_name TEXT,
        type TEXT,
        interval_months INTEGER,
        description TEXT,
        last_maintenance TEXT,
        next_maintenance TEXT,
        is_active INTEGER DEFAULT 1,
        assigned_to TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Consumable price history table
    await db.execute('''
      CREATE TABLE consumable_price_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        consumable_id TEXT,
        consumable_name TEXT,
        supplier TEXT,
        price REAL,
        quantity REAL,
        currency TEXT,
        purchase_date TEXT,
        document_number TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Consumable batches table
    await db.execute('''
      CREATE TABLE consumable_batches(
        id TEXT PRIMARY KEY,
        consumable_id TEXT,
        consumable_name TEXT,
        batch_number TEXT,
        quantity REAL,
        received_date TEXT,
        expiration_date TEXT,
        supplier TEXT,
        document_number TEXT,
        is_active INTEGER DEFAULT 1,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Reorder points table
    await db.execute('''
      CREATE TABLE reorder_points(
        id TEXT PRIMARY KEY,
        consumable_id TEXT,
        consumable_name TEXT,
        minimum_stock REAL,
        reorder_point REAL,
        reorder_quantity REAL,
        preferred_supplier TEXT,
        lead_time_days INTEGER,
        auto_reorder INTEGER DEFAULT 0,
        notification_email TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Rooms table
    await db.execute('''
      CREATE TABLE rooms(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        number TEXT,
        type TEXT,
        floor TEXT,
        building TEXT,
        description TEXT,
        floor_plan_url TEXT,
        area REAL,
        capacity INTEGER,
        responsible_person TEXT,
        equipment_ids TEXT,
        parent_room_id TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Room equipment table
    await db.execute('''
      CREATE TABLE room_equipment(
        id TEXT PRIMARY KEY,
        room_id TEXT,
        equipment_id TEXT,
        equipment_name TEXT,
        inventory_number TEXT,
        placed_at TEXT,
        removed_at TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Inventory audits table
    await db.execute('''
      CREATE TABLE inventory_audits(
        id TEXT PRIMARY KEY,
        room_id TEXT,
        room_name TEXT,
        audit_date TEXT,
        conducted_by TEXT,
        status TEXT,
        expected_equipment_ids TEXT,
        found_equipment_ids TEXT,
        missing_equipment_ids TEXT,
        unexpected_equipment_ids TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Keys table
    await db.execute('''
      CREATE TABLE keys(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        key_number TEXT NOT NULL,
        type TEXT,
        status TEXT,
        room_id TEXT,
        room_name TEXT,
        description TEXT,
        access_level TEXT,
        copies_count INTEGER,
        restrictions TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Key issue records table
    await db.execute('''
      CREATE TABLE key_issue_records(
        id TEXT PRIMARY KEY,
        key_id TEXT,
        key_name TEXT,
        key_number TEXT,
        employee_id TEXT,
        employee_name TEXT,
        issued_at TEXT,
        returned_at TEXT,
        issued_by TEXT,
        received_by TEXT,
        document_number TEXT,
        purpose TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Phone numbers table
    await db.execute('''
      CREATE TABLE phone_numbers(
        id TEXT PRIMARY KEY,
        number TEXT NOT NULL,
        extension TEXT,
        type TEXT,
        status TEXT,
        employee_id TEXT,
        employee_name TEXT,
        department TEXT,
        location TEXT,
        assigned_at TEXT,
        released_at TEXT,
        monthly_cost REAL,
        operator TEXT,
        tariff TEXT,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // SIM cards table
    await db.execute('''
      CREATE TABLE sim_cards(
        id TEXT PRIMARY KEY,
        iccid TEXT NOT NULL,
        imsi TEXT,
        pin TEXT,
        puk TEXT,
        phone_number TEXT,
        status TEXT,
        operator TEXT,
        tariff TEXT,
        activation_date TEXT,
        expiration_date TEXT,
        balance REAL,
        monthly_limit REAL,
        employee_id TEXT,
        employee_name TEXT,
        device_imei TEXT,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Phone call records table
    await db.execute('''
      CREATE TABLE phone_call_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_id TEXT,
        phone_number TEXT,
        call_type TEXT,
        destination_number TEXT,
        duration INTEGER,
        call_date TEXT,
        cost REAL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Vehicles table
    await db.execute('''
      CREATE TABLE vehicles(
        id TEXT PRIMARY KEY,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER,
        vin TEXT,
        license_plate TEXT NOT NULL,
        type TEXT,
        status TEXT,
        fuel_type TEXT,
        color TEXT,
        mileage REAL,
        last_service TEXT,
        next_service TEXT,
        employee_id TEXT,
        employee_name TEXT,
        department TEXT,
        parking_location TEXT,
        fuel_capacity REAL,
        average_consumption REAL,
        insurance_expiry TEXT,
        inspection_expiry TEXT,
        documents TEXT,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Vehicle usage records table
    await db.execute('''
      CREATE TABLE vehicle_usage_records(
        id TEXT PRIMARY KEY,
        vehicle_id TEXT,
        vehicle_name TEXT,
        license_plate TEXT,
        employee_id TEXT,
        employee_name TEXT,
        start_time TEXT,
        end_time TEXT,
        start_mileage REAL,
        end_mileage REAL,
        purpose TEXT,
        route TEXT,
        fuel_used REAL,
        photos TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Vehicle expenses table
    await db.execute('''
      CREATE TABLE vehicle_expenses(
        id TEXT PRIMARY KEY,
        vehicle_id TEXT,
        vehicle_name TEXT,
        date TEXT,
        category TEXT,
        amount REAL,
        description TEXT,
        document_number TEXT,
        attachments TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Document templates table
    await db.execute('''
      CREATE TABLE document_templates(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT,
        content TEXT,
        variables TEXT,
        header_image TEXT,
        footer_text TEXT,
        is_default INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Document signatures table
    await db.execute('''
      CREATE TABLE document_signatures(
        id TEXT PRIMARY KEY,
        document_id TEXT,
        document_type TEXT,
        signer_id TEXT,
        signer_name TEXT,
        signer_role TEXT,
        signature_data TEXT,
        signed_at TEXT,
        ip_address TEXT,
        user_agent TEXT,
        notes TEXT
      )
    ''');

    // Generated documents table
    await db.execute('''
      CREATE TABLE generated_documents(
        id TEXT PRIMARY KEY,
        template_id TEXT,
        template_name TEXT,
        title TEXT,
        content TEXT,
        entity_type TEXT,
        entity_id TEXT,
        pdf_path TEXT,
        status TEXT,
        created_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Sync queue table
    await db.execute('''
      CREATE TABLE sync_queue(
        id TEXT PRIMARY KEY,
        operation TEXT,
        entity_type TEXT,
        entity_id TEXT,
        data TEXT,
        status TEXT,
        priority INTEGER,
        error_message TEXT,
        retry_count INTEGER DEFAULT 0,
        last_attempt TEXT,
        created_at TEXT NOT NULL,
        device_id TEXT,
        user_id TEXT
      )
    ''');

    // Sync conflicts table
    await db.execute('''
      CREATE TABLE sync_conflicts(
        id TEXT PRIMARY KEY,
        entity_type TEXT,
        entity_id TEXT,
        local_data TEXT,
        remote_data TEXT,
        local_timestamp TEXT,
        remote_timestamp TEXT,
        resolved_data TEXT,
        is_resolved INTEGER DEFAULT 0,
        resolution TEXT,
        created_at TEXT NOT NULL,
        resolved_at TEXT
      )
    ''');

    // Device sync info table
    await db.execute('''
      CREATE TABLE device_sync_info(
        id TEXT PRIMARY KEY,
        device_name TEXT,
        device_type TEXT,
        device_id TEXT,
        last_sync TEXT,
        is_online INTEGER DEFAULT 0,
        ip_address TEXT,
        last_seen TEXT,
        is_trusted INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // App settings table
    await db.execute('''
      CREATE TABLE app_settings(
        id INTEGER PRIMARY KEY,
        settings_json TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Notification settings table
    await db.execute('''
      CREATE TABLE notification_settings(
        id INTEGER PRIMARY KEY,
        user_id TEXT,
        settings_json TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Scheduled reports table
    await db.execute('''
      CREATE TABLE scheduled_reports(
        id TEXT PRIMARY KEY,
        name TEXT,
        report_type TEXT,
        frequency TEXT,
        day_of_week TEXT,
        day_of_month INTEGER,
        time TEXT,
        recipients TEXT,
        filters TEXT,
        is_active INTEGER DEFAULT 1,
        last_sent TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Favorites/bookmarks table
    await db.execute('''
      CREATE TABLE favorites(
        id TEXT PRIMARY KEY,
        user_id TEXT,
        type TEXT,
        name TEXT,
        data TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Create default admin user
    await db.insert('users', {
      'id': 'admin_default',
      'username': 'admin',
      'password_hash': '\$2a\$10\$YourHashedPasswordHere', // Placeholder - should be properly hashed
      'role': 'admin',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Insert default settings
    await db.insert('app_settings', {
      'id': 1,
      'settings_json': '{}',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 2 migrations
    }
    if (oldVersion < 3) {
      // Version 3 migrations - add all new tables
      await _createNewTables(db);
    }
  }

  Future<void> _createNewTables(Database db) async {
    // Add new tables that were added in version 3
    // This is a simplified version - in production would check if tables exist first
    
    try {
      // Users table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users(
          id TEXT PRIMARY KEY,
          username TEXT NOT NULL UNIQUE,
          email TEXT,
          password_hash TEXT NOT NULL,
          role TEXT DEFAULT 'user',
          is_active INTEGER DEFAULT 1,
          last_login TEXT,
          employee_id TEXT,
          use_biometric INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Audit logs table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS audit_logs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT,
          username TEXT,
          action_type TEXT,
          entity_type TEXT,
          entity_id TEXT,
          entity_name TEXT,
          old_values TEXT,
          new_values TEXT,
          description TEXT,
          timestamp TEXT NOT NULL,
          ip_address TEXT,
          user_agent TEXT,
          session_id TEXT
        )
      ''');

      // Maintenance records table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS maintenance_records(
          id TEXT PRIMARY KEY,
          equipment_id TEXT,
          equipment_name TEXT,
          type TEXT,
          status TEXT,
          description TEXT,
          scheduled_date TEXT,
          completed_date TEXT,
          performed_by TEXT,
          cost REAL,
          notes TEXT,
          photos TEXT,
          reminder_days INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Rooms table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS rooms(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          number TEXT,
          type TEXT,
          floor TEXT,
          building TEXT,
          description TEXT,
          floor_plan_url TEXT,
          area REAL,
          capacity INTEGER,
          responsible_person TEXT,
          equipment_ids TEXT,
          parent_room_id TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Keys table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS keys(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          key_number TEXT NOT NULL,
          type TEXT,
          status TEXT,
          room_id TEXT,
          room_name TEXT,
          description TEXT,
          access_level TEXT,
          copies_count INTEGER,
          restrictions TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Vehicles table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS vehicles(
          id TEXT PRIMARY KEY,
          make TEXT NOT NULL,
          model TEXT NOT NULL,
          year INTEGER,
          vin TEXT,
          license_plate TEXT NOT NULL,
          type TEXT,
          status TEXT,
          fuel_type TEXT,
          color TEXT,
          mileage REAL,
          last_service TEXT,
          next_service TEXT,
          employee_id TEXT,
          employee_name TEXT,
          department TEXT,
          parking_location TEXT,
          fuel_capacity REAL,
          average_consumption REAL,
          insurance_expiry TEXT,
          inspection_expiry TEXT,
          documents TEXT,
          notes TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Sync queue table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue(
          id TEXT PRIMARY KEY,
          operation TEXT,
          entity_type TEXT,
          entity_id TEXT,
          data TEXT,
          status TEXT,
          priority INTEGER,
          error_message TEXT,
          retry_count INTEGER DEFAULT 0,
          last_attempt TEXT,
          created_at TEXT NOT NULL,
          device_id TEXT,
          user_id TEXT
        )
      ''');
    } catch (e) {
      print('Error creating new tables: $e');
    }
  }

  // ========== USER METHODS ==========

  Future<List<Map<String, dynamic>>> getUsers({bool includeInactive = false}) async {
    final db = await database;
    if (includeInactive) {
      return await db.query('users');
    }
    return await db.query('users', where: 'is_active = ?', whereArgs: [1]);
  }

  Future<Map<String, dynamic>?> getUserById(String id) async {
    final db = await database;
    final results = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'username = ? AND is_active = ?',
      whereArgs: [username, 1],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<String> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    if (!user.containsKey('id') || user['id'] == null) {
      user['id'] = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    }
    final now = DateTime.now().toIso8601String();
    user['created_at'] ??= now;
    user['updated_at'] ??= now;
    await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
    return user['id'];
  }

  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await database;
    user['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [user['id']],
    );
  }

  Future<int> deleteUser(String id) async {
    final db = await database;
    return await db.update(
      'users',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateLastLogin(String userId) async {
    final db = await database;
    await db.update(
      'users',
      {'last_login': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ========== AUDIT LOG METHODS ==========

  Future<int> addAuditLog(Map<String, dynamic> log) async {
    final db = await database;
    log['timestamp'] = DateTime.now().toIso8601String();
    return await db.insert('audit_logs', log);
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({
    int limit = 100,
    int offset = 0,
    String? userId,
    String? entityType,
    String? actionType,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (userId != null) {
      whereClause = 'user_id = ?';
      whereArgs.add(userId);
    }
    if (entityType != null) {
      whereClause += whereClause.isNotEmpty ? ' AND ' : '';
      whereClause += 'entity_type = ?';
      whereArgs.add(entityType);
    }
    if (actionType != null) {
      whereClause += whereClause.isNotEmpty ? ' AND ' : '';
      whereClause += 'action_type = ?';
      whereArgs.add(actionType);
    }
    if (fromDate != null) {
      whereClause += whereClause.isNotEmpty ? ' AND ' : '';
      whereClause += 'timestamp >= ?';
      whereArgs.add(fromDate.toIso8601String());
    }
    if (toDate != null) {
      whereClause += whereClause.isNotEmpty ? ' AND ' : '';
      whereClause += 'timestamp <= ?';
      whereArgs.add(toDate.toIso8601String());
    }
    
    return await db.query(
      'audit_logs',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
  }

  // ========== EQUIPMENT METHODS ==========

  Future<List<Map<String, dynamic>>> getEquipment({bool forceRefresh = false}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('equipment');
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<Map<String, dynamic>?> getEquipmentById(dynamic id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'equipment',
      where: 'id = ?',
      whereArgs: [id.toString()],
    );
    if (maps.isEmpty) return null;
    return Map<String, dynamic>.from(maps.first);
  }

  Future<String> insertEquipment(Map<String, dynamic> equipment) async {
    final db = await database;
    if (!equipment.containsKey('id') || equipment['id'] == null) {
      equipment['id'] = 'eq_${DateTime.now().millisecondsSinceEpoch}';
    }
    final now = DateTime.now().toIso8601String();
    equipment['created_at'] ??= now;
    equipment['updated_at'] ??= now;

    await db.insert('equipment', equipment, conflictAlgorithm: ConflictAlgorithm.replace);
    return equipment['id'].toString();
  }

  Future<int> updateEquipment(Map<String, dynamic> equipment) async {
    final db = await database;
    equipment['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'equipment',
      equipment,
      where: 'id = ?',
      whereArgs: [equipment['id'].toString()],
    );
  }

  Future<int> deleteEquipment(dynamic id) async {
    final db = await database;
    return await db.delete(
      'equipment',
      where: 'id = ?',
      whereArgs: [id.toString()],
    );
  }

  Future<List<Map<String, dynamic>>> searchEquipment(String query) async {
    final db = await database;
    final lowerQuery = '%${query.toLowerCase()}%';
    final List<Map<String, dynamic>> maps = await db.query(
      'equipment',
      where: 'LOWER(name) LIKE ? OR LOWER(serial_number) LIKE ? OR LOWER(inventory_number) LIKE ?',
      whereArgs: [lowerQuery, lowerQuery, lowerQuery],
    );
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<List<Map<String, dynamic>>> searchEquipmentByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'equipment',
      where: 'LOWER(name) LIKE ?',
      whereArgs: ['%${name.toLowerCase()}%'],
      limit: 10,
    );
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<List<Map<String, dynamic>>> searchEquipmentByInventoryNumber(String inventoryNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'equipment',
      where: 'LOWER(inventory_number) LIKE ?',
      whereArgs: ['%${inventoryNumber.toLowerCase()}%'],
      limit: 10,
    );
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<int> getEquipmentCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM equipment');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ========== EMPLOYEE METHODS ==========

  Future<List<Map<String, dynamic>>> getEmployees({bool includeInactive = false}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;
    if (includeInactive) {
      maps = await db.query('employees');
    } else {
      maps = await db.query('employees', where: 'is_active = ?', whereArgs: [1]);
    }
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<Map<String, dynamic>?> getEmployeeById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Map<String, dynamic>.from(maps.first);
  }

  Future<String> insertEmployee(Map<String, dynamic> employee) async {
    final db = await database;
    if (!employee.containsKey('id') || employee['id'] == null) {
      employee['id'] = 'emp_${DateTime.now().millisecondsSinceEpoch}';
    }
    final now = DateTime.now().toIso8601String();
    employee['created_at'] ??= now;
    employee['updated_at'] ??= now;
    
    await db.insert('employees', employee, conflictAlgorithm: ConflictAlgorithm.replace);
    return employee['id'];
  }

  Future<int> updateEmployee(Map<String, dynamic> employee) async {
    final db = await database;
    employee['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'employees',
      employee,
      where: 'id = ?',
      whereArgs: [employee['id'].toString()],
    );
  }

  Future<int> deleteEmployee(String id) async {
    final db = await database;
    return await db.update(
      'employees',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> searchEmployees(String query) async {
    final db = await database;
    final lowerQuery = '%${query.toLowerCase()}%';
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'is_active = 1 AND (LOWER(full_name) LIKE ? OR LOWER(department) LIKE ? OR LOWER(position) LIKE ?)',
      whereArgs: [lowerQuery, lowerQuery, lowerQuery],
    );
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<List<String>> getDepartments() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT department FROM employees WHERE department IS NOT NULL AND department != "" ORDER BY department'
    );
    return result.map((r) => r['department'] as String).toList();
  }

  // ========== CONSUMABLE METHODS ==========

  Future<List<Map<String, dynamic>>> getConsumables() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('consumables');
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<Map<String, dynamic>?> getConsumableById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'consumables',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Map<String, dynamic>.from(maps.first);
  }

  Future<String> insertConsumable(Map<String, dynamic> consumable) async {
    final db = await database;
    if (!consumable.containsKey('id') || consumable['id'] == null) {
      consumable['id'] = 'cons_${DateTime.now().millisecondsSinceEpoch}';
    }
    final now = DateTime.now().toIso8601String();
    consumable['created_at'] ??= now;
    consumable['updated_at'] ??= now;
    
    await db.insert('consumables', consumable, conflictAlgorithm: ConflictAlgorithm.replace);
    return consumable['id'];
  }

  Future<int> updateConsumable(Map<String, dynamic> consumable) async {
    final db = await database;
    consumable['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'consumables',
      consumable,
      where: 'id = ?',
      whereArgs: [consumable['id'].toString()],
    );
  }

  Future<int> deleteConsumable(String id) async {
    final db = await database;
    return await db.delete(
      'consumables',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> searchConsumables(String query) async {
    final db = await database;
    final lowerQuery = '%${query.toLowerCase()}%';
    final List<Map<String, dynamic>> maps = await db.query(
      'consumables',
      where: 'LOWER(name) LIKE ? OR LOWER(category) LIKE ?',
      whereArgs: [lowerQuery, lowerQuery],
    );
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getLowStockConsumables() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'consumables',
      where: 'quantity <= min_quantity AND min_quantity > 0',
    );
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  // ========== MOVEMENT METHODS ==========

  Future<int> addMovement(Map<String, dynamic> movement) async {
    final db = await database;
    movement['created_at'] = DateTime.now().toIso8601String();
    return await db.insert('movements', movement);
  }

  Future<List<Map<String, dynamic>>> getMovements() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movements',
      orderBy: 'movement_date DESC',
    );
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getEquipmentMovements(dynamic equipmentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movements',
      where: 'equipment_id = ?',
      whereArgs: [equipmentId.toString()],
      orderBy: 'movement_date DESC',
    );
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getRecentMovements({int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'movements',
      orderBy: 'movement_date DESC',
      limit: limit,
    );
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<String> exportMovementsToCSV() async {
    final movements = await getMovements();
    final csvData = StringBuffer();
    
    csvData.writeln('ID,Дата,Тип,Оборудование,ID оборудования,Откуда,Куда,Ответственный от,Ответственный кому,Номер документа,Примечания');
    
    for (final movement in movements) {
      final row = [
        movement['id']?.toString() ?? '',
        '"${movement['movement_date']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${movement['movement_type']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${movement['equipment_name']?.toString().replaceAll('"', '""') ?? ''}"',
        movement['equipment_id']?.toString() ?? '',
        '"${movement['from_location']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${movement['to_location']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${movement['from_responsible']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${movement['to_responsible']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${movement['document_number']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${movement['notes']?.toString().replaceAll('"', '""') ?? ''}"',
      ].join(',');
      
      csvData.writeln(row);
    }
    
    return csvData.toString();
  }

  Future<void> clearMovements() async {
    final db = await database;
    await db.delete('movements');
  }

  // ========== CONSUMABLE MOVEMENT METHODS ==========

  Future<int> addConsumableMovement(Map<String, dynamic> movement) async {
    final db = await database;
    movement['created_at'] = DateTime.now().toIso8601String();
    final id = await db.insert('consumable_movements', movement);
    
    // Update consumable quantity
    final consumableId = movement['consumable_id']?.toString();
    final operationType = movement['operation_type']?.toString();
    final quantity = (movement['quantity'] ?? 0).toDouble();
    
    if (consumableId != null) {
      final consumable = await getConsumableById(consumableId);
      if (consumable != null) {
        double newQuantity = (consumable['quantity'] ?? 0).toDouble();
        if (operationType == 'приход') {
          newQuantity += quantity;
        } else if (operationType == 'расход') {
          newQuantity -= quantity;
        }
        
        await updateConsumable({
          'id': consumableId,
          'quantity': newQuantity,
        });
      }
    }
    
    return id;
  }

  Future<List<Map<String, dynamic>>> getConsumableMovements(String? consumableId) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (consumableId != null && consumableId.isNotEmpty) {
      maps = await db.query(
        'consumable_movements',
        where: 'consumable_id = ?',
        whereArgs: [consumableId],
        orderBy: 'operation_date DESC',
      );
    } else {
      maps = await db.query('consumable_movements', orderBy: 'operation_date DESC');
    }
    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  // ========== MAINTENANCE METHODS ==========

  Future<List<Map<String, dynamic>>> getMaintenanceRecords({String? equipmentId}) async {
    final db = await database;
    if (equipmentId != null) {
      return await db.query(
        'maintenance_records',
        where: 'equipment_id = ?',
        whereArgs: [equipmentId],
        orderBy: 'scheduled_date DESC',
      );
    }
    return await db.query('maintenance_records', orderBy: 'scheduled_date DESC');
  }

  Future<String> insertMaintenanceRecord(Map<String, dynamic> record) async {
    final db = await database;
    if (!record.containsKey('id') || record['id'] == null) {
      record['id'] = 'mnt_${DateTime.now().millisecondsSinceEpoch}';
    }
    final now = DateTime.now().toIso8601String();
    record['created_at'] ??= now;
    record['updated_at'] ??= now;
    await db.insert('maintenance_records', record, conflictAlgorithm: ConflictAlgorithm.replace);
    return record['id'];
  }

  Future<int> updateMaintenanceRecord(Map<String, dynamic> record) async {
    final db = await database;
    record['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'maintenance_records',
      record,
      where: 'id = ?',
      whereArgs: [record['id']],
    );
  }

  Future<List<Map<String, dynamic>>> getOverdueMaintenance() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.query(
      'maintenance_records',
      where: 'scheduled_date < ? AND status != ? AND status != ?',
      whereArgs: [now, 'completed', 'cancelled'],
      orderBy: 'scheduled_date ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getUpcomingMaintenance({int days = 7}) async {
    final db = await database;
    final future = DateTime.now().add(Duration(days: days)).toIso8601String();
    final now = DateTime.now().toIso8601String();
    return await db.query(
      'maintenance_records',
      where: 'scheduled_date BETWEEN ? AND ? AND status = ?',
      whereArgs: [now, future, 'scheduled'],
      orderBy: 'scheduled_date ASC',
    );
  }

  // ========== ROOM METHODS ==========

  Future<List<Map<String, dynamic>>> getRooms() async {
    final db = await database;
    return await db.query('rooms', where: 'is_active = ?', whereArgs: [1]);
  }

  Future<Map<String, dynamic>?> getRoomById(String id) async {
    final db = await database;
    final results = await db.query('rooms', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<String> insertRoom(Map<String, dynamic> room) async {
    final db = await database;
    if (!room.containsKey('id') || room['id'] == null) {
      room['id'] = 'room_${DateTime.now().millisecondsSinceEpoch}';
    }
    final now = DateTime.now().toIso8601String();
    room['created_at'] ??= now;
    room['updated_at'] ??= now;
    await db.insert('rooms', room, conflictAlgorithm: ConflictAlgorithm.replace);
    return room['id'];
  }

  Future<int> updateRoom(Map<String, dynamic> room) async {
    final db = await database;
    room['updated_at'] = DateTime.now().toIso8601String();
    return await db.update('rooms', room, where: 'id = ?', whereArgs: [room['id']]);
  }

  // ========== VEHICLE METHODS ==========

  Future<List<Map<String, dynamic>>> getVehicles() async {
    final db = await database;
    return await db.query('vehicles', where: 'is_active = ?', whereArgs: [1]);
  }

  Future<Map<String, dynamic>?> getVehicleById(String id) async {
    final db = await database;
    final results = await db.query('vehicles', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<String> insertVehicle(Map<String, dynamic> vehicle) async {
    final db = await database;
    if (!vehicle.containsKey('id') || vehicle['id'] == null) {
      vehicle['id'] = 'veh_${DateTime.now().millisecondsSinceEpoch}';
    }
    final now = DateTime.now().toIso8601String();
    vehicle['created_at'] ??= now;
    vehicle['updated_at'] ??= now;
    await db.insert('vehicles', vehicle, conflictAlgorithm: ConflictAlgorithm.replace);
    return vehicle['id'];
  }

  Future<int> updateVehicle(Map<String, dynamic> vehicle) async {
    final db = await database;
    vehicle['updated_at'] = DateTime.now().toIso8601String();
    return await db.update('vehicles', vehicle, where: 'id = ?', whereArgs: [vehicle['id']]);
  }

  // ========== SYNC QUEUE METHODS ==========

  Future<String> addToSyncQueue(Map<String, dynamic> item) async {
    final db = await database;
    if (!item.containsKey('id') || item['id'] == null) {
      item['id'] = 'sync_${DateTime.now().millisecondsSinceEpoch}';
    }
    item['created_at'] = DateTime.now().toIso8601String();
    item['status'] ??= 'pending';
    await db.insert('sync_queue', item, conflictAlgorithm: ConflictAlgorithm.replace);
    return item['id'];
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems({int limit = 100}) async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'priority DESC, created_at ASC',
      limit: limit,
    );
  }

  Future<int> updateSyncItemStatus(String id, String status, {String? errorMessage}) async {
    final db = await database;
    final updates = <String, dynamic>{
      'status': status,
      'last_attempt': DateTime.now().toIso8601String(),
    };
    if (errorMessage != null) {
      updates['error_message'] = errorMessage;
    }
    return await db.update('sync_queue', updates, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> incrementRetryCount(String id) async {
    final db = await database;
    final item = await db.query('sync_queue', where: 'id = ?', whereArgs: [id]);
    if (item.isNotEmpty) {
      final currentCount = item.first['retry_count'] as int? ?? 0;
      return await db.update(
        'sync_queue',
        {'retry_count': currentCount + 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    return 0;
  }

  Future<int> deleteSyncItem(String id) async {
    final db = await database;
    return await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  // ========== STATISTICS METHODS ==========

  Future<Map<String, int>> getStatistics() async {
    final db = await database;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM equipment');
    final inUseResult = await db.rawQuery("SELECT COUNT(*) as count FROM equipment WHERE status = 'В использовании'");
    final inStockResult = await db.rawQuery("SELECT COUNT(*) as count FROM equipment WHERE status = 'На складе'");
    final underRepairResult = await db.rawQuery("SELECT COUNT(*) as count FROM equipment WHERE status = 'В ремонте'");
    
    return {
      'total': Sqflite.firstIntValue(totalResult) ?? 0,
      'in_use': Sqflite.firstIntValue(inUseResult) ?? 0,
      'in_stock': Sqflite.firstIntValue(inStockResult) ?? 0,
      'under_repair': Sqflite.firstIntValue(underRepairResult) ?? 0,
    };
  }

  // ========== EXPORT METHODS ==========

  Future<String> exportToCSV() async {
    final equipment = await getEquipment();
    final csvData = StringBuffer();
    
    csvData.writeln('ID,Название,Тип,Серийный номер,Инвентарный номер,Статус,Ответственный,Местоположение,Дата покупки,Примечания');
    
    for (final item in equipment) {
      final row = [
        item['id']?.toString() ?? '',
        '"${item['name']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${item['type']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${item['serial_number']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${item['inventory_number']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${item['status']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${item['responsible_person']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${item['location']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${item['purchase_date']?.toString().replaceAll('"', '""') ?? ''}"',
        '"${item['notes']?.toString().replaceAll('"', '""') ?? ''}"',
      ].join(',');
      
      csvData.writeln(row);
    }
    
    return csvData.toString();
  }

  // ========== UTILITY METHODS ==========

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('equipment');
    await db.delete('employees');
    await db.delete('consumables');
    await db.delete('movements');
    await db.delete('consumable_movements');
    await db.delete('maintenance_records');
    await db.delete('maintenance_schedules');
    await db.delete('rooms');
    await db.delete('room_equipment');
    await db.delete('inventory_audits');
    await db.delete('keys');
    await db.delete('key_issue_records');
    await db.delete('phone_numbers');
    await db.delete('sim_cards');
    await db.delete('vehicles');
    await db.delete('vehicle_usage_records');
    await db.delete('vehicle_expenses');
  }

  // ========== SETTINGS METHODS ==========

  Future<Map<String, dynamic>?> getAppSettings() async {
    final db = await database;
    final results = await db.query('app_settings', where: 'id = ?', whereArgs: [1]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    final db = await database;
    settings['updated_at'] = DateTime.now().toIso8601String();
    await db.insert(
      'app_settings',
      {'id': 1, ...settings},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
