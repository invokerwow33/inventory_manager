import 'package:flutter/material.dart';
import 'package:inventory_manager/database/database_helper.dart';
import 'package:inventory_manager/database/simple_database_helper.dart';
import 'package:inventory_manager/screens/add_equipment_screen.dart';
import 'package:inventory_manager/screens/equipment_list_screen.dart';
import 'package:inventory_manager/screens/backup_screen.dart';
import 'package:inventory_manager/screens/qr_generator_screen.dart';
import 'package:inventory_manager/screens/qr_scanner_screen.dart';
import 'package:inventory_manager/screens/reports_screen.dart';
import 'package:inventory_manager/screens/movement_history_screen.dart';
import 'package:inventory_manager/screens/create_movement_screen.dart';
import 'package:inventory_manager/screens/consumables_list_screen.dart';
import 'package:inventory_manager/screens/employees_list_screen.dart';
import 'package:inventory_manager/screens/bulk_operations_screen.dart';
import 'package:inventory_manager/models/equipment.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalEquipment = 0;
  int _inUseCount = 0;
  int _inStockCount = 0;
  int _inRepairCount = 0;
  int _consumablesCount = 0;
  int _lowStockCount = 0;
  int _employeesCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final dbHelper = DatabaseHelper.instance;
      final simpleDb = SimpleDatabaseHelper();
      
      await Future.wait([
        dbHelper.initDatabase(),
        simpleDb.initDatabase(),
      ]);
      
      final allEquipmentData = await dbHelper.getEquipment();
      final allEquipment = allEquipmentData.map((map) => Equipment.fromMap(map)).toList();
      final consumableStats = await simpleDb.getConsumableStats();
      final employeeStats = await simpleDb.getEmployeeStats();
      
      if (mounted) {
        setState(() {
          _totalEquipment = allEquipment.length;
          _inUseCount = allEquipment.where((e) => e.status == EquipmentStatus.inUse).length;
          _inStockCount = allEquipment.where((e) => e.status == EquipmentStatus.inStock).length;
          _inRepairCount = allEquipment.where((e) => e.status == EquipmentStatus.underRepair).length;
          _consumablesCount = consumableStats['total'] ?? 0;
          _lowStockCount = consumableStats['low_stock'] ?? 0;
          _employeesCount = employeeStats['active'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки статистики: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double get _utilizationPercentage {
    if (_totalEquipment == 0) return 0;
    return (_inUseCount / _totalEquipment);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // УБИРАЕМ AppBar - навигация теперь в main.dart через NavigationRail
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Статистика
          _buildStatsCard(),
          const SizedBox(height: 16),

          // Основные функции
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Основные функции',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.start,
                  children: [
                    _buildFunctionCard(
                      icon: Icons.list,
                      title: 'Оборудование',
                      subtitle: 'Просмотр',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EquipmentListScreen(),
                          ),
                        );
                      },
                    ),
                    _buildFunctionCard(
                      icon: Icons.add,
                      title: 'Добавить',
                      subtitle: 'Новая запись',
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddEquipmentScreen(equipment: null),
                          ),
                        );
                      },
                    ),
                    _buildFunctionCard(
                      icon: Icons.qr_code,
                      title: 'QR',
                      subtitle: 'Создание кодов',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QRGeneratorScreen(),
                          ),
                        );
                      },
                    ),
                    _buildFunctionCard(
                      icon: Icons.qr_code_scanner,
                      title: 'QR',
                      subtitle: 'Сканировать QR',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QRScannerScreen(),
                          ),
                        );
                      },
                    ),
                    _buildFunctionCard(
                      icon: Icons.swap_horiz,
                      title: 'Перемещение',
                      subtitle: 'История',
                      color: Colors.deepPurple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MovementHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildFunctionCard(
                      icon: Icons.add_circle,
                      title: 'Создать',
                      subtitle: 'Новая операция',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateMovementScreen(),
                          ),
                        );
                      },
                    ),
                    _buildFunctionCard(
                      icon: Icons.inventory_2,
                      title: 'Расходники',
                      subtitle: 'Учет материалов',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ConsumablesListScreen(),
                          ),
                        );
                      },
                    ),
                    _buildFunctionCard(
                      icon: Icons.people,
                      title: 'Сотрудники',
                      subtitle: 'Карточки и выдача',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmployeesListScreen(),
                          ),
                        );
                      },
                    ),
                    _buildFunctionCard(
                      icon: Icons.select_all,
                      title: 'Массовые',
                      subtitle: 'Операции',
                      color: Colors.deepOrange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BulkOperationsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildFunctionCard(
                      icon: Icons.analytics,
                      title: 'Отчеты',
                      subtitle: 'Статистика',
                      color: Colors.indigo,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReportsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildFunctionCard(
                      icon: Icons.backup,
                      title: 'Резервное копирование',
                      subtitle: 'Импорт/Экспорт',
                      color: Colors.red,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BackupScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Быстрые действия
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Быстрые действия',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQuickActionButton(
                          icon: Icons.add,
                          label: 'Добавить',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddEquipmentScreen(equipment: null),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionButton(
                          icon: Icons.search,
                          label: 'Поиск',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EquipmentListScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionButton(
                          icon: Icons.swap_horiz,
                          label: 'Переместить',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateMovementScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionButton(
                          icon: Icons.download,
                          label: 'Экспорт',
                          onTap: _exportData,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
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
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildStatItem(
                  value: _totalEquipment.toString(),
                  label: 'Оборудование',
                  icon: Icons.devices,
                  color: Colors.blue,
                ),
                _buildStatItem(
                  value: _inUseCount.toString(),
                  label: 'В использовании',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _buildStatItem(
                  value: _inStockCount.toString(),
                  label: 'На складе',
                  icon: Icons.inventory,
                  color: Colors.orange,
                ),
                _buildStatItem(
                  value: _consumablesCount.toString(),
                  label: 'Расходники',
                  icon: Icons.inventory_2,
                  color: Colors.purple,
                ),
                _buildStatItem(
                  value: _employeesCount.toString(),
                  label: 'Сотрудники',
                  icon: Icons.people,
                  color: Colors.teal,
                ),
                if (_lowStockCount > 0)
                  _buildStatItem(
                    value: _lowStockCount.toString(),
                    label: 'Крит. остаток',
                    icon: Icons.warning,
                    color: Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _utilizationPercentage,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 8),
            Text(
              'Загруженность оборудования: ${(_utilizationPercentage * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
            color: Colors.green.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildFunctionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 180,
      height: 110,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, size: 22),
            onPressed: onTap,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _exportData() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final equipment = await dbHelper.getEquipment();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Экспорт данных (${equipment.length} записей)'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка экспорта: $e')),
      );
    }
  }
}