import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cinema_provider.dart';
import '../../models/cinema_hall.dart';
import 'manage_cinema_hall_seats_screen.dart';

class ManageCinemaHallsScreen extends StatefulWidget {
  const ManageCinemaHallsScreen({super.key});

  @override
  State<ManageCinemaHallsScreen> createState() => _ManageCinemaHallsScreenState();
}

class _ManageCinemaHallsScreenState extends State<ManageCinemaHallsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHalls();
    });
  }

  Future<void> _loadHalls() async {
    await context.read<CinemaProvider>().loadCinemaHalls(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Кинозалы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateHallDialog(),
            tooltip: 'Добавить зал',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHalls,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Consumer<CinemaProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.cinemaHalls.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.meeting_room, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Нет кинозалов',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateHallDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить зал'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.cinemaHalls.length,
            itemBuilder: (context, index) {
              final hall = provider.cinemaHalls[index];
              return _buildHallCard(hall);
            },
          );
        },
      ),
    );
  }

  Widget _buildHallCard(CinemaHall hall) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEditHallDialog(hall),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hall.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (!hall.isActive)
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
              if (hall.description != null && hall.description!.isNotEmpty)
                Text(
                  hall.description!,
                  style: TextStyle(color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip('${hall.totalSeats} мест', Icons.people),
                  const SizedBox(width: 8),
                  if (hall.screenWidth != null && hall.screenHeight != null) ...[
                    _buildInfoChip(
                      '${hall.screenWidth}x${hall.screenHeight}м',
                      Icons.aspect_ratio,
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (hall.projectorType != null)
                Text(
                  'Проектор: ${hall.projectorType}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              const SizedBox(height: 4),
              if (hall.soundSystem != null)
                Text(
                  'Звук: ${hall.soundSystem}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManageCinemaHallSeatsScreen(hall: hall),
                        ),
                      );
                    },
                    icon: const Icon(Icons.event_seat, size: 18),
                    label: const Text('Места'),
                  ),
                  TextButton.icon(
                    onPressed: () => _showEditHallDialog(hall),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Изменить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
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

  void _showCreateHallDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final screenWidthController = TextEditingController();
    final screenHeightController = TextEditingController();
    final projectorController = TextEditingController();
    final soundController = TextEditingController();
    final totalSeatsController = TextEditingController(text: '50');
    bool isActive = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Новый кинозал'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
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
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: screenWidthController,
                        decoration: const InputDecoration(
                          labelText: 'Ширина экрана (м)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: screenHeightController,
                        decoration: const InputDecoration(
                          labelText: 'Высота экрана (м)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: projectorController,
                  decoration: const InputDecoration(
                    labelText: 'Проектор',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: soundController,
                  decoration: const InputDecoration(
                    labelText: 'Звуковая система',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: totalSeatsController,
                  decoration: const InputDecoration(
                    labelText: 'Количество мест',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Активен'),
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
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите название')),
                  );
                  return;
                }

                final hall = CinemaHall(
                  id: 'hall_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  totalSeats: int.tryParse(totalSeatsController.text.trim()) ?? 0,
                  screenWidth: double.tryParse(screenWidthController.text.trim()),
                  screenHeight: double.tryParse(screenHeightController.text.trim()),
                  projectorType: projectorController.text.trim().isEmpty
                      ? null
                      : projectorController.text.trim(),
                  soundSystem: soundController.text.trim().isEmpty
                      ? null
                      : soundController.text.trim(),
                  isActive: isActive,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await context.read<CinemaProvider>().createCinemaHall(hall);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditHallDialog(CinemaHall hall) {
    final nameController = TextEditingController(text: hall.name);
    final descriptionController = TextEditingController(text: hall.description ?? '');
    final screenWidthController = TextEditingController(
      text: hall.screenWidth?.toString() ?? '',
    );
    final screenHeightController = TextEditingController(
      text: hall.screenHeight?.toString() ?? '',
    );
    final projectorController = TextEditingController(text: hall.projectorType ?? '');
    final soundController = TextEditingController(text: hall.soundSystem ?? '');
    final totalSeatsController = TextEditingController(text: hall.totalSeats.toString());
    bool isActive = hall.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Редактирование зала'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
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
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: screenWidthController,
                        decoration: const InputDecoration(
                          labelText: 'Ширина экрана (м)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: screenHeightController,
                        decoration: const InputDecoration(
                          labelText: 'Высота экрана (м)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: projectorController,
                  decoration: const InputDecoration(
                    labelText: 'Проектор',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: soundController,
                  decoration: const InputDecoration(
                    labelText: 'Звуковая система',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: totalSeatsController,
                  decoration: const InputDecoration(
                    labelText: 'Количество мест',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Активен'),
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
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите название')),
                  );
                  return;
                }

                final updatedHall = hall.copyWith(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  totalSeats: int.tryParse(totalSeatsController.text.trim()) ?? 0,
                  screenWidth: double.tryParse(screenWidthController.text.trim()),
                  screenHeight: double.tryParse(screenHeightController.text.trim()),
                  projectorType: projectorController.text.trim().isEmpty
                      ? null
                      : projectorController.text.trim(),
                  soundSystem: soundController.text.trim().isEmpty
                      ? null
                      : soundController.text.trim(),
                  isActive: isActive,
                  updatedAt: DateTime.now(),
                );

                await context.read<CinemaProvider>().updateCinemaHall(updatedHall);
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
