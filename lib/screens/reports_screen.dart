import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:inventory_manager/database/simple_database_helper.dart';
import 'package:intl/intl.dart';
import '../widgets/filter_panel.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final SimpleDatabaseHelper _dbHelper = SimpleDatabaseHelper();
  List<Map<String, dynamic>> _allEquipment = [];
  List<Map<String, dynamic>> _filteredEquipment = [];
  Map<String, int> _stats = {};
  Map<String, int> _categoryStats = {};
  bool _isLoading = true;
  bool _isFiltering = false;
  
  // Текущие фильтры
  FilterCriteria _currentFilters = const FilterCriteria();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _dbHelper.initDatabase();
      _allEquipment = await _dbHelper.getEquipment();
      _filteredEquipment = List.from(_allEquipment);
      _updateStats();
    } catch (e) {
      print('Ошибка загрузки данных для отчетов: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateStats() {
    // Статистика по отфильтрованным данным
    _stats = {
      'total': _filteredEquipment.length,
      'in_use': _filteredEquipment.where((item) => item['status'] == 'В использовании').length,
      'in_stock': _filteredEquipment.where((item) => item['status'] == 'На складе').length,
      'under_repair': _filteredEquipment.where((item) => item['status'] == 'В ремонте').length,
      'written_off': _filteredEquipment.where((item) => item['status'] == 'Списано').length,
    };
    
    _categoryStats = {};
    for (var item in _filteredEquipment) {
      final category = item['category']?.toString().trim() ?? 'Не указана';
      final categoryName = category.isEmpty ? 'Не указана' : category;
      _categoryStats[categoryName] = (_categoryStats[categoryName] ?? 0) + 1;
    }
  }

  Future<void> _applyFilters(FilterCriteria filters) async {
    setState(() {
      _isFiltering = true;
      _currentFilters = filters;
    });
    
    try {
      final filtered = await _dbHelper.filterEquipment(
        category: filters.category,
        statuses: filters.statuses.isEmpty ? null : filters.statuses,
        dateFrom: filters.dateFrom,
        dateTo: filters.dateTo,
        searchQuery: filters.searchQuery.isEmpty ? null : filters.searchQuery,
      );
      
      setState(() {
        _filteredEquipment = filtered;
        _updateStats();
      });
    } catch (e) {
      print('Ошибка применения фильтров: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка применения фильтров: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isFiltering = false);
    }
  }

  void _resetFilters() {
    setState(() {
      _currentFilters = const FilterCriteria();
      _filteredEquipment = List.from(_allEquipment);
      _updateStats();
    });
  }

  Future<void> _exportToCsv() async {
    try {
      final csvData = await _dbHelper.exportEquipmentListToCSV(_filteredEquipment);
      final bytes = csvData.codeUnits;
      
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить CSV файл',
        fileName: 'equipment_report_${_timestamp()}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      
      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV файл успешно сохранен'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка экспорта CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Оборудование'];
      
      // Заголовки
      sheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Название'),
        TextCellValue('Категория'),
        TextCellValue('Серийный номер'),
        TextCellValue('Инвентарный номер'),
        TextCellValue('Статус'),
        TextCellValue('Ответственный'),
        TextCellValue('Местоположение'),
        TextCellValue('Дата покупки'),
        TextCellValue('Примечания'),
      ]);
      
      // Данные
      for (final item in _filteredEquipment) {
        sheet.appendRow([
          TextCellValue(item['id']?.toString() ?? ''),
          TextCellValue(item['name']?.toString() ?? ''),
          TextCellValue(item['category']?.toString() ?? ''),
          TextCellValue(item['serial_number']?.toString() ?? ''),
          TextCellValue(item['inventory_number']?.toString() ?? ''),
          TextCellValue(item['status']?.toString() ?? ''),
          TextCellValue(item['responsible_person']?.toString() ?? ''),
          TextCellValue(item['location']?.toString() ?? ''),
          TextCellValue(item['purchase_date']?.toString() ?? ''),
          TextCellValue(item['notes']?.toString() ?? ''),
        ]);
      }
      
      final bytes = excel.encode();
      if (bytes != null) {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Сохранить Excel файл',
          fileName: 'equipment_report_${_timestamp()}.xlsx',
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );
        
        if (result != null) {
          final file = File(result);
          await file.writeAsBytes(bytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Excel файл успешно сохранен'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка экспорта Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _timestamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Панель фильтров
          FilterPanel(
            onApplyFilters: _applyFilters,
            onResetFilters: _resetFilters,
            onExportCsv: _exportToCsv,
            onExportExcel: _exportToExcel,
            isLoading: _isFiltering,
          ),
          
          // Результаты фильтрации
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildResultsHeader(),
          ),
          
          // Статистика
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStatsCard(),
          ),
          
          // Статистика по статусам и категориям
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildStatusStats()),
                const SizedBox(width: 16),
                Expanded(child: _buildCategoryStats()),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Таблица с результатами
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildResultsTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Найдено записей: ${_filteredEquipment.length} из ${_allEquipment.length}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            if (!_currentFilters.isEmpty)
              Chip(
                label: const Text('Фильтры активны'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
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
            Wrap(
              spacing: 24,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildStatItem(
                  value: _stats['total']?.toString() ?? '0',
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
                _buildStatItem(
                  value: _stats['under_repair']?.toString() ?? '0',
                  label: 'В ремонте',
                  icon: Icons.build,
                  color: Colors.purple,
                ),
                _buildStatItem(
                  value: _stats['written_off']?.toString() ?? '0',
                  label: 'Списано',
                  icon: Icons.delete,
                  color: Colors.red,
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
      'Списано': _stats['written_off'] ?? 0,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Распределение по статусам',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...statuses.entries.map((entry) {
              final percentage = _filteredEquipment.isNotEmpty
                  ? (entry.value / _filteredEquipment.length * 100).toStringAsFixed(1)
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
                      value: _filteredEquipment.isNotEmpty
                          ? entry.value / _filteredEquipment.length
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...sortedCategories.take(5).map((entry) {
              final percentage = _filteredEquipment.isNotEmpty
                  ? (entry.value / _filteredEquipment.length * 100).toStringAsFixed(1)
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
                        widthFactor: _filteredEquipment.isNotEmpty
                            ? entry.value / _filteredEquipment.length
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

  Widget _buildResultsTable() {
    if (_filteredEquipment.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Нет данных для отображения',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Попробуйте изменить фильтры',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.table_chart, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Результаты поиска',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  'Показано: ${_filteredEquipment.length}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              horizontalMargin: 16,
              columns: const [
                DataColumn(label: Text('Название')),
                DataColumn(label: Text('Категория')),
                DataColumn(label: Text('Инв. номер')),
                DataColumn(label: Text('Статус')),
                DataColumn(label: Text('Ответственный')),
              ],
              rows: _filteredEquipment.take(50).map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item['name']?.toString() ?? 'Без названия')),
                    DataCell(Text(item['category']?.toString() ?? '-')),
                    DataCell(Text(item['inventory_number']?.toString() ?? '-')),
                    DataCell(_buildStatusBadge(item['status']?.toString() ?? '')),
                    DataCell(Text(item['responsible_person']?.toString() ?? '-')),
                  ],
                );
              }).toList(),
            ),
          ),
          if (_filteredEquipment.length > 50)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '... и еще ${_filteredEquipment.length - 50} записей',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'В использовании':
        color = Colors.green;
        break;
      case 'На складе':
        color = Colors.blue;
        break;
      case 'В ремонте':
        color = Colors.orange;
        break;
      case 'Списано':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.isEmpty ? 'Не указан' : status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
