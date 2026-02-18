import 'package:flutter/material.dart';
import 'package:inventory_manager/database/simple_database_helper.dart';
import 'package:inventory_manager/models/consumable.dart';
import 'package:inventory_manager/screens/add_consumable_screen.dart';
import 'package:inventory_manager/screens/consumable_history_screen.dart';

class ConsumablesListScreen extends StatefulWidget {
  const ConsumablesListScreen({super.key});

  @override
  State<ConsumablesListScreen> createState() => _ConsumablesListScreenState();
}

class _ConsumablesListScreenState extends State<ConsumablesListScreen> {
  final SimpleDatabaseHelper _dbHelper = SimpleDatabaseHelper();
  List<Consumable> _consumables = [];
  List<Consumable> _filteredConsumables = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  ConsumableCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadConsumables();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadConsumables() async {
    setState(() => _isLoading = true);
    try {
      await _dbHelper.initDatabase();
      final consumablesData = await _dbHelper.getConsumables();
      setState(() {
        _consumables = consumablesData.map((c) => Consumable.fromMap(c)).toList();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки расходников: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredConsumables = _consumables.where((consumable) {
        final matchesSearch = consumable.name.toLowerCase().contains(query) ||
            consumable.category.label.toLowerCase().contains(query) ||
            (consumable.supplier?.toLowerCase().contains(query) ?? false);
        
        final matchesCategory = _selectedCategory == null || 
            consumable.category == _selectedCategory;
        
        return matchesSearch && matchesCategory;
      }).toList();
      
      // Сортируем: сначала критически мало, затем по алфавиту
      _filteredConsumables.sort((a, b) {
        if (a.isLowStock && !b.isLowStock) return -1;
        if (!a.isLowStock && b.isLowStock) return 1;
        return a.name.compareTo(b.name);
      });
    });
  }

  Future<void> _refreshData() async {
    await _loadConsumables();
  }

  Future<void> _showWriteOffDialog(Consumable consumable) async {
    final quantityController = TextEditingController();
    final notesController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Списать ${consumable.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Доступно: ${consumable.quantity.toStringAsFixed(2)} ${consumable.unit.shortLabel}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Количество для списания *',
                border: const OutlineInputBorder(),
                suffixText: consumable.unit.shortLabel,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Примечания',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = double.tryParse(quantityController.text.replaceAll(',', '.'));
              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите корректное количество')),
                );
                return;
              }
              if (quantity > consumable.quantity) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Недостаточно на складе')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Списать'),
          ),
        ],
      ),
    );

    if (result == true) {
      final quantity = double.parse(quantityController.text.replaceAll(',', '.'));
      await _performWriteOff(consumable, quantity, notesController.text);
    }
  }

  Future<void> _performWriteOff(Consumable consumable, double quantity, String? notes) async {
    try {
      await _dbHelper.addConsumableMovement({
        'consumable_id': consumable.id,
        'consumable_name': consumable.name,
        'quantity': quantity,
        'operation_type': 'расход',
        'operation_date': DateTime.now().toIso8601String(),
        'notes': notes ?? 'Списание',
      });
      
      await _refreshData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Списано $quantity ${consumable.unit.shortLabel} ${consumable.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _showRestockDialog(Consumable consumable) async {
    final quantityController = TextEditingController();
    final supplierController = TextEditingController(text: consumable.supplier ?? '');
    final notesController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Приход ${consumable.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Текущий остаток: ${consumable.quantity.toStringAsFixed(2)} ${consumable.unit.shortLabel}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Количество для прихода *',
                border: const OutlineInputBorder(),
                suffixText: consumable.unit.shortLabel,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: supplierController,
              decoration: const InputDecoration(
                labelText: 'Поставщик',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Примечания',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = double.tryParse(quantityController.text.replaceAll(',', '.'));
              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите корректное количество')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Оприходовать'),
          ),
        ],
      ),
    );

    if (result == true) {
      final quantity = double.parse(quantityController.text.replaceAll(',', '.'));
      await _performRestock(consumable, quantity, supplierController.text, notesController.text);
    }
  }

  Future<void> _performRestock(Consumable consumable, double quantity, String? supplier, String? notes) async {
    try {
      await _dbHelper.addConsumableMovement({
        'consumable_id': consumable.id,
        'consumable_name': consumable.name,
        'quantity': quantity,
        'operation_type': 'приход',
        'operation_date': DateTime.now().toIso8601String(),
        'notes': notes ?? 'Приход',
      });
      
      // Обновляем поставщика если указан
      if (supplier != null && supplier.isNotEmpty) {
        final updated = consumable.copyWith(supplier: supplier);
        await _dbHelper.updateConsumable(updated.toMap());
      }
      
      await _refreshData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Оприходовано $quantity ${consumable.unit.shortLabel} ${consumable.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Расходные материалы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Обновить',
          ),
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
                    hintText: 'Поиск по названию, категории...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Все'),
                        selected: _selectedCategory == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = null;
                            _applyFilters();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...ConsumableCategory.values.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(category.label),
                            selected: _selectedCategory == category,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? category : null;
                                _applyFilters();
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Индикатор загрузки или список
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredConsumables.isEmpty
                    ? _buildEmptyState()
                    : _buildConsumablesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddConsumableScreen(),
            ),
          );
          if (result == true) {
            _refreshData();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Добавить расходник',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _consumables.isEmpty
                ? 'Нет расходных материалов'
                : 'Не найдено по запросу',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          if (_consumables.isEmpty)
            TextButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddConsumableScreen(),
                  ),
                );
                if (result == true) {
                  _refreshData();
                }
              },
              child: const Text('Добавить первый расходник'),
            ),
        ],
      ),
    );
  }

  Widget _buildConsumablesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredConsumables.length,
      itemBuilder: (context, index) {
        final consumable = _filteredConsumables[index];
        return _buildConsumableCard(consumable);
      },
    );
  }

  Widget _buildConsumableCard(Consumable consumable) {
    final isLowStock = consumable.isLowStock;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isLowStock ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: consumable.category.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    consumable.category.icon,
                    color: consumable.category.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        consumable.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        consumable.category.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLowStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Критический остаток',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Остаток',
                    '${consumable.quantity.toStringAsFixed(2)} ${consumable.unit.shortLabel}',
                    isLowStock ? Colors.red : Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Мин. остаток',
                    '${consumable.minQuantity.toStringAsFixed(2)} ${consumable.unit.shortLabel}',
                    Colors.grey,
                  ),
                ),
              ],
            ),
            if (consumable.supplier != null && consumable.supplier!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Поставщик: ${consumable.supplier}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => _showRestockDialog(consumable),
                  tooltip: 'Приход',
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.orange),
                  onPressed: () => _showWriteOffDialog(consumable),
                  tooltip: 'Списать',
                ),
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConsumableHistoryScreen(
                          consumable: consumable,
                        ),
                      ),
                    );
                  },
                  tooltip: 'История',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddConsumableScreen(consumable: consumable),
                      ),
                    );
                    if (result == true) {
                      _refreshData();
                    }
                  },
                  tooltip: 'Редактировать',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
