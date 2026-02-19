import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audit_service.dart';
import '../models/audit_log.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final AuditService _auditService = AuditService();
  List<AuditLog> _logs = [];
  bool _isLoading = false;
  int _currentPage = 0;
  static const int _pageSize = 50;

  AuditEntityType? _selectedEntityType;
  AuditActionType? _selectedActionType;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _auditService.getAuditLogs(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        entityType: _selectedEntityType,
        actionType: _selectedActionType,
        fromDate: _fromDate,
        toDate: _toDate,
      );
      setState(() {
        _logs = logs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Журнал действий'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters chips
          if (_selectedEntityType != null || _selectedActionType != null || _fromDate != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedEntityType != null)
                    Chip(
                      label: Text(_selectedEntityType!.label),
                      onDeleted: () {
                        setState(() => _selectedEntityType = null);
                        _loadLogs();
                      },
                    ),
                  if (_selectedActionType != null)
                    Chip(
                      label: Text(_selectedActionType!.label),
                      onDeleted: () {
                        setState(() => _selectedActionType = null);
                        _loadLogs();
                      },
                    ),
                ],
              ),
            ),

          // Logs list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(child: Text('Нет записей'))
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return _AuditLogTile(log: log);
                        },
                      ),
          ),

          // Pagination
          if (!_isLoading && _logs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0
                        ? () {
                            setState(() => _currentPage--);
                            _loadLogs();
                          }
                        : null,
                  ),
                  Text('Страница ${_currentPage + 1}'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _logs.length == _pageSize
                        ? () {
                            setState(() => _currentPage++);
                            _loadLogs();
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<AuditEntityType>(
              decoration: const InputDecoration(labelText: 'Тип объекта'),
              value: _selectedEntityType,
              items: AuditEntityType.values.map((type) =>
                DropdownMenuItem(
                  value: type,
                  child: Text(type.label),
                ),
              ).toList(),
              onChanged: (value) => setState(() => _selectedEntityType = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AuditActionType>(
              decoration: const InputDecoration(labelText: 'Действие'),
              value: _selectedActionType,
              items: AuditActionType.values.map((type) =>
                DropdownMenuItem(
                  value: type,
                  child: Text(type.label),
                ),
              ).toList(),
              onChanged: (value) => setState(() => _selectedActionType = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _loadLogs();
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  void _exportLogs() {
    // Export logs to CSV/Excel
  }
}

class _AuditLogTile extends StatelessWidget {
  final AuditLog log;

  const _AuditLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: log.actionColor.withOpacity(0.2),
        child: Icon(log.actionIcon, color: log.actionColor, size: 20),
      ),
      title: Text('${log.actionLabel}: ${log.entityName ?? log.entityId}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${log.entityLabel} • ${log.username ?? 'Система'}'),
          if (log.description != null)
            Text(log.description!, style: Theme.of(context).textTheme.bodySmall),
          Text(
            log.formattedTimestamp,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
      isThreeLine: log.description != null,
    );
  }
}
