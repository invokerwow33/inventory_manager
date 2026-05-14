import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cinema_provider.dart';
import '../../models/event.dart';
import '../../models/cinema_hall.dart';
import '../services/logger_service.dart';

class CreateScreeningScreen extends StatefulWidget {
  const CreateScreeningScreen({super.key});

  @override
  State<CreateScreeningScreen> createState() => _CreateScreeningScreenState();
}

class _CreateScreeningScreenState extends State<CreateScreeningScreen> {
  final LoggerService _logger = LoggerService();
  Event? _selectedEvent;
  CinemaHall? _selectedHall;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final _basePriceController = TextEditingController(text: '250');
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<CinemaProvider>();
    await provider.loadEvents(isActive: true);
    await provider.loadCinemaHalls();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый сеанс'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _createScreening,
            tooltip: 'Создать',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Выбор мероприятия
            Card(
              child: ListTile(
                leading: const Icon(Icons.movie, color: Colors.blue),
                title: Text(
                  _selectedEvent?.title ?? 'Выберите мероприятие',
                  style: TextStyle(
                    color: _selectedEvent == null ? Colors.grey : null,
                  ),
                ),
                subtitle: const Text('Обязательно'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _selectEvent,
              ),
            ),
            const SizedBox(height: 16),

            // Выбор зала
            Card(
              child: ListTile(
                leading: const Icon(Icons.meeting_room, color: Colors.green),
                title: Text(
                  _selectedHall?.name ?? 'Выберите зал',
                  style: TextStyle(
                    color: _selectedHall == null ? Colors.grey : null,
                  ),
                ),
                subtitle: const Text('Обязательно'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _selectHall,
              ),
            ),
            const SizedBox(height: 16),

            // Дата и время
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.orange),
                      title: Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
                      subtitle: const Text('Дата'),
                      onTap: _selectDate,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.access_time, color: Colors.purple),
                      title: Text(_selectedTime.format(context)),
                      subtitle: const Text('Время'),
                      onTap: _selectTime,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Цена
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Базовая цена билета',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _basePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Цена (₽)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Цена будет умножена на коэффициент места (VIP, Premium)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Примечания
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Примечания',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Примечания к сеансу',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Кнопка создания
            ElevatedButton(
              onPressed: _createScreening,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Создать сеанс',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectEvent() async {
    final provider = context.read<CinemaProvider>();
    final events = provider.events;

    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала создайте мероприятие')),
      );
      return;
    }

    final selectedEvent = await showDialog<Event>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите мероприятие'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                title: Text(event.title),
                subtitle: Text(event.genre ?? ''),
                onTap: () => Navigator.pop(context, event),
              );
            },
          ),
        ),
      ),
    );

    if (selectedEvent != null) {
      setState(() => _selectedEvent = selectedEvent);
    }
  }

  void _selectHall() async {
    final provider = context.read<CinemaProvider>();
    final halls = provider.cinemaHalls.where((h) => h.isActive).toList();

    if (halls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала создайте кинозал')),
      );
      return;
    }

    final selectedHall = await showDialog<CinemaHall>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите зал'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: halls.length,
            itemBuilder: (context, index) {
              final hall = halls[index];
              return ListTile(
                title: Text(hall.name),
                subtitle: Text('${hall.totalSeats} мест'),
                onTap: () => Navigator.pop(context, hall),
              );
            },
          ),
        ),
      ),
    );

    if (selectedHall != null) {
      setState(() => _selectedHall = selectedHall);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _createScreening() async {
    _logger.info('[CreateScreening] Начинаем создание сеанса...');;
    
    if (_selectedEvent == null) {
      _logger.warning('[CreateScreening] Ошибка: мероприятие не выбрано');;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите мероприятие')),
      );
      return;
    }

    if (_selectedHall == null) {
      _logger.warning('[CreateScreening] Ошибка: зал не выбран');;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите зал')),
      );
      return;
    }

    final basePrice = double.tryParse(_basePriceController.text);
    if (basePrice == null || basePrice <= 0) {
      _logger.warning('[CreateScreening] Ошибка: некорректная цена: ${_basePriceController.text}');;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректную цену')),
      );
      return;
    }
    
    _logger.info('[CreateScreening] Данные валидны:');;
    _logger.info('  - Event: ${_selectedEvent!.title} (${_selectedEvent!.id})');;
    _logger.info('  - Hall: ${_selectedHall!.name} (${_selectedHall!.id})');;
    _logger.info('  - Price: $basePrice');;
    _logger.info('  - Start: $_selectedDate $_selectedTime');;

    final startTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final endTime = startTime.add(Duration(minutes: _selectedEvent!.durationMinutes ?? 120));

    final screening = Screening(
      id: 'scr_${DateTime.now().millisecondsSinceEpoch}',
      eventId: _selectedEvent!.id,
      eventTitle: _selectedEvent!.title,
      hallId: _selectedHall!.id,
      hallName: _selectedHall!.name,
      startTime: startTime,
      endTime: endTime,
      basePrice: basePrice,
      currency: 'RUB',
      status: 'scheduled',
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _logger.info('[CreateScreening] Создание объекта Screening завершено');;

    try {
      _logger.info('[CreateScreening] Вызов createScreening в provider...');;
      await context.read<CinemaProvider>().createScreening(screening);
      _logger.info('[CreateScreening] Сеанс успешно создан!');;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сеанс создан'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      _logger.info('[CreateScreening] ОШИБКА при создании сеанса: $e');;
      _logger.info('[CreateScreening] Stack trace: $stackTrace');;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
