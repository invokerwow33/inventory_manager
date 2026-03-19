import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cinema_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/event.dart';
import '../../models/cinema_hall.dart';
import '../../models/permission.dart';
import 'cinema_seat_selection_screen.dart';
import 'manage_events_screen.dart';
import 'create_screening_screen.dart';
import 'manage_cinema_halls_screen.dart';

class CinemaScreen extends StatefulWidget {
  const CinemaScreen({super.key});

  @override
  State<CinemaScreen> createState() => _CinemaScreenState();
}

class _CinemaScreenState extends State<CinemaScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cinemaProvider = context.read<CinemaProvider>();
    await cinemaProvider.loadEvents(isActive: true, forceRefresh: true);
    await cinemaProvider.loadCinemaHalls(forceRefresh: true);
    await cinemaProvider.loadScreenings(date: _selectedDate, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canManage = auth.canManageEvents || auth.canManageScreenings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Кинотеатр'),
        actions: [
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.add),
              onSelected: (value) {
                switch (value) {
                  case 'event':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageEventsScreen()),
                    );
                    break;
                  case 'screening':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateScreeningScreen()),
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'event',
                  child: Row(
                    children: [
                      Icon(Icons.movie),
                      SizedBox(width: 8),
                      Text('Мероприятие'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'screening',
                  child: Row(
                    children: [
                      Icon(Icons.schedule),
                      SizedBox(width: 8),
                      Text('Сеанс'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'halls',
                  child: Row(
                    children: [
                      Icon(Icons.meeting_room),
                      SizedBox(width: 8),
                      Text('Управление залами'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'event':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageEventsScreen()),
                    );
                    break;
                  case 'screening':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateScreeningScreen()),
                    );
                    break;
                  case 'halls':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageCinemaHallsScreen()),
                    );
                    break;
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Column(
        children: [
          // Выбор даты
          _buildDatePicker(),
          
          // Статистика
          _buildStats(),
          
          // Список сеансов
          Expanded(
            child: Consumer<CinemaProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.screenings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.movie_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'На ${DateFormat('dd.MM.yyyy').format(_selectedDate)} сеансов нет',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        if (canManage) ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showCreateScreening(),
                            icon: const Icon(Icons.add),
                            label: const Text('Создать сеанс'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.screenings.length,
                  itemBuilder: (context, index) {
                    final screening = provider.screenings[index];
                    return _buildScreeningCard(screening, auth);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Выберите дату:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (index) {
                final date = DateTime.now().add(Duration(days: index));
                final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
                    DateFormat('yyyy-MM-dd').format(_selectedDate);
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('EEE', 'ru_RU').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    onSelected: (selected) async {
                      if (selected) {
                        setState(() => _selectedDate = date);
                        await context.read<CinemaProvider>().loadScreenings(
                          date: date,
                          forceRefresh: true,
                        );
                      }
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Consumer<CinemaProvider>(
      builder: (context, provider, _) {
        final stats = provider.statistics;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildStatChip('Сеансов', stats['screenings'] ?? 0, Colors.blue),
              const SizedBox(width: 8),
              _buildStatChip('Мест', provider.screenings.fold<int>(0, (sum, s) => sum + 100), Colors.green),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildScreeningCard(Screening screening, AuthProvider auth) {
    final isToday = screening.isToday;
    final canSell = auth.canSellTickets;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isToday ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: () {
          if (canSell) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CinemaSeatSelectionScreen(screening: screening),
              ),
            );
          }
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
                      screening.eventTitle ?? 'Без названия',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Сегодня', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    screening.startTimeLabel,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    screening.hallName ?? 'Зал',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Цена от ${screening.basePrice.toStringAsFixed(0)} ₽',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (canSell)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CinemaSeatSelectionScreen(screening: screening),
                          ),
                        );
                      },
                      icon: const Icon(Icons.point_of_sale, size: 18),
                      label: const Text('Продать билеты'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
}
