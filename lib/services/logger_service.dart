import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LogEntry {
  final DateTime timestamp;
  final String errorType;
  final String errorMessage;
  final String? stackTrace;

  const LogEntry({
    required this.timestamp,
    required this.errorType,
    required this.errorMessage,
    this.stackTrace,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'errorType': errorType,
      'errorMessage': errorMessage,
      'stackTrace': stackTrace,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      errorType: map['errorType']?.toString() ?? 'UnknownError',
      errorMessage: map['errorMessage']?.toString() ?? '',
      stackTrace: map['stackTrace']?.toString(),
    );
  }
}

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  static const String _logsKey = 'error_logs';
  static const int _maxLogs = 1000;
  static const int _maxInfoLogs = 500;

  bool _debugMode = false;

  void setDebugMode(bool enabled) {
    _debugMode = enabled;
  }

  void info(String message) {
    if (_debugMode) {
      print('[INFO] $message');
    }
  }

  void debug(String message) {
    if (_debugMode) {
      print('[DEBUG] $message');
    }
  }

  void warning(String message) {
    print('[WARNING] $message');
  }

  Future<void> logError(Object error, [StackTrace? stackTrace]) async {
    print('[ERROR] ${error.toString()}');
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = await _loadLogs(prefs);
      logs.add(
        LogEntry(
          timestamp: DateTime.now(),
          errorType: error.runtimeType.toString(),
          errorMessage: error.toString(),
          stackTrace: stackTrace?.toString(),
        ),
      );

      final trimmedLogs = logs.length > _maxLogs
          ? logs.sublist(logs.length - _maxLogs)
          : logs;

      await prefs.setString(_logsKey, _encodeLogs(trimmedLogs));
    } catch (_) {}
  }

  Future<List<LogEntry>> getLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = await _loadLogs(prefs);
      return logs;
    } catch (_) {
      return [];
    }
  }

  Future<void> clearLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_logsKey);
    } catch (_) {}
  }

  Future<List<LogEntry>> _loadLogs(SharedPreferences prefs) async {
    final rawLogs = prefs.getString(_logsKey);
    if (rawLogs == null || rawLogs.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(rawLogs);
      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(LogEntry.fromMap)
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _encodeLogs(List<LogEntry> logs) {
    return jsonEncode(logs.map((log) => log.toMap()).toList());
  }
}
