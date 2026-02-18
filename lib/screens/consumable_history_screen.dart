import 'package:flutter/material.dart';
import 'package:inventory_manager/database/simple_database_helper.dart';
import 'package:inventory_manager/models/consumable.dart';
import 'package:intl/intl.dart';

class ConsumableHistoryScreen extends StatefulWidget {
  final Consumable consumable;
  
  const ConsumableHistoryScreen({super.key, required this.consumable});
  
  @override
  State<ConsumableHistoryScreen> createState() => _ConsumableHistoryScreenState();
}

class _ConsumableHistoryScreenState extends State<ConsumableHistoryScreen> {
  final SimpleDatabaseHelper _dbHelper = SimpleDatabaseHelper();
  List<Map<String, dynamic>> _movements = [];
  bool _isLoading = true;
  String? _filterType;

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    setState(() => _isLoading = true);
    try {
      await _dbHelper.initDatabase();
      final movements = await _dbHelper.getConsumableMovements(widget.consumable.id);
      setState(() {
        _movements = movements;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки истории: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredMovements {
    if (_filterType == null) return _movements;
    return _movements.where((m) => m['operation_type'] == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('История: ${widget.consumable.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMovements,
          ),
        ],
      ),
      body: Column(
        children: [
          // Информация о расходнике
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.consumable.category.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.consumable.category.icon,
                      color: widget.consumable.category.color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.consumable.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.consumable.category.label,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStatChip(
                              'Остаток: ${widget.consumable.quantity.toStringAsFixed(2)} ${widget.consumable.unit.shortLabel}',
                              widget.consumable.isLowStock ? Colors.red : Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Фильтры
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Все операции'),
                  selected: _filterType == null,
                  onSelected: (selected) {
                    setState(() => _filterType = null);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Приход'),
                  selected: _filterType == 'приход',
                  onSelected: (selected) {
                    setState(() => _filterType = selected ? 'приход' : null);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Расход'),
                  selected: _filterType == 'расход',
                  onSelected: (selected) {
                    setState(() => _filterType = selected ? 'расход' : null);
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Список операций
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMovements.isEmpty
                    ? _buildEmptyState()
                    : _buildMovementsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Нет операций',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'История прихода и расхода будет отображаться здесь',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredMovements.length,
      itemBuilder: (context, index) {
        final movement = _filteredMovements[index];
        return _buildMovementCard(movement);
      },
    );
  }

  Widget _buildMovementCard(Map<String, dynamic> movement) {
    final isIncoming = movement['operation_type'] == 'приход';
    final quantity = (movement['quantity'] ?? 0).toDouble();
    final date = DateTime.tryParse(movement['created_at'] ?? '') ?? DateTime.now();
    final operationDate = DateTime.tryParse(movement['operation_date'] ?? '') ?? date;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncoming ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
          child: Icon(
            isIncoming ? Icons.add : Icons.remove,
            color: isIncoming ? Colors.green : Colors.orange,
          ),
        ),
        title: Row(
          children: [
            Text(
              '${isIncoming ? '+' : '-'} ${quantity.toStringAsFixed(2)} ${widget.consumable.unit.shortLabel}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isIncoming ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isIncoming ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isIncoming ? 'Приход' : 'Расход',
                style: TextStyle(
                  fontSize: 12,
                  color: isIncoming ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('dd.MM.yyyy HH:mm').format(operationDate),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            if (movement['employee_name'] != null && movement['employee_name'].toString().isNotEmpty)
              Text(
                'Сотрудник: ${movement['employee_name']}',
                style: const TextStyle(fontSize: 12),
              ),
            if (movement['document_number'] != null && movement['document_number'].toString().isNotEmpty)
              Text(
                'Документ: ${movement['document_number']}',
                style: const TextStyle(fontSize: 12),
              ),
            if (movement['notes'] != null && movement['notes'].toString().isNotEmpty)
              Text(
                'Примечания: ${movement['notes']}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        isThreeLine: false,
      ),
    );
  }
}
