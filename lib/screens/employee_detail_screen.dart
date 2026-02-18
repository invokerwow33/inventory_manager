import 'package:flutter/material.dart';
import 'package:inventory_manager/database/simple_database_helper.dart';
import 'package:inventory_manager/models/employee.dart';
import 'package:inventory_manager/screens/add_employee_screen.dart';
import 'package:inventory_manager/screens/create_movement_screen.dart';
import 'package:intl/intl.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Employee employee;
  
  const EmployeeDetailScreen({super.key, required this.employee});
  
  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> 
    with SingleTickerProviderStateMixin {
  final SimpleDatabaseHelper _dbHelper = SimpleDatabaseHelper();
  late TabController _tabController;
  List<Map<String, dynamic>> _movements = [];
  bool _isLoadingMovements = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    setState(() => _isLoadingMovements = true);
    try {
      await _dbHelper.initDatabase();
      final movements = await _dbHelper.getEmployeeMovements(widget.employee.id);
      setState(() {
        _movements = movements;
        _isLoadingMovements = false;
      });
    } catch (e) {
      print('Ошибка загрузки движений: $e');
      setState(() => _isLoadingMovements = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка сотрудника'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEmployeeScreen(employee: widget.employee),
                ),
              );
              if (result == true && mounted) {
                Navigator.pop(context);
              }
            },
            tooltip: 'Редактировать',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Информация'),
            Tab(icon: Icon(Icons.devices), text: 'Оборудование'),
            Tab(icon: Icon(Icons.history), text: 'История'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildEquipmentTab(),
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateMovementScreen(
                preselectedResponsible: widget.employee.fullName,
              ),
            ),
          ).then((_) => _loadMovements());
        },
        icon: const Icon(Icons.add),
        label: const Text('Выдать оборудование'),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Аватар и ФИО
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    child: Text(
                      widget.employee.initials,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.employee.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.employee.displayInfo.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.employee.displayInfo,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Детальная информация
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Контактная информация',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  if (widget.employee.employeeNumber != null)
                    _buildInfoRow(Icons.badge, 'Табельный номер', widget.employee.employeeNumber!),
                  
                  if (widget.employee.email != null)
                    _buildInfoRow(Icons.email, 'Email', widget.employee.email!),
                  
                  if (widget.employee.phone != null)
                    _buildInfoRow(Icons.phone, 'Телефон', widget.employee.phone!),
                  
                  if (widget.employee.department != null)
                    _buildInfoRow(Icons.business, 'Отдел', widget.employee.department!),
                  
                  if (widget.employee.position != null)
                    _buildInfoRow(Icons.work, 'Должность', widget.employee.position!),
                  
                  const Divider(height: 32),
                  
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Добавлен',
                    DateFormat('dd.MM.yyyy').format(widget.employee.createdAt),
                  ),
                ],
              ),
            ),
          ),
          
          if (widget.employee.notes != null && widget.employee.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Примечания',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.employee.notes!),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentTab() {
    if (_isLoadingMovements) {
      return const Center(child: CircularProgressIndicator());
    }

    // Фильтруем выдачи этому сотруднику
    final issuedEquipment = _movements.where((m) {
      final toResponsible = m['to_responsible']?.toString().toLowerCase() ?? '';
      return toResponsible.contains(widget.employee.fullName.toLowerCase()) &&
             m['movement_type'] == 'Выдача';
    }).toList();

    // Фильтруем возвраты от этого сотрудника
    final returnedEquipment = _movements.where((m) {
      final fromResponsible = m['from_responsible']?.toString().toLowerCase() ?? '';
      return fromResponsible.contains(widget.employee.fullName.toLowerCase()) &&
             m['movement_type'] == 'Возврат';
    }).toList();

    // Получаем ID оборудования, которое было возвращено
    final returnedEquipmentIds = returnedEquipment
        .map((m) => m['equipment_id']?.toString())
        .where((id) => id != null)
        .toSet();

    // Фильтруем только активное оборудование (выдано, но не возвращено)
    final activeEquipment = issuedEquipment.where((m) {
      final equipmentId = m['equipment_id']?.toString();
      return equipmentId != null && !returnedEquipmentIds.contains(equipmentId);
    }).toList();

    if (activeEquipment.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.devices, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Нет активного оборудования',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateMovementScreen(
                      preselectedResponsible: widget.employee.fullName,
                    ),
                  ),
                ).then((_) => _loadMovements());
              },
              icon: const Icon(Icons.add),
              label: const Text('Выдать оборудование'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeEquipment.length,
      itemBuilder: (context, index) {
        final movement = activeEquipment[index];
        return _buildEquipmentCard(movement);
      },
    );
  }

  Widget _buildEquipmentCard(Map<String, dynamic> movement) {
    final issueDate = DateTime.tryParse(movement['movement_date'] ?? '') ?? DateTime.now();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.devices),
        ),
        title: Text(movement['equipment_name'] ?? 'Неизвестное оборудование'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Инв. номер: ${movement['equipment_id'] ?? '-'}'),
            Text('Выдано: ${DateFormat('dd.MM.yyyy').format(issueDate)}'),
            if (movement['document_number'] != null && movement['document_number'].toString().isNotEmpty)
              Text('Документ: ${movement['document_number']}'),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.assignment_return, color: Colors.blue),
          onPressed: () {
            // TODO: Быстрый возврат оборудования
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Возврат оборудования - в разработке')),
            );
          },
          tooltip: 'Вернуть оборудование',
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingMovements) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_movements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Нет истории операций',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _movements.length,
      itemBuilder: (context, index) {
        final movement = _movements[index];
        return _buildHistoryCard(movement);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> movement) {
    final movementType = movement['movement_type']?.toString() ?? 'Перемещение';
    final date = DateTime.tryParse(movement['movement_date'] ?? '') ?? DateTime.now();
    
    IconData icon;
    Color color;
    
    switch (movementType) {
      case 'Выдача':
        icon = Icons.arrow_forward;
        color = Colors.green;
        break;
      case 'Возврат':
        icon = Icons.arrow_back;
        color = Colors.blue;
        break;
      case 'Списание':
        icon = Icons.delete;
        color = Colors.red;
        break;
      default:
        icon = Icons.swap_horiz;
        color = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(movement['equipment_name'] ?? 'Неизвестное оборудование'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    movementType,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd.MM.yyyy').format(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (movement['from_location'] != null && movement['from_location'].toString().isNotEmpty)
              Text('Откуда: ${movement['from_location']}'),
            if (movement['to_location'] != null && movement['to_location'].toString().isNotEmpty)
              Text('Куда: ${movement['to_location']}'),
            if (movement['document_number'] != null && movement['document_number'].toString().isNotEmpty)
              Text('Документ: ${movement['document_number']}'),
          ],
        ),
        isThreeLine: false,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
