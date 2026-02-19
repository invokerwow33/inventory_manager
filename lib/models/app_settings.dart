import 'package:flutter/material.dart';

enum ColorSchemeOption {
  blue('Синий', Colors.blue),
  green('Зеленый', Colors.green),
  purple('Фиолетовый', Colors.purple),
  orange('Оранжевый', Colors.orange),
  red('Красный', Colors.red),
  teal('Бирюзовый', Colors.teal),
  pink('Розовый', Colors.pink),
  indigo('Индиго', Colors.indigo);

  final String label;
  final Color color;

  const ColorSchemeOption(this.label, this.color);

  static ColorSchemeOption fromString(String value) {
    return ColorSchemeOption.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ColorSchemeOption.blue,
    );
  }
}

enum DatabaseType {
  sqlite('SQLite (локально)', 'sqlite'),
  postgresql('PostgreSQL (сервер)', 'postgresql'),
  mysql('MySQL (сервер)', 'mysql');

  final String label;
  final String value;

  const DatabaseType(this.label, this.value);

  static DatabaseType fromString(String value) {
    return DatabaseType.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => DatabaseType.sqlite,
    );
  }
}

enum LanguageOption {
  russian('Русский', 'ru'),
  english('English', 'en');

  final String label;
  final String code;

  const LanguageOption(this.label, this.code);

  static LanguageOption fromCode(String code) {
    return LanguageOption.values.firstWhere(
      (e) => e.code == code,
      orElse: () => LanguageOption.russian,
    );
  }
}

class AppSettings {
  // Appearance
  ColorSchemeOption colorScheme;
  ThemeMode themeMode;
  bool useSystemTheme;
  double fontScale;
  bool highContrast;
  bool reduceMotion;

  // Localization
  LanguageOption language;

  // Database
  DatabaseType databaseType;
  String? dbHost;
  int? dbPort;
  String? dbName;
  String? dbUsername;
  String? dbPassword;

  // Security
  bool requireLogin;
  bool useBiometric;
  int sessionTimeout;
  bool autoLock;

  // Sync
  bool autoSync;
  int syncInterval;
  bool syncOnStartup;
  bool offlineMode;

  // Features
  bool enableAuditLog;
  bool enableBarcodeScanning;
  bool enableGeolocation;
  bool enableMaintenance;
  bool enableVehicleTracking;
  bool enableTelephony;
  bool enableKeyManagement;

  // Backup
  bool autoBackup;
  int backupInterval;
  String? backupLocation;
  bool cloudBackup;

  // Advanced
  bool developerMode;
  bool verboseLogging;
  int itemsPerPage;
  bool enableVirtualScroll;

  DateTime updatedAt;

  AppSettings({
    this.colorScheme = ColorSchemeOption.blue,
    this.themeMode = ThemeMode.system,
    this.useSystemTheme = true,
    this.fontScale = 1.0,
    this.highContrast = false,
    this.reduceMotion = false,
    this.language = LanguageOption.russian,
    this.databaseType = DatabaseType.sqlite,
    this.dbHost,
    this.dbPort,
    this.dbName,
    this.dbUsername,
    this.dbPassword,
    this.requireLogin = false,
    this.useBiometric = false,
    this.sessionTimeout = 30,
    this.autoLock = true,
    this.autoSync = true,
    this.syncInterval = 15,
    this.syncOnStartup = true,
    this.offlineMode = false,
    this.enableAuditLog = true,
    this.enableBarcodeScanning = true,
    this.enableGeolocation = false,
    this.enableMaintenance = true,
    this.enableVehicleTracking = false,
    this.enableTelephony = false,
    this.enableKeyManagement = false,
    this.autoBackup = true,
    this.backupInterval = 24,
    this.backupLocation,
    this.cloudBackup = false,
    this.developerMode = false,
    this.verboseLogging = false,
    this.itemsPerPage = 50,
    this.enableVirtualScroll = true,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'color_scheme': colorScheme.name,
      'theme_mode': themeMode.name,
      'use_system_theme': useSystemTheme,
      'font_scale': fontScale,
      'high_contrast': highContrast,
      'reduce_motion': reduceMotion,
      'language': language.code,
      'database_type': databaseType.value,
      'db_host': dbHost,
      'db_port': dbPort,
      'db_name': dbName,
      'db_username': dbUsername,
      'db_password': dbPassword,
      'require_login': requireLogin,
      'use_biometric': useBiometric,
      'session_timeout': sessionTimeout,
      'auto_lock': autoLock,
      'auto_sync': autoSync,
      'sync_interval': syncInterval,
      'sync_on_startup': syncOnStartup,
      'offline_mode': offlineMode,
      'enable_audit_log': enableAuditLog,
      'enable_barcode_scanning': enableBarcodeScanning,
      'enable_geolocation': enableGeolocation,
      'enable_maintenance': enableMaintenance,
      'enable_vehicle_tracking': enableVehicleTracking,
      'enable_telephony': enableTelephony,
      'enable_key_management': enableKeyManagement,
      'auto_backup': autoBackup,
      'backup_interval': backupInterval,
      'backup_location': backupLocation,
      'cloud_backup': cloudBackup,
      'developer_mode': developerMode,
      'verbose_logging': verboseLogging,
      'items_per_page': itemsPerPage,
      'enable_virtual_scroll': enableVirtualScroll,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      colorScheme: ColorSchemeOption.fromString(map['color_scheme'] ?? 'blue'),
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == map['theme_mode'],
        orElse: () => ThemeMode.system,
      ),
      useSystemTheme: map['use_system_theme'] ?? true,
      fontScale: map['font_scale']?.toDouble() ?? 1.0,
      highContrast: map['high_contrast'] ?? false,
      reduceMotion: map['reduce_motion'] ?? false,
      language: LanguageOption.fromCode(map['language'] ?? 'ru'),
      databaseType: DatabaseType.fromString(map['database_type'] ?? 'sqlite'),
      dbHost: map['db_host'],
      dbPort: map['db_port'],
      dbName: map['db_name'],
      dbUsername: map['db_username'],
      dbPassword: map['db_password'],
      requireLogin: map['require_login'] ?? false,
      useBiometric: map['use_biometric'] ?? false,
      sessionTimeout: map['session_timeout'] ?? 30,
      autoLock: map['auto_lock'] ?? true,
      autoSync: map['auto_sync'] ?? true,
      syncInterval: map['sync_interval'] ?? 15,
      syncOnStartup: map['sync_on_startup'] ?? true,
      offlineMode: map['offline_mode'] ?? false,
      enableAuditLog: map['enable_audit_log'] ?? true,
      enableBarcodeScanning: map['enable_barcode_scanning'] ?? true,
      enableGeolocation: map['enable_geolocation'] ?? false,
      enableMaintenance: map['enable_maintenance'] ?? true,
      enableVehicleTracking: map['enable_vehicle_tracking'] ?? false,
      enableTelephony: map['enable_telephony'] ?? false,
      enableKeyManagement: map['enable_key_management'] ?? false,
      autoBackup: map['auto_backup'] ?? true,
      backupInterval: map['backup_interval'] ?? 24,
      backupLocation: map['backup_location'],
      cloudBackup: map['cloud_backup'] ?? false,
      developerMode: map['developer_mode'] ?? false,
      verboseLogging: map['verbose_logging'] ?? false,
      itemsPerPage: map['items_per_page'] ?? 50,
      enableVirtualScroll: map['enable_virtual_scroll'] ?? true,
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Color get primaryColor => colorScheme.color;

  ColorScheme get lightColorScheme {
    return ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    );
  }

