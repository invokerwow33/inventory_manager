import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/equipment.dart';
import '../providers/equipment_provider.dart';
import '../widgets/common/common_widgets.dart';
import 'add_equipment_screen.dart';
import 'bulk_operations_screen.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Multi-selection mode
  bool _isSelectionMode = false;
  final Set<String> _selectedEquipmentIds = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // Load equipment when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipmentProvider>().loadEquipment();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<EquipmentProvider>().search(_searchController.text);
  }

  Future<void> _refreshData() async {
    await context.read<EquipmentProvider>().loadEquipment(forceRefresh: true);
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

  void _selectAll(List<Equipment> equipmentList) {
    setState(() {
      _selectedEquipmentIds.addAll(equipmentList.map((e) => e.id));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedEquipmentIds.clear();
    });
  }

  Future<void> _deleteEquipment(Equipment equipment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердите удаление'),
        content: Text('Вы уверены, что хотите удалить "${equipment.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<EquipmentProvider>().deleteEquipment(equipment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Оборудование удалено')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления: $e')),
          );
        }
      }
    }
  }

  Map<String, dynamic> _equipmentToMap(Equipment equipment) {
    return equipment.toMap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оборудование'),
        actions: [
          if (_isSelectionMode) ...[
            TextButton.icon(
              onPressed: () => _selectAll(context.read<EquipmentProvider>().equipment),
              icon: const Icon(Icons.select_all),
              label: const Text('Все'),
            ),
            TextButton.icon(
              onPressed: _clearSelection,
              icon: const Icon(Icons.deselect),
              label: Text('${_selectedEquipmentIds.length}'),
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _selectedEquipmentIds.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BulkOperationsScreen(
                            equipmentIds: _selectedEquipmentIds.toList(),
                          ),
                        ),
                      );
                    },
              tooltip: 'Массовая операция',
            ),
          ],
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist),
            onPressed: _toggleSelectionMode,
            tooltip: _isSelectionMode ? 'Отменить' : 'Выбрать',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEquipmentScreen(),
                ),
              );
              if (result == true) {
                _refreshData();
              }
            },
            tooltip: 'Добавить оборудование',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск оборудования...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<EquipmentProvider>().clearFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
              ),
            ),
          ),
        ),
      ),
      body: Consumer<EquipmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.equipment.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final equipmentList = provider.equipment;

          if (equipmentList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.devices_other,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? 'Нет оборудования'
                        : 'Ничего не найдено',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  if (_searchController.text.isEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddEquipmentScreen(),
                          ),
                        );
                        if (result == true) {
                          _refreshData();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить оборудование'),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: equipmentList.length,
              itemBuilder: (context, index) {
                final equipment = equipmentList[index];
                final isSelected = _selectedEquipmentIds.contains(equipment.id);

                if (_isSelectionMode) {
                  return EquipmentListTile(
                    equipment: equipment,
                    isSelected: isSelected,
                    onTap: () => _toggleEquipmentSelection(equipment.id),
                  );
                }

                return EquipmentCard(
                  equipment: equipment,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEquipmentScreen(
                          equipment: _equipmentToMap(equipment),
                        ),
                      ),
                    );
                    if (result == true) {
                      _refreshData();
                    }
                  },
                  onEdit: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEquipmentScreen(
                          equipment: _equipmentToMap(equipment),
                        ),
                      ),
                    );
                    if (result == true) {
                      _refreshData();
                    }
                  },
                  onDelete: () => _deleteEquipment(equipment),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
