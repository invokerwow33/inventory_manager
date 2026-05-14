import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/employee.dart';
import '../providers/employee_provider.dart';
import '../screens/add_employee_screen.dart';
import '../screens/employee_detail_screen.dart';
import '../services/logger_service.dart';

class EmployeesListScreen extends StatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  State<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen> {
  final LoggerService _logger = LoggerService();
  final TextEditingController _searchController = TextEditingController();
  List<Employee> _filteredEmployees = [];
  bool _isLoading = true;
  String? _selectedDepartment;
  List<String> _departments = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<EmployeeProvider>();
      await provider.loadEmployees(forceRefresh: true);
      
      // Extract departments from loaded employees
      final depts = provider.employees
          .where((e) => e.department != null && e.department!.isNotEmpty)
          .map((e) => e.department!)
          .toSet()
          .toList();
      
      if (mounted) {
        setState(() {
          _departments = depts..sort();
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.warning('Ошибка загрузки сотрудников: $e');;
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final provider = context.read<EmployeeProvider>();
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEmployees = provider.employees.where((employee) {
        final matchesSearch = employee.fullName.toLowerCase().contains(query) ||
            (employee.position?.toLowerCase().contains(query) ?? false) ||
            (employee.employeeNumber?.toLowerCase().contains(query) ?? false);

        final matchesDepartment = _selectedDepartment == null ||
            employee.department == _selectedDepartment;

        return matchesSearch && matchesDepartment;
      }).toList();

      // Сортируем по ФИО
      _filteredEmployees.sort((a, b) => a.fullName.compareTo(b.fullName));
    });
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _addEmployee() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddEmployeeScreen()),
    );
    if (result == true && mounted) {
      await _refreshData();
    }
  }

  Future<void> _confirmDelete(Employee employee) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить сотрудника?'),
        content: Text(
          'Сотрудник "${employee.fullName}" будет помечен как неактивный. '
          'История операций сохранится.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final provider = context.read<EmployeeProvider>();
        await provider.deleteEmployee(employee.id);
        await _refreshData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Сотрудник удален')),
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
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeProvider>(
      builder: (context, provider, _) {
        final employees = provider.employees;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Сотрудники'),
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
                        hintText: 'Поиск по ФИО, должности, табельному номеру...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        ),
                      ),
                    ),
                    if (_departments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('Все отделы'),
                              selected: _selectedDepartment == null,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedDepartment = null;
                                  _applyFilters();
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ..._departments.map((department) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(department),
                                  selected: _selectedDepartment == department,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedDepartment = selected ? department : null;
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
                  ],
                ),
              ),

              // Индикатор загрузки или список
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredEmployees.isEmpty
                        ? _buildEmptyState(employees.isEmpty)
                        : _buildEmployeesList(),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addEmployee,
            tooltip: 'Добавить сотрудника',
            child: const Icon(Icons.person_add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            isEmpty
                ? 'Нет сотрудников'
                : 'Не найдено по запросу',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          if (isEmpty)
            TextButton(
              onPressed: _addEmployee,
              child: const Text('Добавить первого сотрудника'),
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = _filteredEmployees[index];
        return _buildEmployeeCard(employee);
      },
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmployeeDetailScreen(employee: employee),
            ),
          ).then((_) => _refreshData());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue.withOpacity(0.2),
                child: Text(
                  employee.initials,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (employee.displayInfo.isNotEmpty)
                      Text(
                        employee.displayInfo,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (employee.employeeNumber != null && employee.employeeNumber!.isNotEmpty)
                          _buildInfoChip(
                            Icons.badge,
                            employee.employeeNumber!,
                          ),
                        if (employee.phone != null && employee.phone!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            Icons.phone,
                            employee.phone!,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEmployeeScreen(employee: employee),
                        ),
                      );
                      if (result == true) {
                        _refreshData();
                      }
                      break;
                    case 'delete':
                      await _confirmDelete(employee);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Редактировать'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Удалить', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
