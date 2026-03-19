import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../models/permission.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadComments();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    await context.read<TaskProvider>().loadComments(widget.task.id);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _addComment() async {
    final message = _commentController.text.trim();
    if (message.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final comment = TaskComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: widget.task.id,
      authorId: auth.currentUser!.id,
      authorName: auth.currentUser!.username,
      message: message,
      createdAt: DateTime.now(),
    );

    try {
      await context.read<TaskProvider>().addComment(comment);
      _commentController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _changeStatus(TaskStatus status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить статус'),
        content: Text('Вы уверены, что хотите изменить статус на "${status.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Да'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final taskProvider = context.read<TaskProvider>();
        final auth = context.read<AuthProvider>();

        await taskProvider.updateTaskStatus(widget.task.id, status);

        // Добавляем системное сообщение
        await taskProvider.addSystemComment(
          widget.task.id,
          'Статус изменен на "${status.label}"',
        );

        // Обновляем список задач чтобы отобразить изменения
        if (auth.isAdmin || auth.currentUser?.isManager == true) {
          await taskProvider.loadTasks(createdBy: auth.currentUser!.id, forceRefresh: true);
        } else {
          await taskProvider.loadTasks(assignedTo: auth.currentUser!.id, forceRefresh: true);
        }

        await _loadComments();

        if (mounted) {
          Navigator.pop(context); // Закрываем экран детали
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

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: const Text('Это действие можно отменить в течение 5 секунд.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final taskProvider = context.read<TaskProvider>();
        final task = widget.task;
        
        // Сохраняем задачу для возможного восстановления
        final taskMap = task.toMap();
        
        // Удаляем задачу
        await taskProvider.deleteTask(task.id);
        
        if (mounted) {
          Navigator.pop(context); // Возвращаемся к списку задач
          
          // Показываем SnackBar с кнопкой отмены
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Задача удалена'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Отменить',
                onPressed: () async {
                  // Восстанавливаем задачу
                  final restoredTask = Task.fromMap(taskMap);
                  await taskProvider.createTask(restoredTask);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Задача восстановлена')),
                  );
                },
              ),
            ),
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
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isAdmin = auth.isAdmin;
    final isManager = user?.isManager ?? false;
    final isMyTask = widget.task.assignedTo == auth.currentUser?.id;
    final canDelete = user?.canDeleteTask ?? false;
    final canChangeStatus = isAdmin || isManager || canDelete;

    return Scaffold(
      appBar: AppBar(
        title: Text('Задача #${widget.task.id.substring(0, 8)}'),
        actions: [
          if (canChangeStatus)
            PopupMenuButton<TaskStatus>(
              icon: const Icon(Icons.more_vert),
              onSelected: _changeStatus,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: TaskStatus.pending,
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: TaskStatus.pending.color),
                      const SizedBox(width: 8),
                      const Text('Назначена'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: TaskStatus.inProgress,
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow, color: TaskStatus.inProgress.color),
                      const SizedBox(width: 8),
                      const Text('В работе'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: TaskStatus.onHold,
                  child: Row(
                    children: [
                      Icon(Icons.pause, color: TaskStatus.onHold.color),
                      const SizedBox(width: 8),
                      const Text('На паузе'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: TaskStatus.completed,
                  child: Row(
                    children: [
                      Icon(Icons.check, color: TaskStatus.completed.color),
                      const SizedBox(width: 8),
                      const Text('Выполнена'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: TaskStatus.cancelled,
                  child: Row(
                    children: [
                      Icon(Icons.close, color: TaskStatus.cancelled.color),
                      const SizedBox(width: 8),
                      const Text('Отменена'),
                    ],
                  ),
                ),
              ],
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(),
              tooltip: 'Удалить задачу',
            ),
        ],
      ),
      body: Column(
        children: [
          // Информация о задаче
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок и статус
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.task.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusChip(widget.task.status),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Приоритет
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.task.priority.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flag,
                              size: 14,
                              color: widget.task.priority.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.task.priority.label,
                              style: TextStyle(
                                color: widget.task.priority.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.task.isOverdue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning, size: 14, color: Colors.red),
                              SizedBox(width: 4),
                              Text(
                                'Просрочено',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Описание
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Описание',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(widget.task.description),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Информация
                  _buildInfoRow('Создатель', widget.task.createdByName),
                  if (widget.task.assignedToName != null)
                    _buildInfoRow('Исполнитель', widget.task.assignedToName!),
                  if (widget.task.dueDate != null)
                    _buildInfoRow(
                      'Дедлайн',
                      DateFormat('dd.MM.yyyy').format(widget.task.dueDate!),
                    ),
                  if (widget.task.startedAt != null)
                    _buildInfoRow(
                      'Начата',
                      DateFormat('dd.MM.yyyy HH:mm').format(widget.task.startedAt!),
                    ),
                  if (widget.task.completedAt != null)
                    _buildInfoRow(
                      'Завершена',
                      DateFormat('dd.MM.yyyy HH:mm').format(widget.task.completedAt!),
                    ),
                  if (widget.task.notes != null && widget.task.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lightbulb, color: Colors.amber),
                                SizedBox(width: 8),
                                Text(
                                  'Заметка от директора',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(widget.task.notes!),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Кнопки действий для сотрудника
                  if (!isAdmin && isMyTask) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Действия',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (widget.task.status == TaskStatus.pending)
                              ElevatedButton.icon(
                                onPressed: () => _changeStatus(TaskStatus.inProgress),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Начать выполнение'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            if (widget.task.status == TaskStatus.inProgress) ...[
                              ElevatedButton.icon(
                                onPressed: () => _changeStatus(TaskStatus.completed),
                                icon: const Icon(Icons.check),
                                label: const Text('Завершить задачу'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => _changeStatus(TaskStatus.onHold),
                                icon: const Icon(Icons.pause),
                                label: const Text('Приостановить'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Комментарии (чат)
                  const Text(
                    'Чат задачи',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<TaskProvider>(
                    builder: (context, provider, _) {
                      if (provider.comments.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'Нет комментариев',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      return Container(
                        constraints: const BoxConstraints(maxHeight: 400),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.comments.length,
                          itemBuilder: (context, index) {
                            final comment = provider.comments[index];
                            return _buildComment(comment, auth.currentUser!.id);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Поле ввода комментария
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Напишите сообщение...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
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
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildComment(TaskComment comment, String currentUserId) {
    if (comment.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              comment.message,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    final isMe = comment.authorId == currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                comment.authorName.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Text(
                    comment.authorName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    comment.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm dd.MM.yyyy').format(comment.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                comment.authorName.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
