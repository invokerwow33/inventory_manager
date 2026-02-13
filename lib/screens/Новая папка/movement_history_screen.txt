import 'package:flutter/material.dart';
import 'package:inventory_manager/database/simple_database_helper.dart';
import 'package:inventory_manager/screens/equipment_list_screen.dart';
import 'package:intl/intl.dart';

class MovementHistoryScreen extends StatefulWidget {
  final int? equipmentId;
  final String? equipmentName;
  
  const MovementHistoryScreen({
    Key? key,
    this.equipmentId,
    this.equipmentName,
  }) : super(key: key);

  @override
  _MovementHistoryScreenState createState() => _MovementHistoryScreenState();
}

class _MovementHistoryScreenState extends State<MovementHistoryScreen> {
  final SimpleDatabaseHelper _dbHelper = SimpleDatabaseHelper();
  List<Map<String, dynamic>> _movements = [];
  bool _isLoading = true;
  String _filterType = 'Все';
  
  final List<String> _movementTypes = [
    'Все',
    'Перемещение',
    'Выдача',
    'Возврат',
    'Списание',
  ];

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    setState(() => _isLoading = true);
    try {
      await _dbHelper.initDatabase();
      
      if (widget.equipmentId != null) {
        // История конкретного оборудования
        _movements = await _dbHelper.getEquipmentMovements(widget.equipmentId!);
      } else {
        // Все перемещения
        _movements = await _dbHelper.getRecentMovements(limit: 100);
      }
      
      _applyFilter();
    } catch (e) {
      print('Ошибка загрузки перемещений: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    if (_filterType == 'Все') return;
    
    setState(() {
      _movements = _movements
          .where((movement) => movement['movement_type'] == _filterType)
          .toList();
    });
  }

  Color _getMovementColor(String type) {
    switch (type) {
      case 'Выдача':
        return Colors.blue;
      case 'Возврат':
        return Colors.green;
      case 'Списание':
        return Colors.red;
      case 'Перемещение':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getMovementIcon(String type) {
    switch (type) {
      case 'Выдача':
        return Icons.arrow_upward;
      case 'Возврат':
        return Icons.arrow_downward;
      case 'Списание':
        return Icons.delete;
      case 'Перемещение':
        return Icons.swap_horiz;
      default:
        return Icons.history;
    }
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.equipmentId != null
            ? Text('История: ${widget.equipmentName ?? "Оборудование"}')
            : const Text('История перемещений'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMovements,
            tooltip: 'Обновить',
          ),
          if (_movements.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() => _filterType = value);
                _loadMovements();
              },
              itemBuilder: (context) => _movementTypes.map((type) {
                return PopupMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              icon: const Icon(Icons.filter_alt),
              tooltip: 'Фильтр',
            ),
          if (_movements.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportMovements,
              tooltip: 'Экспорт',
            ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_movements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              widget.equipmentId != null
                  ? 'Нет истории перемещений'
                  : 'Нет записей о перемещениях',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            const Text(
              'Создайте первое перемещение',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EquipmentListScreen(),
                  ),
                );
              },
              child: const Text('Перейти к оборудованию'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Статистика
        if (widget.equipmentId == null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      count: _movements.where((m) => m['movement_type'] == 'Выдача').length,
                      label: 'Выдач',
                      color: Colors.blue,
                    ),
                    _buildStatItem(
                      count: _movements.where((m) => m['movement_type'] == 'Возврат').length,
                      label: 'Возвратов',
                      color: Colors.green,
                    ),
                    _buildStatItem(
                      count: _movements.where((m) => m['movement_type'] == 'Перемещение').length,
                      label: 'Перемещений',
                      color: Colors.orange,
                    ),
                    _buildStatItem(
                      count: _movements.where((m) => m['movement_type'] == 'Списание').length,
                      label: 'Списаний',
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Фильтр
        if (_filterType != 'Все')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Chip(
              label: Text('Фильтр: $_filterType'),
              onDeleted: () {
                setState(() => _filterType = 'Все');
                _loadMovements();
              },
              deleteIcon: const Icon(Icons.close),
            ),
          ),

        const SizedBox(height: 8),

        // Список перемещений
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadMovements,
            child: ListView.builder(
              itemCount: _movements.length,
              itemBuilder: (context, index) {
                final movement = _movements[index];
                final type = movement['movement_type']?.toString() ?? 'Перемещение';
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getMovementColor(type).withOpacity(0.1),
                      child: Icon(
                        _getMovementIcon(type),
                        color: _getMovementColor(type),
                      ),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.equipmentId == null)
                          Text(
                            movement['equipment_name']?.toString() ?? 'Неизвестное оборудование',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        Text(
                          type,
                          style: TextStyle(
                            color: _getMovementColor(type),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('От: ${movement['from_location'] ?? 'Не указано'}'),
                        Text('Кому: ${movement['to_location'] ?? 'Не указано'}'),
                        if (movement['from_responsible']?.toString().isNotEmpty ?? false)
                          Text('Отв. от: ${movement['from_responsible']}'),
                        if (movement['to_responsible']?.toString().isNotEmpty ?? false)
                          Text('Отв. кому: ${movement['to_responsible']}'),
                        Text(_formatDateTime(movement['movement_date'] ?? movement['created_at'])),
                        if (movement['document_number']?.toString().isNotEmpty ?? false)
                          Text('Док: ${movement['document_number']}'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showMovementDetails(movement);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({required int count, required String label, required Color color}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _exportMovements() async {
    try {
      final csvData = await _dbHelper.exportMovementsToCSV();
      
      // Здесь можно реализовать сохранение файла
      // или отправку по email/сохранение в хранилище
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Экспортировано ${_movements.length} записей'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
      
      print('CSV данные:\n$csvData');
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка экспорта: $e')),
      );
    }
  }

  void _showMovementDetails(Map<String, dynamic> movement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(movement['equipment_name']?.toString() ?? 'Перемещение'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Тип', movement['movement_type']),
              _buildDetailRow('Оборудование', movement['equipment_name']),
              _buildDetailRow('Откуда', movement['from_location']),
              _buildDetailRow('Куда', movement['to_location']),
              _buildDetailRow('Ответственный от', movement['from_responsible']),
              _buildDetailRow('Ответственный кому', movement['to_responsible']),
              _buildDetailRow('Дата', _formatDateTime(movement['movement_date'] ?? movement['created_at'])),
              _buildDetailRow('Номер документа', movement['document_number']),
              if (movement['notes']?.toString().isNotEmpty ?? false)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Примечания:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(movement['notes'].toString()),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? 'Не указано'),
          ),
        ],
      ),
    );
  }
}