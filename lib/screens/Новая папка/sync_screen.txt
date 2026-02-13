import 'package:flutter/material.dart';
import '../services/sync_service.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final SyncService _syncService = SyncService();
  bool _isSyncing = false;
  Map<String, dynamic> _syncStatus = {};

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    final status = await _syncService.getSyncStatus();
    setState(() {
      _syncStatus = status;
    });
  }

  Future<void> _performSync() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      await _syncService.syncWithServer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Синхронизация успешно завершена'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка синхронизации: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
      await _loadSyncStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Синхронизация'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildSyncButton(),
            const SizedBox(height: 30),
            _buildSettingsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статус синхронизации',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                _syncStatus['isOnline'] == true
                    ? Icons.wifi
                    : Icons.wifi_off,
                color: _syncStatus['isOnline'] == true
                    ? Colors.green
                    : Colors.red,
              ),
              title: const Text('Сетевое подключение'),
              subtitle: Text(
                _syncStatus['isOnline'] == true
                    ? 'Подключено'
                    : 'Не подключено',
              ),
            ),
            ListTile(
              leading: Icon(
                _syncStatus['lastSync'] != null
                    ? Icons.check_circle
                    : Icons.sync_problem,
                color: _syncStatus['lastSync'] != null
                    ? Colors.green
                    : Colors.orange,
              ),
              title: const Text('Последняя синхронизация'),
              subtitle: Text(
                _syncStatus['lastSync'] != null
                    ? '${_syncStatus['lastSync']}'
                    : 'Никогда',
              ),
            ),
            ListTile(
              leading: Icon(
                _syncStatus['hasPendingChanges'] == true
                    ? Icons.cloud_upload
                    : Icons.cloud_done,
                color: _syncStatus['hasPendingChanges'] == true
                    ? Colors.orange
                    : Colors.green,
              ),
              title: const Text('Ожидающие изменения'),
              subtitle: Text(
                _syncStatus['hasPendingChanges'] == true
                    ? 'Есть неотправленные данные'
                    : 'Все данные синхронизированы',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncButton() {
    return ElevatedButton.icon(
      icon: _isSyncing
          ? const CircularProgressIndicator(color: Colors.white)
          : const Icon(Icons.sync),
      label: Text(
        _isSyncing ? 'Синхронизация...' : 'Синхронизировать сейчас',
      ),
      onPressed: _isSyncing ? null : _performSync,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return ExpansionTile(
      title: const Text('Настройки синхронизации'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Автоматическая синхронизация'),
                subtitle: const Text('Синхронизировать каждые 30 минут'),
                value: true,
                onChanged: (value) {
                  // TODO: Реализовать настройку
                },
              ),
              SwitchListTile(
                title: const Text('Синхронизация по Wi-Fi'),
                subtitle: const Text('Только при подключении к Wi-Fi'),
                value: true,
                onChanged: (value) {
                  // TODO: Реализовать настройку
                },
              ),
              ListTile(
                title: const Text('URL сервера'),
                subtitle: const Text('http://your-server.com/api'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showServerUrlDialog();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showServerUrlDialog() {
    TextEditingController controller = TextEditingController(
      text: 'http://your-server.com/api',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('URL сервера'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Введите URL сервера',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Сохранить URL
                Navigator.pop(context);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }
}