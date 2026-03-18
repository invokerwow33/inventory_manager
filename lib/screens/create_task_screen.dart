import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../models/permission.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';

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
    final auth = context.read<AuthProvider>();
    
    // Получаем всех пользователей (кроме текущего)
    final users = await auth.getUsers();
    final availableUsers = users.where((u) => u.id != auth.currentUser?.id && u.isActive).toList();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите исполнителя'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              // Опция "Не назначено" - задача видна всем
              ListTile(
                title: const Text('📢 Все сотрудники', style: TextStyle(fontStyle: FontStyle.italic)),
                subtitle: const Text('Задача будет видна всем пользователям'),
                leading: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.people, color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, {'id': null, 'name': null}),
              ),
              const Divider(),
              // Список пользователей
              ...availableUsers.map((user) {
                final roleLabel = user.isAdmin ? 'Админ' : (user.isManager ? 'Менеджер' : 'Пользователь');
                return ListTile(
                  title: Text(user.username),
                  subtitle: Text('${user.email ?? ''} • $roleLabel'),
                  leading: CircleAvatar(
                    child: Text(user.username.substring(0, 1).toUpperCase()),
                  ),
                  onTap: () => Navigator.pop(context, {'id': user.id, 'name': user.username}),
                );
              }),
            ],
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
      setState(() {
        _selectedEmployeeId = result['id'];
        _selectedEmployeeName = result['name'];
      });
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();

    // Проверяем, выбран ли исполнитель (опционально)
    // Если не выбран, задача будет создана без исполнителя (общая задача)
    
    try {
      final task = Task(
        id: 'task_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        createdBy: auth.currentUser!.id,
        createdByName: auth.currentUser!.username,
        assignedTo: _selectedEmployeeId, // может быть null
        assignedToName: _selectedEmployeeName, // может быть null
        priority: _priority,
        dueDate: _dueDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
        // updatedAt исключено
      );

      await taskProvider.createTask(task);
      if (mounted) {
        // Принудительно обновляем список задач с теми же параметрами
        // Директор видит только созданные им задачи
        await taskProvider.loadTasks(createdBy: auth.currentUser!.id, forceRefresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Задача создана')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('[CreateTask] Ошибка создания задачи: $e');
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
