import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_manager/services/logger_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  late Future<List<LogEntry>> _logsFuture;
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _logsFuture = LoggerService().getLogs();
  }

  Future<void> _reloadLogs() async {
    setState(() {
      _logsFuture = LoggerService().getLogs();
    });
  }

  Future<void> _clearLogs() async {
    await LoggerService().clearLogs();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Логи очищены')),
    );
    await _reloadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Логи ошибок'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Очистить логи',
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: FutureBuilder<List<LogEntry>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(
              child: Text('Ошибок пока нет'),
            );
          }

          final reversedLogs = logs.reversed.toList();
          return RefreshIndicator(
            onRefresh: _reloadLogs,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reversedLogs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final log = reversedLogs[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.errorType,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(log.errorMessage),
                        const SizedBox(height: 8),
                        Text(
                          _dateFormat.format(log.timestamp),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (log.stackTrace != null && log.stackTrace!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Stack trace:',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            log.stackTrace!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontFamily: 'monospace'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
