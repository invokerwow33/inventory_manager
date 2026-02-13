import 'package:flutter/material.dart';
import 'package:inventory_manager/database/simple_database_helper.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final SimpleDatabaseHelper _dbHelper = SimpleDatabaseHelper();
  List<Map<String, dynamic>> _equipment = [];
  Map<String, int> _stats = {};
  Map<String, int> _categoryStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _dbHelper.initDatabase();
      _equipment = await _dbHelper.getEquipment();
      _stats = await _dbHelper.getStatistics();
      _calculateCategoryStats();
    } catch (e) {
      print('Ошибка загрузки данных для отчетов: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateCategoryStats() {
    _categoryStats = {};
    for (var item in _equipment) {
      final category = item['category']?.toString().trim() ?? 'Не указана';
      final categoryName = category.isEmpty ? 'Не указана' : category;
      _categoryStats[categoryName] = (_categoryStats[categoryName] ?? 0) + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отчеты и статистика'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Обновить данные',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildReports(),
    );
  }

  Widget _buildReports() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Общая статистика
          _buildStatsCard(),
          const SizedBox(height: 20),

          // Статистика по статусам
          _buildStatusStats(),
          const SizedBox(height: 20),

          // Статистика по категориям
          _buildCategoryStats(),
          const SizedBox(height: 20),

          // Недавно добавленное оборудование
          _buildRecentEquipment(),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Общая статистика',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  value: _equipment.length.toString(),
                  label: 'Всего единиц',
                  icon: Icons.devices,
                  color: Colors.blue,
                ),
                _buildStatItem(
                  value: _stats['in_use']?.toString() ?? '0',
                  label: 'В использовании',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _buildStatItem(
                  value: _stats['in_stock']?.toString() ?? '0',
                  label: 'На складе',
                  icon: Icons.inventory,
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStatusStats() {
    final statuses = {
      'В использовании': _stats['in_use'] ?? 0,
      'На складе': _stats['in_stock'] ?? 0,
      'В ремонте': _stats['under_repair'] ?? 0,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Распределение по статусам',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...statuses.entries.map((entry) {
              final percentage = _equipment.isNotEmpty
                  ? (entry.value / _equipment.length * 100).toStringAsFixed(1)
                  : '0.0';
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text('${entry.value} ед. ($percentage%)'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _equipment.isNotEmpty
                          ? entry.value / _equipment.length
                          : 0,
                      backgroundColor: Colors.grey[200],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStats() {
    if (_categoryStats.isEmpty) {
      return Card(
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Нет данных по категориям'),
        ),
      );
    }

    final sortedCategories = _categoryStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Распределение по категориям',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...sortedCategories.take(5).map((entry) {
              final percentage = _equipment.isNotEmpty
                  ? (entry.value / _equipment.length * 100).toStringAsFixed(1)
                  : '0.0';
            
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key),
                          Text(
                            '${entry.value} ед. ($percentage%)',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _equipment.isNotEmpty
                            ? entry.value / _equipment.length
                            : 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEquipment() {
    final recentEquipment = _equipment
        .where((item) => item['created_at'] != null)
        .toList()
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'].toString());
        final dateB = DateTime.tryParse(b['created_at'].toString());
        return dateB?.compareTo(dateA ?? DateTime(1970)) ?? 0;
      });

    final recent = recentEquipment.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Недавно добавленное оборудование',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (recent.isEmpty)
              const Text('Нет недавно добавленного оборудования')
            else
              ...recent.map((item) {
                final date = DateTime.tryParse(item['created_at'].toString());
                final formattedDate = date != null
                    ? DateFormat('dd.MM.yyyy').format(date)
                    : 'Дата не указана';
                
                return ListTile(
                  leading: const Icon(Icons.devices),
                  title: Text(item['name']?.toString() ?? 'Без названия'),
                  subtitle: Text('Добавлено: $formattedDate'),
                  trailing: Text(item['status']?.toString() ?? ''),
                );
              }),
          ],
        ),
      ),
    );
  }
}