import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../models/equipment.dart';

class AnalyticsProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  bool _isLoading = false;
  String? _error;
  
  // Cached data
  Map<String, dynamic> _equipmentStats = {};
  Map<String, dynamic> _consumableStats = {};
  Map<String, dynamic> _movementStats = {};
  List<Map<String, dynamic>> _monthlyData = [];
  List<Map<String, dynamic>> _departmentData = [];
  List<Map<String, dynamic>> _categoryData = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get equipmentStats => _equipmentStats;
  Map<String, dynamic> get consumableStats => _consumableStats;
  Map<String, dynamic> get movementStats => _movementStats;
  List<Map<String, dynamic>> get monthlyData => _monthlyData;
  List<Map<String, dynamic>> get departmentData => _departmentData;
  List<Map<String, dynamic>> get categoryData => _categoryData;

  Future<void> loadAllStats() async {
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        loadEquipmentStats(),
        loadConsumableStats(),
        loadMovementStats(),
        loadMonthlyData(),
        loadDepartmentData(),
        loadCategoryData(),
      ]);
    } catch (e) {
      _setError('Ошибка загрузки статистики: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadEquipmentStats() async {
    try {
      final stats = await _dbHelper.getStatistics();
      final equipment = await _dbHelper.getEquipment();
      
      // Calculate additional stats
      double totalValue = 0;
      double totalCurrentValue = 0;
      
      for (final item in equipment) {
        totalValue += (item['purchase_price'] ?? 0) as double;
        totalCurrentValue += (item['current_value'] ?? item['purchase_price'] ?? 0) as double;
      }
      
      _equipmentStats = {
        ...stats,
        'totalValue': totalValue,
        'totalCurrentValue': totalCurrentValue,
        'amortization': totalValue - totalCurrentValue,
        'averageValue': equipment.isNotEmpty ? totalValue / equipment.length : 0,
      };
      
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки статистики оборудования: $e');
    }
  }

  Future<void> loadConsumableStats() async {
    try {
      final consumables = await _dbHelper.getConsumables();
      final lowStock = await _dbHelper.getLowStockConsumables();
      
      _consumableStats = {
        'total': consumables.length,
        'lowStock': lowStock.length,
        'normal': consumables.length - lowStock.length,
        'totalValue': consumables.fold<double>(
          0, 
          (sum, c) => sum + ((c['quantity'] ?? 0) * 100), // Approximate value
        ),
      };
      
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки статистики расходников: $e');
    }
  }

  Future<void> loadMovementStats() async {
    try {
      final movements = await _dbHelper.getMovements();
      
      final byType = <String, int>{};
      final byMonth = <String, int>{};
      
      for (final movement in movements) {
        final type = movement['movement_type'] as String? ?? 'Unknown';
        byType[type] = (byType[type] ?? 0) + 1;
        
        final date = DateTime.tryParse(movement['movement_date'] ?? '');
        if (date != null) {
          final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          byMonth[monthKey] = (byMonth[monthKey] ?? 0) + 1;
        }
      }
      
      _movementStats = {
        'total': movements.length,
        'byType': byType,
        'byMonth': byMonth,
      };
      
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки статистики перемещений: $e');
    }
  }

  Future<void> loadMonthlyData() async {
    try {
      final movements = await _dbHelper.getMovements();
      final equipment = await _dbHelper.getEquipment();
      
      // Group by month for the last 12 months
      final now = DateTime.now();
      final monthlyStats = <Map<String, dynamic>>[];
      
      for (int i = 11; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}';
        
        final monthMovements = movements.where((m) {
          final date = DateTime.tryParse(m['movement_date'] ?? '');
          if (date == null) return false;
          return date.year == month.year && date.month == month.month;
        }).toList();
        
        final addedEquipment = equipment.where((e) {
          final date = DateTime.tryParse(e['created_at'] ?? '');
          if (date == null) return false;
          return date.year == month.year && date.month == month.month;
        }).length;
        
        monthlyStats.add({
          'month': monthStr,
          'movements': monthMovements.length,
          'added': addedEquipment,
          'issues': monthMovements.where((m) => m['movement_type'] == 'Выдача').length,
          'returns': monthMovements.where((m) => m['movement_type'] == 'Возврат').length,
        });
      }
      
      _monthlyData = monthlyStats;
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки месячных данных: $e');
    }
  }

  Future<void> loadDepartmentData() async {
    try {
      final equipment = await _dbHelper.getEquipment();
      final employees = await _dbHelper.getEmployees();
      
      final deptStats = <String, Map<String, dynamic>>{};
      
      for (final item in equipment) {
        final dept = item['department'] as String? ?? 'Не указан';
        if (!deptStats.containsKey(dept)) {
          deptStats[dept] = {'equipment': 0, 'value': 0.0, 'employees': 0};
        }
        deptStats[dept]!['equipment'] = (deptStats[dept]!['equipment'] as int) + 1;
        deptStats[dept]!['value'] = (deptStats[dept]!['value'] as double) + 
            ((item['purchase_price'] ?? 0) as double);
      }
      
      for (final emp in employees) {
        final dept = emp['department'] as String? ?? 'Не указан';
        if (!deptStats.containsKey(dept)) {
          deptStats[dept] = {'equipment': 0, 'value': 0.0, 'employees': 0};
        }
        deptStats[dept]!['employees'] = (deptStats[dept]!['employees'] as int) + 1;
      }
      
      _departmentData = deptStats.entries.map((e) => {
        'department': e.key,
        ...e.value,
      }).toList();
      
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки данных по отделам: $e');
    }
  }

  Future<void> loadCategoryData() async {
    try {
      final equipment = await _dbHelper.getEquipment();
      
      final categoryStats = <String, Map<String, dynamic>>{};
      
      for (final item in equipment) {
        final category = item['type'] as String? ?? 'Другое';
        if (!categoryStats.containsKey(category)) {
          categoryStats[category] = {'count': 0, 'value': 0.0};
        }
        categoryStats[category]!['count'] = (categoryStats[category]!['count'] as int) + 1;
        categoryStats[category]!['value'] = (categoryStats[category]!['value'] as double) + 
            ((item['purchase_price'] ?? 0) as double);
      }
      
      _categoryData = categoryStats.entries.map((e) => {
        'category': e.key,
        ...e.value,
      }).toList();
      
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки данных по категориям: $e');
    }
  }

  // Chart data helpers
  List<PieChartSectionData> getEquipmentStatusChartData() {
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.red,
      Colors.purple,
    ];
    
    final data = <PieChartSectionData>[];
    final stats = _equipmentStats;
    
    final sections = [
      {'value': stats['in_use'] ?? 0, 'title': 'В использовании', 'color': colors[0]},
      {'value': stats['in_stock'] ?? 0, 'title': 'На складе', 'color': colors[1]},
      {'value': stats['under_repair'] ?? 0, 'title': 'В ремонте', 'color': colors[2]},
    ];
    
    int colorIndex = 0;
    for (final section in sections) {
      final value = section['value'] as int;
      if (value > 0) {
        data.add(PieChartSectionData(
          value: value.toDouble(),
          title: '$value',
          color: section['color'] as Color,
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ));
      }
      colorIndex++;
    }
    
    return data;
  }

  List<BarChartGroupData> getMonthlyMovementsChartData() {
    return _monthlyData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (data['movements'] as int).toDouble(),
            color: Colors.blue,
            width: 12,
          ),
          BarChartRodData(
            toY: (data['issues'] as int).toDouble(),
            color: Colors.orange,
            width: 12,
          ),
        ],
      );
    }).toList();
  }

  List<LineChartBarData> getEquipmentValueTrendData() {
    return [
      LineChartBarData(
        spots: _monthlyData.asMap().entries.map((entry) {
          return FlSpot(
            entry.key.toDouble(),
            (entry.value['added'] as int).toDouble(),
          );
        }).toList(),
        isCurved: true,
        color: Colors.blue,
        barWidth: 3,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.blue.withOpacity(0.2),
        ),
      ),
    ];
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
