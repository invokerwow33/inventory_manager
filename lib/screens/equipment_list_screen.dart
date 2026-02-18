import 'package:flutter/material.dart';
import 'package:inventory_manager/models/equipment.dart';
import 'package:inventory_manager/screens/add_equipment_screen.dart';
import 'package:inventory_manager/screens/bulk_operations_screen.dart';
import 'package:inventory_manager/widgets/export_menu_button.dart';
import 'package:inventory_manager/database/database_helper.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  List<Equipment> _equipmentList = [];
  List<Equipment> _filteredList = [];
  final TextEditingController _searchController = TextEditingController();
  final List<String> _statusFilters = ['Все', 'В использовании', 'На складе', 'В ремонте', 'Списано'];
  String _selectedFilter = 'Все';
  bool _isLoading = true;
  
  // Multi-selection mode
  bool _isSelectionMode = false;
  final Set<String> _selectedEquipmentIds = {};

  @override
  void initState() {
    super.initState();
    _loadEquipment();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadEquipment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.initDatabase();
      final equipmentList = await dbHelper.getAllEquipment();
      
      setState(() {
        _equipmentList = equipmentList;
        _filteredList = equipmentList;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки оборудования: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredList = _equipmentList.where((equipment) {
        final nameMatch = equipment.name.toLowerCase().contains(query);
        final invMatch = equipment.inventoryNumber?.toLowerCase().contains(query) ?? false;
        final serialMatch = equipment.serialNumber?.toLowerCase().contains(query) ?? false;
        final locationMatch = equipment.location?.toLowerCase().contains(query) ?? false;
        final personMatch = equipment.responsiblePerson?.toLowerCase().contains(query) ?? false;
        final departmentMatch = equipment.department?.toLowerCase().contains(query) ?? false;
        
        return nameMatch || invMatch || serialMatch || locationMatch || personMatch || departmentMatch;
      }).toList();
    });
  }

  void _applyStatusFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'Все') {
        _filteredList = _equipmentList;
      } else {
        _filteredList = _equipmentList.where((equipment) {
          return equipment.status.label == filter;
        }).toList();
      }
    });
  }

  Future<void> _refreshData() async {
    await _loadEquipment();
  }

  // Метод для преобразования Equipment в Map для старого AddEquipmentScreen
  Map<String, dynamic> _equipmentToMap(Equipment equipment) {
    return {
      'id': equipment.id,
      'name': equipment.name,
      'category': equipment.type.label,
      'serial_number': equipment.serialNumber,
      'inventory_number': equipment.inventoryNumber,
      'manufacturer': equipment.manufacturer,
      'model': equipment.model,
      'purchase_date': equipment.purchaseDate?.toIso8601String(),
      'purchase_price': equipment.purchasePrice,
      'department': equipment.department,
      'responsible_person': equipment.responsiblePerson,
      'location': equipment.location,
      'status': equipment.status.label,
      'notes': equipment.notes,
      'created_at': equipment.createdAt.toIso8601String(),
      'updated_at': equipment.updatedAt.toIso8601String(),
    };
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedEquipmentIds.clear();
      }
    });
  }

  void _toggleEquipmentSelection(String id) {
    setState(() {
      if (_selectedEquipmentIds.contains(id)) {
        _selectedEquipmentIds.remove(id);
      } else {
        _selectedEquipmentIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedEquipmentIds.addAll(_filteredList.map((e) => e.id));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedEquipmentIds.clear();
    });
  }

  Future<void> _startBulkOperation() async {
    if (_selectedEquipmentIds.isEmpty) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BulkOperationsScreen(
          preselectedEquipmentIds: _selectedEquipmentIds.toList(),
        ),
      ),
    );
    
    if (result == true) {
      _refreshData();
      setState(() {
        _isSelectionMode = false;
        _selectedEquipmentIds.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode 
            ? Text('Выбрано: ${_selectedEquipmentIds.length}')
            : const Text('Оборудование'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
                tooltip: 'Отменить выбор',
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAll,
              tooltip: 'Выбрать все',
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSelection,
              tooltip: 'Снять выбор',
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _selectedEquipmentIds.isEmpty ? null : _startBulkOperation,
              tooltip: 'Массовая операция',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _toggleSelectionMode,
              tooltip: 'Режим выбора',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
              tooltip: 'Обновить данные',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEquipmentScreen(equipment: null),
                ),
              ),
              tooltip: 'Добавить оборудование',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Панель поиска и фильтров
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Поиск по оборудованию...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          onSelected: (selected) {
                            _applyStatusFilter(filter);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Индикатор загрузки или таблица
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.devices_other, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _equipmentList.isEmpty
                                  ? 'Нет оборудования'
                                  : 'Не найдено по запросу',
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            if (_equipmentList.isEmpty)
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddEquipmentScreen(equipment: null),
                                    ),
                                  );
                                },
                                child: const Text('Добавить первое оборудование'),
                              ),
                          ],
                        ),
                      )
                    : _buildEquipmentTable(),
          ),
        ],
      ),
      bottomNavigationBar: _isSelectionMode && _selectedEquipmentIds.isNotEmpty
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Выбрано: ${_selectedEquipmentIds.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _startBulkOperation,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Массовая операция'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEquipmentTable() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Название')),
            DataColumn(label: Text('Инв. номер')),
            DataColumn(label: Text('Статус')),
            DataColumn(label: Text('Местоположение')),
            DataColumn(label: Text('Ответственный')),
            DataColumn(label: Text('Действия')),
          ],
          rows: _filteredList.map((equipment) {
            final isSelected = _selectedEquipmentIds.contains(equipment.id);
            
            return DataRow(
              selected: isSelected,
              onSelectChanged: _isSelectionMode 
                  ? (_) => _toggleEquipmentSelection(equipment.id)
                  : (_) {
                      // В обычном режиме - пока ничего не делаем при выборе строки
                    },
              color: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  if (isSelected) {
                    return Colors.blue.withOpacity(0.1);
                  }
                  return null;
                },
              ),
              cells: [
                DataCell(
                  Row(
                    children: [
                      Icon(equipment.type.icon, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              equipment.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            if (equipment.manufacturer != null && equipment.model != null)
                              Text(
                                '${equipment.manufacturer} ${equipment.model}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    equipment.inventoryNumber ?? '-',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: equipment.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: equipment.status.color),
                    ),
                    child: Text(
                      equipment.status.label,
                      style: TextStyle(
                        color: equipment.status.color,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(equipment.location ?? '-'),
                ),
                DataCell(
                  Text(equipment.responsiblePerson ?? '-'),
                ),
                DataCell(
                  _isSelectionMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleEquipmentSelection(equipment.id),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () {
                                final equipmentMap = _equipmentToMap(equipment);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEquipmentScreen(equipment: equipmentMap),
                                  ),
                                ).then((result) {
                                  if (result == true) {
                                    _refreshData();
                                  }
                                });
                              },
                              tooltip: 'Редактировать',
                            ),
                            IconButton(
                              icon: const Icon(Icons.qr_code, size: 18),
                              onPressed: () {
                                // TODO: Показать QR
                              },
                              tooltip: 'Показать QR',
                            ),
                          ],
                        ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}