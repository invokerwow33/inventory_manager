import 'package:flutter/material.dart';

enum NotificationChannel {
  lowStock('Низкий запас', 'notifications_low_stock', Icons.inventory_2),
  maintenance('Обслуживание', 'notifications_maintenance', Icons.build),
  overdue('Просрочено', 'notifications_overdue', Icons.warning),
  movements('Перемещения', 'notifications_movements', Icons.swap_horiz),
  system('Системные', 'notifications_system', Icons.settings),
  reports('Отчеты', 'notifications_reports', Icons.assessment),
  sync('Синхронизация', 'notifications_sync', Icons.sync);

  final String label;
  final String preferenceKey;
  final IconData icon;

  const NotificationChannel(this.label, this.preferenceKey, this.icon);
}

enum NotificationMethod {
  push('Push-уведомления', Icons.notifications, Colors.blue),
  email('Email', Icons.email, Colors.orange),
  telegram('Telegram', Icons.telegram, Colors.cyan),
  sms('SMS', Icons.sms, Colors.green);

  final String label;
  final IconData icon;
  final Color color;

  const NotificationMethod(this.label, this.icon, this.color);
}

class NotificationSettings {
  bool masterEnabled;
  Map<NotificationChannel, bool> channelSettings;
  Map<NotificationChannel, List<NotificationMethod>> channelMethods;
  String? emailAddress;
  String? telegramChatId;
  String? slackWebhook;
  TimeOfDay? quietHoursStart;
  TimeOfDay? quietHoursEnd;
  bool quietHoursEnabled;
  int lowStockThreshold;
  int maintenanceReminderDays;
  int overdueReminderDays;
  DateTime updatedAt;

  NotificationSettings({
    this.masterEnabled = true,
    Map<NotificationChannel, bool>? channelSettings,
    Map<NotificationChannel, List<NotificationMethod>>? channelMethods,
    this.emailAddress,
    this.telegramChatId,
    this.slackWebhook,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.quietHoursEnabled = false,
    this.lowStockThreshold = 3,
    this.maintenanceReminderDays = 7,
    this.overdueReminderDays = 1,
    required this.updatedAt,
  }) : 
    channelSettings = channelSettings ?? {
      NotificationChannel.lowStock: true,
      NotificationChannel.maintenance: true,
      NotificationChannel.overdue: true,
      NotificationChannel.movements: false,
      NotificationChannel.system: true,
      NotificationChannel.reports: false,
      NotificationChannel.sync: true,
    },
    channelMethods = channelMethods ?? {
      NotificationChannel.lowStock: [NotificationMethod.push],
      NotificationChannel.maintenance: [NotificationMethod.push],
      NotificationChannel.overdue: [NotificationMethod.push, NotificationMethod.email],
      NotificationChannel.movements: [NotificationMethod.push],
      NotificationChannel.system: [NotificationMethod.push],
      NotificationChannel.reports: [NotificationMethod.email],
      NotificationChannel.sync: [NotificationMethod.push],
    };

  Map<String, dynamic> toMap() {
    return {
      'master_enabled': masterEnabled,
      'channel_settings': channelSettings.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'channel_methods': channelMethods.map(
        (key, value) => MapEntry(
          key.name,
          value.map((m) => m.name).toList(),
        ),
      ),
      'email_address': emailAddress,
      'telegram_chat_id': telegramChatId,
      'slack_webhook': slackWebhook,
      'quiet_hours_start': quietHoursStart != null
          ? '${quietHoursStart!.hour}:${quietHoursStart!.minute}'
          : null,
      'quiet_hours_end': quietHoursEnd != null
          ? '${quietHoursEnd!.hour}:${quietHoursEnd!.minute}'
          : null,
      'quiet_hours_enabled': quietHoursEnabled,
      'low_stock_threshold': lowStockThreshold,
      'maintenance_reminder_days': maintenanceReminderDays,
      'overdue_reminder_days': overdueReminderDays,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null) return null;
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }

    Map<NotificationChannel, bool> parseChannels(Map<String, dynamic>? data) {
      final result = <NotificationChannel, bool>{};
      if (data == null) return result;
      for (final entry in data.entries) {
        final channel = NotificationChannel.values.firstWhere(
          (c) => c.name == entry.key,
          orElse: () => NotificationChannel.system,
        );
        result[channel] = entry.value as bool;
      }
      return result;
    }

    Map<NotificationChannel, List<NotificationMethod>> parseMethods(
      Map<String, dynamic>? data,
    ) {
      final result = <NotificationChannel, List<NotificationMethod>>{};
      if (data == null) return result;
      for (final entry in data.entries) {
        final channel = NotificationChannel.values.firstWhere(
          (c) => c.name == entry.key,
          orElse: () => NotificationChannel.system,
        );
        final methods = (entry.value as List)
            .map((m) => NotificationMethod.values.firstWhere(
                  (method) => method.name == m,
                  orElse: () => NotificationMethod.push,
                ))
            .toList();
        result[channel] = methods;
      }
      return result;
    }

