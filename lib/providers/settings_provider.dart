import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/app_settings.dart';
import '../models/notification_settings.dart';
import '../services/audit_service.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AuditService _auditService = AuditService();
  
  AppSettings _appSettings = AppSettings(updatedAt: DateTime.now());
  NotificationSettings _notificationSettings = NotificationSettings(updatedAt: DateTime.now());
  bool _isLoading = false;
  String? _error;

  // Getters
  AppSettings get appSettings => _appSettings;
  NotificationSettings get notificationSettings => _notificationSettings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Convenience getters
  ThemeMode get themeMode => _appSettings.themeMode;
  ColorSchemeOption get colorScheme => _appSettings.colorScheme;
  LanguageOption get language => _appSettings.language;
  bool get useSystemTheme => _appSettings.useSystemTheme;
  double get fontScale => _appSettings.fontScale;
  bool get highContrast => _appSettings.highContrast;
  bool get requireLogin => _appSettings.requireLogin;
  bool get useBiometric => _appSettings.useBiometric;
  bool get enableMaintenance => _appSettings.enableMaintenance;
  bool get enableVehicleTracking => _appSettings.enableVehicleTracking;
  bool get enableTelephony => _appSettings.enableTelephony;
  bool get enableKeyManagement => _appSettings.enableKeyManagement;
  int get itemsPerPage => _appSettings.itemsPerPage;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _setLoading(true);
    try {
      // Load from database
      final dbSettings = await _dbHelper.getAppSettings();
      if (dbSettings != null) {
        final settingsJson = dbSettings['settings_json'] as String?;
        if (settingsJson != null && settingsJson.isNotEmpty && settingsJson != '{}') {
          _appSettings = AppSettings.fromMap(jsonDecode(settingsJson));
        }
      }

      // Load from SharedPreferences as fallback
      final prefs = await SharedPreferences.getInstance();
      final savedSettings = prefs.getString('app_settings');
      if (savedSettings != null) {
        _appSettings = AppSettings.fromMap(jsonDecode(savedSettings));
      }

      final savedNotifications = prefs.getString('notification_settings');
      if (savedNotifications != null) {
        _notificationSettings = NotificationSettings.fromMap(jsonDecode(savedNotifications));
      }

      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки настроек: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveAppSettings(AppSettings settings, {String? userId}) async {
    _setLoading(true);
    try {
      _appSettings = settings.copyWith(updatedAt: DateTime.now());
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_settings', jsonEncode(_appSettings.toMap()));
      
      // Save to database
      await _dbHelper.saveAppSettings({
        'settings_json': jsonEncode(_appSettings.toMap()),
      });

      if (userId != null) {
        await _auditService.logSettingsChanged(userId, 'general');
      }

      notifyListeners();
    } catch (e) {
      _setError('Ошибка сохранения настроек: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveNotificationSettings(NotificationSettings settings, {String? userId}) async {
    try {
      _notificationSettings = settings.copyWith(updatedAt: DateTime.now());
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_settings', jsonEncode(_notificationSettings.toMap()));

      if (userId != null) {
        await _auditService.logSettingsChanged(userId, 'notifications');
      }

      notifyListeners();
    } catch (e) {
      _setError('Ошибка сохранения настроек уведомлений: $e');
    }
  }

  // Theme settings
  Future<void> setThemeMode(ThemeMode mode, {String? userId}) async {
    final newSettings = _appSettings.copyWith(themeMode: mode);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setColorScheme(ColorSchemeOption scheme, {String? userId}) async {
    final newSettings = _appSettings.copyWith(colorScheme: scheme);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setUseSystemTheme(bool value, {String? userId}) async {
    final newSettings = _appSettings.copyWith(useSystemTheme: value);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setFontScale(double scale, {String? userId}) async {
    final newSettings = _appSettings.copyWith(fontScale: scale);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setHighContrast(bool value, {String? userId}) async {
    final newSettings = _appSettings.copyWith(highContrast: value);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setReduceMotion(bool value, {String? userId}) async {
    final newSettings = _appSettings.copyWith(reduceMotion: value);
    await saveAppSettings(newSettings, userId: userId);
  }

  // Language settings
  Future<void> setLanguage(LanguageOption language, {String? userId}) async {
    final newSettings = _appSettings.copyWith(language: language);
    await saveAppSettings(newSettings, userId: userId);
  }

  // Security settings
  Future<void> setRequireLogin(bool value, {String? userId}) async {
    final newSettings = _appSettings.copyWith(requireLogin: value);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setUseBiometric(bool value, {String? userId}) async {
    final newSettings = _appSettings.copyWith(useBiometric: value);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setSessionTimeout(int minutes, {String? userId}) async {
    final newSettings = _appSettings.copyWith(sessionTimeout: minutes);
    await saveAppSettings(newSettings, userId: userId);
  }

  // Feature toggles
  Future<void> setEnableMaintenance(bool value, {String? userId}) async {
    final newSettings = _appSettings.copyWith(enableMaintenance: value);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setEnableVehicleTracking(bool value, {String? userId}) async {
    final newSettings = _appSettings.copyWith(enableVehicleTracking: value);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setEnableTelephony(bool value, {String? userId}) async {
    final newSettings = _appSettings.copyWith(enableTelephony: value);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setEnableKeyManagement(bool value, {String? userId}) async {
    final newSettings = _appSettings.copyWith(enableKeyManagement: value);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setEnableGeolocation(bool value, {String? userId}) async {
    final newSettings = _appSettings.copyWith(enableGeolocation: value);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setEnableAuditLog(bool value, {String? userId}) async {
    final newSettings = _appSettings.copyWith(enableAuditLog: value);
    await saveAppSettings(newSettings, userId: userId);
  }

  // Performance settings
  Future<void> setItemsPerPage(int count, {String? userId}) async {
    final newSettings = _appSettings.copyWith(itemsPerPage: count);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setEnableVirtualScroll(bool value, {String? userId}) async {
    final newSettings = _appSettings.copyWith(enableVirtualScroll: value);
    await saveAppSettings(newSettings, userId: userId);
  }

  // Sync settings
  Future<void> setAutoSync(bool value, {String? userId}) async {
    final newSettings = _appSettings.copyWith(autoSync: value);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setSyncInterval(int minutes, {String? userId}) async {
    final newSettings = _appSettings.copyWith(syncInterval: minutes);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setOfflineMode(bool value, {String? userId}) async {
    final newSettings = _appSettings.copyWith(offlineMode: value);
    await saveAppSettings(newSettings, userId: userId);
  }

  // Database settings
  Future<void> setDatabaseType(DatabaseType type, {String? userId}) async {
    final newSettings = _appSettings.copyWith(databaseType: type);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setDatabaseConnection({
    String? host,
    int? port,
    String? database,
    String? username,
    String? password,
    String? userId,
  }) async {
    final newSettings = _appSettings.copyWith(
      dbHost: host,
      dbPort: port,
      dbName: database,
      dbUsername: username,
      dbPassword: password,
    );
    await saveAppSettings(newSettings, userId: userId);
  }

  // Backup settings
  Future<void> setAutoBackup(bool value, {String? userId}) async {
    final newSettings = _appSettings.copyWith(autoBackup: value);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setBackupInterval(int hours, {String? userId}) async {
    final newSettings = _appSettings.copyWith(backupInterval: hours);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setBackupLocation(String? path, {String? userId}) async {
    final newSettings = _appSettings.copyWith(backupLocation: path);
    await saveAppSettings(newSettings, userId: userId);
  }

  Future<void> setCloudBackup(bool value, {String? userId}) async {
    final newSettings = _appSettings.copyWith(cloudBackup: value);
    await saveAppSettings(newSettings, userId: userId);
  }

  // Notification settings helpers
  Future<void> setMasterNotificationsEnabled(bool value) async {
    final newSettings = _notificationSettings.copyWith(masterEnabled: value);
    await saveNotificationSettings(newSettings);
  }

  Future<void> setChannelEnabled(NotificationChannel channel, bool enabled) async {
    _notificationSettings.setChannelEnabled(channel, enabled);
    await saveNotificationSettings(_notificationSettings);
  }

  Future<void> setChannelMethods(NotificationChannel channel, List<NotificationMethod> methods) async {
    _notificationSettings.setChannelMethods(channel, methods);
    await saveNotificationSettings(_notificationSettings);
  }

  Future<void> setNotificationEmail(String? email) async {
    final newSettings = _notificationSettings.copyWith(emailAddress: email);
    await saveNotificationSettings(newSettings);
  }

  Future<void> setTelegramChatId(String? chatId) async {
    final newSettings = _notificationSettings.copyWith(telegramChatId: chatId);
    await saveNotificationSettings(newSettings);
  }

  Future<void> setSlackWebhook(String? webhook) async {
    final newSettings = _notificationSettings.copyWith(slackWebhook: webhook);
    await saveNotificationSettings(newSettings);
  }

  Future<void> setQuietHours({
    required bool enabled,
    TimeOfDay? start,
    TimeOfDay? end,
  }) async {
    final newSettings = _notificationSettings.copyWith(
      quietHoursEnabled: enabled,
      quietHoursStart: start,
      quietHoursEnd: end,
    );
    await saveNotificationSettings(newSettings);
  }

  // Theme builder helpers
  ThemeData getLightTheme() {
    final colorScheme = _appSettings.lightColorScheme;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      textTheme: _buildTextTheme(Brightness.light),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  ThemeData getDarkTheme() {
    final colorScheme = _appSettings.darkColorScheme;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      textTheme: _buildTextTheme(Brightness.dark),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  TextTheme _buildTextTheme(Brightness brightness) {
    final baseTextTheme = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;
    
    return baseTextTheme.copyWith(
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 16 * _appSettings.fontScale),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 14 * _appSettings.fontScale),
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: 12 * _appSettings.fontScale),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 22 * _appSettings.fontScale),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: 16 * _appSettings.fontScale),
      titleSmall: baseTextTheme.titleSmall?.copyWith(fontSize: 14 * _appSettings.fontScale),
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> resetToDefaults({String? userId}) async {
    _appSettings = AppSettings(updatedAt: DateTime.now());
    _notificationSettings = NotificationSettings(updatedAt: DateTime.now());
    await saveAppSettings(_appSettings, userId: userId);
    await saveNotificationSettings(_notificationSettings);
  }
}
