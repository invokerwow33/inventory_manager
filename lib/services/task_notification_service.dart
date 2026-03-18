import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../database/database_helper.dart';
import '../models/task.dart';

class TaskNotificationService {
  static final TaskNotificationService _instance = TaskNotificationService._internal();
  factory TaskNotificationService() => _instance;
  TaskNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Инициализируем timezone
    tz.initializeTimeZones();

    // Настройки для Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Настройки для iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Запрашиваем разрешения
    await _requestPermissions();
    
    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    // Android 13+ требует явное разрешение
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    // iOS
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Можно добавить навигацию к задаче
    // Для этого нужно передать task_id в payload
  }

  /// Планирование уведомления о просроченной задаче
  Future<void> scheduleOverdueNotification(Task task) async {
    if (!_isInitialized) await init();

    if (task.dueDate == null) return;

    // Уведомление за 1 день до дедлайна
    final scheduledDate = task.dueDate!.subtract(const Duration(days: 1));
    
    // Не планируем в прошлом
    if (scheduledDate.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Напоминания о задачах',
      channelDescription: 'Уведомления о предстоящих дедлайнах',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      task.id.hashCode, // Уникальный ID для каждой задачи
      '📋 Задача: ${task.title}',
      'Срок выполнения: ${_formatDate(task.dueDate!)}',
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );
  }

  /// Мгновенное уведомление о просроченной задаче
  Future<void> showOverdueNotification(Task task) async {
    if (!_isInitialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'task_overdue',
      'Просроченные задачи',
      channelDescription: 'Уведомления о просроченных задачах',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Colors.red,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      task.id.hashCode + 10000, // Другой ID для мгновенных уведомлений
      '⚠️ Задача просрочена: ${task.title}',
      'Дедлайн был: ${_formatDate(task.dueDate!)}',
      details,
    );
  }

  /// Отмена уведомления при удалении/завершении задачи
  Future<void> cancelNotification(Task task) async {
    if (!_isInitialized) await init();
    await _notifications.cancel(task.id.hashCode);
    await _notifications.cancel(task.id.hashCode + 10000);
  }

  /// Проверка просроченных задач при запуске приложения
  Future<void> checkOverdueTasks() async {
    if (!_isInitialized) await init();

    final dbHelper = DatabaseHelper.instance;
    final tasks = await dbHelper.getTasks();
    
    final now = DateTime.now();
    
    for (final taskMap in tasks) {
      final task = Task.fromMap(taskMap);
      
      // Проверяем только активные задачи с дедлайном
      if (task.dueDate == null) continue;
      if (task.status == TaskStatus.completed || task.status == TaskStatus.cancelled) continue;
      
      // Если задача просрочена
      if (task.dueDate!.isBefore(now)) {
        await showOverdueNotification(task);
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} (просрочено на ${-difference} дн.)';
    } else if (difference == 0) {
      return 'сегодня';
    } else if (difference == 1) {
      return 'завтра';
    } else {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} (через $difference дн.)';
    }
  }
}
