import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../models/permission.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_provider.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  TaskPriority _priority = TaskPriority.normal;
  DateTime? _dueDate;
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;

  @override
  void initState() {
    super.initState();
    
    // Проверяем права на создание задач
    final auth = context.read<AuthProvider>();
    if (!auth.hasPermission(Permission.createTask)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Нет прав для создания задач')),
          );
          Navigator.pop(context);
        }
      });
      return;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _selectEmployee() async {
    final provider = context.read<EmployeeProvider>();
    await provider.loadEmployees();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите сотрудника'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.employees.length,
            itemBuilder: (context, index) {
              final employee = provider.employees[index];
              return ListTile(
                title: Text(employee.fullName),
                subtitle: Text(employee.position ?? ''),
                onTap: () => Navigator.pop(context, employee.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    if (result != null) {
      final employee = provider.employees.firstWhere((e) => e.id == result);
      setState(() {
        _selectedEmployeeId = result;
        _selectedEmployeeName = employee.fullName;
      });
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();

    final task = Task(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      createdBy: auth.currentUser!.id,
      createdByName: auth.currentUser!.username,
      assignedTo: _selectedEmployeeId,
      assignedToName: _selectedEmployeeName,
      priority: _priority,
      dueDate: _dueDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await taskProvider.createTask(task);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Задача создана')),
        );
        Navigator.pop(context);
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
        title: const Text('Новая задача'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _createTask,
            tooltip: 'Создать',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Заголовок
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Заголовок *',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите заголовок';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Описание
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание *',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите описание';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Сотрудник
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(
                    _selectedEmployeeName ?? 'Выберите сотрудника',
                    style: TextStyle(
                      color: _selectedEmployeeName == null ? Colors.grey : null,
                    ),
                  ),
                  subtitle: const Text('Нажмите для выбора'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _selectEmployee,
                ),
              ),
              const SizedBox(height: 16),

              // Приоритет
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Приоритет',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: TaskPriority.values.map((priority) {
                          return ChoiceChip(
                            label: Text(priority.label),
                            selected: _priority == priority,
                            selectedColor: priority.color.withOpacity(0.3),
                            checkmarkColor: priority.color,
                            labelStyle: TextStyle(
                              color: priority.color,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _priority = priority);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Дедлайн
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    _dueDate == null
                        ? 'Дедлайн не установлен'
                        : 'Дедлайн: ${_dueDate!.day}.${_dueDate!.month}.${_dueDate!.year}',
                  ),
                  subtitle: const Text('Нажмите для выбора даты'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _selectDueDate,
                ),
              ),
              const SizedBox(height: 16),

              // Заметки
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Заметки (необязательно)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Кнопка создания
              ElevatedButton.icon(
                onPressed: _createTask,
                icon: const Icon(Icons.check),
                label: const Text('Создать задачу'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