  ColorScheme get darkColorScheme {
    return ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    );
  }

  AppSettings copyWith({
    ColorSchemeOption? colorScheme,
    ThemeMode? themeMode,
    bool? useSystemTheme,
    double? fontScale,
    bool? highContrast,
    bool? reduceMotion,
    LanguageOption? language,
    DatabaseType? databaseType,
    String? dbHost,
    int? dbPort,
    String? dbName,
    String? dbUsername,
    String? dbPassword,
    bool? requireLogin,
    bool? useBiometric,
    int? sessionTimeout,
    bool? autoLock,
    bool? autoSync,
    int? syncInterval,
    bool? syncOnStartup,
    bool? offlineMode,
    bool? enableAuditLog,
    bool? enableBarcodeScanning,
    bool? enableGeolocation,
    bool? enableMaintenance,
    bool? enableVehicleTracking,
    bool? enableTelephony,
    bool? enableKeyManagement,
    bool? autoBackup,
    int? backupInterval,
    String? backupLocation,
    bool? cloudBackup,
    bool? developerMode,
    bool? verboseLogging,
    int? itemsPerPage,
    bool? enableVirtualScroll,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      colorScheme: colorScheme ?? this.colorScheme,
      themeMode: themeMode ?? this.themeMode,
      useSystemTheme: useSystemTheme ?? this.useSystemTheme,
      fontScale: fontScale ?? this.fontScale,
      highContrast: highContrast ?? this.highContrast,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      language: language ?? this.language,
      databaseType: databaseType ?? this.databaseType,
      dbHost: dbHost ?? this.dbHost,
      dbPort: dbPort ?? this.dbPort,
      dbName: dbName ?? this.dbName,
      dbUsername: dbUsername ?? this.dbUsername,
      dbPassword: dbPassword ?? this.dbPassword,
      requireLogin: requireLogin ?? this.requireLogin,
      useBiometric: useBiometric ?? this.useBiometric,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      autoLock: autoLock ?? this.autoLock,
      autoSync: autoSync ?? this.autoSync,
      syncInterval: syncInterval ?? this.syncInterval,
      syncOnStartup: syncOnStartup ?? this.syncOnStartup,
      offlineMode: offlineMode ?? this.offlineMode,
      enableAuditLog: enableAuditLog ?? this.enableAuditLog,
      enableBarcodeScanning: enableBarcodeScanning ?? this.enableBarcodeScanning,
      enableGeolocation: enableGeolocation ?? this.enableGeolocation,
      enableMaintenance: enableMaintenance ?? this.enableMaintenance,
      enableVehicleTracking: enableVehicleTracking ?? this.enableVehicleTracking,
      enableTelephony: enableTelephony ?? this.enableTelephony,
      enableKeyManagement: enableKeyManagement ?? this.enableKeyManagement,
      autoBackup: autoBackup ?? this.autoBackup,
      backupInterval: backupInterval ?? this.backupInterval,
      backupLocation: backupLocation ?? this.backupLocation,
      cloudBackup: cloudBackup ?? this.cloudBackup,
      developerMode: developerMode ?? this.developerMode,
      verboseLogging: verboseLogging ?? this.verboseLogging,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      enableVirtualScroll: enableVirtualScroll ?? this.enableVirtualScroll,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