    return NotificationSettings(
      masterEnabled: map['master_enabled'] ?? true,
      channelSettings: parseChannels(map['channel_settings']?.cast<String, dynamic>()),
      channelMethods: parseMethods(map['channel_methods']?.cast<String, dynamic>()),
      emailAddress: map['email_address'],
      telegramChatId: map['telegram_chat_id'],
      slackWebhook: map['slack_webhook'],
      quietHoursStart: parseTime(map['quiet_hours_start']),
      quietHoursEnd: parseTime(map['quiet_hours_end']),
      quietHoursEnabled: map['quiet_hours_enabled'] ?? false,
      lowStockThreshold: map['low_stock_threshold'] ?? 3,
      maintenanceReminderDays: map['maintenance_reminder_days'] ?? 7,
      overdueReminderDays: map['overdue_reminder_days'] ?? 1,
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool isChannelEnabled(NotificationChannel channel) {
    return masterEnabled && (channelSettings[channel] ?? false);
  }

  List<NotificationMethod> getChannelMethods(NotificationChannel channel) {
    return channelMethods[channel] ?? [NotificationMethod.push];
  }

  void setChannelEnabled(NotificationChannel channel, bool enabled) {
    channelSettings[channel] = enabled;
  }

  void setChannelMethods(NotificationChannel channel, List<NotificationMethod> methods) {
    channelMethods[channel] = methods;
  }

  bool shouldSendNotification(NotificationChannel channel, NotificationMethod method) {
    if (!isChannelEnabled(channel)) return false;
    final methods = getChannelMethods(channel);
    return methods.contains(method);
  }

  bool get isInQuietHours {
    if (!quietHoursEnabled || quietHoursStart == null || quietHoursEnd == null) {
      return false;
    }
    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = quietHoursStart!.hour * 60 + quietHoursStart!.minute;
    final endMinutes = quietHoursEnd!.hour * 60 + quietHoursEnd!.minute;

    if (startMinutes < endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  NotificationSettings copyWith({
    bool? masterEnabled,
    Map<NotificationChannel, bool>? channelSettings,
    Map<NotificationChannel, List<NotificationMethod>>? channelMethods,
    String? emailAddress,
    String? telegramChatId,
    String? slackWebhook,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    bool? quietHoursEnabled,
    int? lowStockThreshold,
    int? maintenanceReminderDays,
    int? overdueReminderDays,
    DateTime? updatedAt,
  }) {
    return NotificationSettings(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      channelSettings: channelSettings ?? this.channelSettings,
      channelMethods: channelMethods ?? this.channelMethods,
      emailAddress: emailAddress ?? this.emailAddress,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      slackWebhook: slackWebhook ?? this.slackWebhook,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      maintenanceReminderDays: maintenanceReminderDays ?? this.maintenanceReminderDays,
      overdueReminderDays: overdueReminderDays ?? this.overdueReminderDays,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ScheduledReport {
  String id;
  String name;
  String reportType;
  String frequency;
  List<int>? dayOfWeek;
  int? dayOfMonth;
  TimeOfDay time;
  List<String> recipients;
  Map<String, dynamic>? filters;
  bool isActive;
  DateTime lastSent;
  DateTime createdAt;

  ScheduledReport({
    required this.id,
    required this.name,
    required this.reportType,
    required this.frequency,
    this.dayOfWeek,
    this.dayOfMonth,
    required this.time,
    required this.recipients,
    this.filters,
    this.isActive = true,
    required this.lastSent,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'report_type': reportType,
      'frequency': frequency,
      'day_of_week': dayOfWeek?.join(','),
      'day_of_month': dayOfMonth,
      'time': '${time.hour}:${time.minute}',
      'recipients': recipients.join(','),
      'filters': filters?.toString(),
      'is_active': isActive ? 1 : 0,
      'last_sent': lastSent.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ScheduledReport.fromMap(Map<String, dynamic> map) {
    return ScheduledReport(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      reportType: map['report_type'] ?? '',
      frequency: map['frequency'] ?? 'weekly',
      dayOfWeek: map['day_of_week']?.toString().split(',').map((s) => int.tryParse(s) ?? 1).toList(),
      dayOfMonth: map['day_of_month'],
      time: TimeOfDay(
        hour: int.tryParse(map['time']?.toString().split(':')[0] ?? '9') ?? 9,
        minute: int.tryParse(map['time']?.toString().split(':')[1] ?? '0') ?? 0,
      ),
      recipients: map['recipients']?.toString().split(',') ?? [],
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      lastSent: DateTime.tryParse(map['last_sent'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get shouldRunToday {
    final now = DateTime.now();
    final currentTime = TimeOfDay.now();
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final scheduledMinutes = time.hour * 60 + time.minute;

    if (currentMinutes < scheduledMinutes) return false;

    switch (frequency) {
      case 'daily':
        return lastSent.day != now.day;
      case 'weekly':
        if (dayOfWeek == null || !dayOfWeek!.contains(now.weekday)) return false;
        return lastSent.day != now.day;
      case 'monthly':
        if (dayOfMonth == null || now.day != dayOfMonth) return false;
        return lastSent.month != now.month;
      default:
        return false;
    }
  }
}
