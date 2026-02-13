import 'package:flutter/material.dart';
import 'package:inventory_manager/database/simple_database_helper.dart';

class EquipmentSelectionScreen extends StatefulWidget {
  final List<int> selectedEquipmentIds; // Уже выбранное оборудование
  final bool multipleSelection; // Разрешить множественный выбор
  
  const EquipmentSelectionScreen({
    Key? key,
    this.selectedEquipmentIds = const [],
    this.multipleSelection = true,
  }) : super(key: key);

  @override
  _EquipmentSelectionScreenState createState() => _EquipmentSelectionScreenState();
}

class _EquipmentSelectionScreenState extends State<EquipmentSelectionScreen> {
  final SimpleDatabaseHelper _dbHelper = SimpleDatabaseHelper();
  List<Map<String, dynamic>> _equipment = [];
  List<Map<String, dynamic>> _filteredEquipment = [];
  Set<int> _selectedIds = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedEquipmentIds);
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    setState(() => _isLoading = true);
    try {
      await _dbHelper.initDatabase();
      _equipment = await _dbHelper.getEquipment();
      _applyFilters();
    } catch (e) {
      print('Ошибка загрузки оборудования: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_equipment);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return (item['name']?.toString().toLowerCase().contains(query) ?? false) ||
               (item['serial_number']?.toString().toLowerCase().contains(query) ?? false) ||
               (item['category']?.toString().toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Сортировка по названию
    filtered.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

    setState(() => _filteredEquipment = filtered);
  }

  void _toggleSelection(Map<String, dynamic> equipment) {
    setState(() {
      final id = equipment['id'] as int;
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (widget.multipleSelection) {
          _selectedIds.add(id);
        } else {
          _selectedIds.clear();
          _selectedIds.add(id);
        }
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'В использовании':
        return Colors.green;
      case 'На складе':
        return Colors.blue;
      case 'В ремонте':
        return Colors.orange;
      case 'Списано':
        return Colors.red;
      case 'В резерве':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.multipleSelection 
            ? 'Выберите оборудование' 
            : 'Выберите оборудование'),
        actions: [
          if (_selectedIds.isNotEmpty && widget.multipleSelection)
            TextButton(
              onPressed: () {
                Navigator.pop(context, _selectedIds.toList());
              },
              child: const Text(
                'Добавить',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск оборудования...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _applyFilters();
              },
            ),
          ),
          const Divider(height: 1),

          // Счетчик выбранных
          if (widget.multipleSelection)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Выбрано: ${_selectedIds.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_selectedIds.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedIds.clear();
                        });
                      },
                      child: const Text('Сбросить'),
                    ),
                ],
              ),
            ),

          // Список оборудования
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEquipment.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredEquipment.length,
                        itemBuilder: (context, index) {
                          final equipment = _filteredEquipment[index];
                          final isSelected = _selectedIds.contains(equipment['id'] as int);
                          return _buildEquipmentItem(equipment, isSelected);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: !widget.multipleSelection && _selectedIds.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pop(context, _selectedIds.toList());
              },
              child: const Icon(Icons.check),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.devices_other,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'Оборудование не найдено',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          if (_searchQuery.isNotEmpty)
            Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Попробуйте изменить поиск',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _searchQuery = '');
                    _applyFilters();
                  },
                  child: const Text('Сбросить поиск'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEquipmentItem(Map<String, dynamic> equipment, bool isSelected) {
    final status = equipment['status']?.toString() ?? 'Не указан';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isSelected ? Colors.blue.withOpacity(0.1) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status).withOpacity(0.2),
          child: Icon(
            Icons.devices,
            color: _getStatusColor(status),
          ),
        ),
        title: Text(
          equipment['name']?.toString() ?? 'Без названия',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.blue : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Категория: ${equipment['category'] ?? 'Не указана'}'),
            if (equipment['serial_number'] != null && equipment['serial_number'].toString().isNotEmpty)
              Text('Серийный номер: ${equipment['serial_number']}'),
            Text('Статус: $status'),
            if (equipment['location'] != null && equipment['location'].toString().isNotEmpty)
              Text('Местоположение: ${equipment['location']}'),
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
        onTap: () {
          _toggleSelection(equipment);
          if (!widget.multipleSelection) {
            Navigator.pop(context, _selectedIds.toList());
          }
        },
        onLongPress: widget.multipleSelection
            ? () {
                _toggleSelection(equipment);
              }
            : null,
      ),
    );
  }
}