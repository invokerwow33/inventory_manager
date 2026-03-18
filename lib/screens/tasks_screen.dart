import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/permission.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import 'task_detail_screen.dart';
import 'create_task_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    // Используем addPostFrameCallback чтобы избежать вызова setState во время сборки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  Future<void> _loadTasks() async {
    final provider = context.read<TaskProvider>();
    final auth = context.read<AuthProvider>();

    // Директор (admin/manager) видит все созданные им задачи
    // Сотрудник видит задачи назначенные ему ИЛИ общие (без исполнителя)
    if (auth.isAdmin || auth.currentUser?.isManager == true) {
      await provider.loadTasks(createdBy: auth.currentUser?.id, forceRefresh: true);
    } else {
      // Сотрудник видит свои задачи или общие
      await provider.loadTasks(assignedTo: auth.currentUser?.id, forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Задачи сотрудников' : 'Мои задачи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Column(
        children: [
          // Статистика
          Consumer<TaskProvider>(
            builder: (context, provider, _) {
              final stats = provider.statistics;
              return _buildStatsBar(stats);
            },
          ),

          // Фильтры
          _buildFilterBar(),

          // Список задач
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.task_alt, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          isAdmin ? 'Нет задач' : 'Нет задач для вас',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.tasks.length,
                  itemBuilder: (context, index) {
                    final task = provider.tasks[index];
                    return _buildTaskCard(task, isAdmin);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Показываем кнопку только если есть права на создание задач
          if (!auth.hasPermission(Permission.createTask)) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateTaskScreen(),
                ),
              );
              _loadTasks();
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildStatsBar(Map<String, int> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatChip('Всего', stats['total'] ?? 0, Colors.blue),
            const SizedBox(width: 8),
            _buildStatChip('Назначены', stats['pending'] ?? 0, Colors.grey),
            const SizedBox(width: 8),
            _buildStatChip('В работе', stats['inProgress'] ?? 0, Colors.orange),
            const SizedBox(width: 8),
            _buildStatChip('Выполнены', stats['completed'] ?? 0, Colors.green),
            const SizedBox(width: 8),
            _buildStatChip('Просрочены', stats['overdue'] ?? 0, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Поиск
              TextField(
                decoration: InputDecoration(
                  hintText: 'Поиск задач...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      provider.setSearchQuery(null);
                    },
                  ),
                ),
                onChanged: (value) {
                  provider.setSearchQuery(value.isEmpty ? null : value);
                },
              ),
              const SizedBox(height: 12),
              // Фильтры по статусу и приоритету
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Фильтр по статусу
                    FilterChip(
                      label: const Text('Все статусы'),
                      selected: provider.tasks.any((t) => true) &&
                                provider.allTasks.where((t) => t.status == TaskStatus.pending).length +
                                provider.allTasks.where((t) => t.status == TaskStatus.inProgress).length +
                                provider.allTasks.where((t) => t.status == TaskStatus.completed).length ==
                                provider.allTasks.length,
                      onSelected: (selected) {
                        provider.setFilterStatus(null);
                      },
                    ),
                    const SizedBox(width: 8),
                    ...TaskStatus.values.map((status) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 6,
                                backgroundColor: status.color,
                              ),
                              const SizedBox(width: 6),
                              Text(status.label),
                            ],
                          ),
                          selected: provider.tasks.where((t) => t.status == status).isNotEmpty &&
                                    provider.allTasks.where((t) => t.status == status).length ==
                                    provider.allTasks.length,
                          onSelected: (selected) {
                            provider.setFilterStatus(selected ? status : null);
                          },
                        ),
                      );
                    }),
                    
                    const SizedBox(width: 16),
                    
                    // Фильтр по приоритету
                    FilterChip(
                      label: const Text('Все приоритеты'),
                      selected: true,
                      onSelected: (selected) {
                        provider.setFilterPriority(null);
                      },
                    ),
                    const SizedBox(width: 8),
                    ...TaskPriority.values.map((priority) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flag, size: 16, color: priority.color),
                              const SizedBox(width: 4),
                              Text(priority.label),
                            ],
                          ),
                          selected: provider.tasks.where((t) => t.priority == priority).isNotEmpty &&
                                    provider.allTasks.where((t) => t.priority == priority).length == 
                                    provider.allTasks.length,
                          onSelected: (selected) {
                            provider.setFilterPriority(selected ? priority : null);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(Task task, bool isAdmin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: task.isOverdue ? Colors.red.shade50 : null,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(task: task),
            ),
          ).then((_) => _loadTasks());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: task.priority.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.priority.label,
                      style: TextStyle(
                        color: task.priority.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!isAdmin)
                Text(
                  'От: ${task.createdByName}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              if (isAdmin && task.assignedToName != null)
                Text(
                  'Исполнитель: ${task.assignedToName}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatusChip(task.status),
                  const SizedBox(width: 8),
                  if (task.dueDate != null)
                    _buildDateChip(task.dueDate!, task.isOverdue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: status.color),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDateChip(DateTime date, bool isOverdue) {
    final days = date.difference(DateTime.now()).inDays;
    String text;
    if (days < 0) {
      text = 'Просрочено: ${DateFormat('dd.MM.yyyy').format(date)}';
    } else if (days == 0) {
      text = 'Сегодня';
    } else if (days == 1) {
      text = 'Завтра';
    } else {
      text = '$days дн. : ${DateFormat('dd.MM.yyyy').format(date)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isOverdue ? Colors.red : Colors.blue),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isOverdue ? Colors.red : Colors.blue,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
