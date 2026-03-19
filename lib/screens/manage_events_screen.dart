import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cinema_provider.dart';
import '../../models/event.dart';

class ManageEventsScreen extends StatefulWidget {
  const ManageEventsScreen({super.key});

  @override
  State<ManageEventsScreen> createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<ManageEventsScreen> {
  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    await context.read<CinemaProvider>().loadEvents(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мероприятия'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateEventDialog(),
            tooltip: 'Добавить',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Consumer<CinemaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.movie_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Нет мероприятий',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateEventDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить мероприятие'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.events.length,
            itemBuilder: (context, index) {
              final event = provider.events[index];
              return _buildEventCard(event);
            },
          );
        },
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEditEventDialog(event),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (!event.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Архив',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (event.description != null && event.description!.isNotEmpty)
                Text(
                  event.description!,
                  style: TextStyle(color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (event.genre != null) ...[
                    _buildChip(event.genre!, Icons.label),
                    const SizedBox(width: 8),
                  ],
                  if (event.ageRating != null) ...[
                    _buildChip(event.ageRating!, Icons.security),
                    const SizedBox(width: 8),
                  ],
                  if (event.durationMinutes != null)
                    Text(
                      event.durationLabel,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (event.director != null) ...[
                    Expanded(
                      child: Text(
                        'Режиссёр: ${event.director}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.blue)),
        ],
      ),
    );
  }

  void _showCreateEventDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final genreController = TextEditingController();
    final directorController = TextEditingController();
    final castController = TextEditingController();
    final ageRatingController = TextEditingController(text: '12+');
    final durationController = TextEditingController();
    final yearController = TextEditingController(text: DateTime.now().year.toString());
    bool isActive = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Новое мероприятие'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: genreController,
                        decoration: const InputDecoration(
                          labelText: 'Жанр',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: ageRatingController,
                        decoration: const InputDecoration(
                          labelText: 'Возраст',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        decoration: const InputDecoration(
                          labelText: 'Длительность (мин)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: yearController,
                        decoration: const InputDecoration(
                          labelText: 'Год',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: directorController,
                  decoration: const InputDecoration(
                    labelText: 'Режиссёр',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: castController,
                  decoration: const InputDecoration(
                    labelText: 'В ролях',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Активно'),
                  subtitle: const Text('Отображать в списке'),
                  value: isActive,
                  onChanged: (value) => setDialogState(() => isActive = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите название')),
                  );
                  return;
                }

                final event = Event(
                  id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  genre: genreController.text.trim().isEmpty
                      ? null
                      : genreController.text.trim(),
                  ageRating: ageRatingController.text.trim().isEmpty
                      ? null
                      : ageRatingController.text.trim(),
                  durationMinutes: durationController.text.trim().isEmpty
                      ? null
                      : int.tryParse(durationController.text.trim()),
                  year: yearController.text.trim().isEmpty
                      ? null
                      : int.tryParse(yearController.text.trim()),
                  director: directorController.text.trim().isEmpty
                      ? null
                      : directorController.text.trim(),
                  cast: castController.text.trim().isEmpty
                      ? null
                      : castController.text.trim(),
                  isActive: isActive,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await context.read<CinemaProvider>().createEvent(event);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEventDialog(Event event) {
    final titleController = TextEditingController(text: event.title);
    final descriptionController = TextEditingController(text: event.description ?? '');
    final genreController = TextEditingController(text: event.genre ?? '');
    final directorController = TextEditingController(text: event.director ?? '');
    final castController = TextEditingController(text: event.cast ?? '');
    final ageRatingController = TextEditingController(text: event.ageRating ?? '');
    final durationController = TextEditingController(
      text: event.durationMinutes?.toString() ?? '',
    );
    final yearController = TextEditingController(text: event.year?.toString() ?? '');
    bool isActive = event.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Редактирование'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: genreController,
                        decoration: const InputDecoration(
                          labelText: 'Жанр',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: ageRatingController,
                        decoration: const InputDecoration(
                          labelText: 'Возраст',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        decoration: const InputDecoration(
                          labelText: 'Длительность (мин)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: yearController,
                        decoration: const InputDecoration(
                          labelText: 'Год',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: directorController,
                  decoration: const InputDecoration(
                    labelText: 'Режиссёр',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: castController,
                  decoration: const InputDecoration(
                    labelText: 'В ролях',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Активно'),
                  subtitle: const Text('Отображать в списке'),
                  value: isActive,
                  onChanged: (value) => setDialogState(() => isActive = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите название')),
                  );
                  return;
                }

                final updatedEvent = event.copyWith(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  genre: genreController.text.trim().isEmpty
                      ? null
                      : genreController.text.trim(),
                  ageRating: ageRatingController.text.trim().isEmpty
                      ? null
                      : ageRatingController.text.trim(),
                  durationMinutes: durationController.text.trim().isEmpty
                      ? null
                      : int.tryParse(durationController.text.trim()),
                  year: yearController.text.trim().isEmpty
                      ? null
                      : int.tryParse(yearController.text.trim()),
                  director: directorController.text.trim().isEmpty
                      ? null
                      : directorController.text.trim(),
                  cast: castController.text.trim().isEmpty
                      ? null
                      : castController.text.trim(),
                  isActive: isActive,
                  updatedAt: DateTime.now(),
                );

                await context.read<CinemaProvider>().updateEvent(updatedEvent);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
