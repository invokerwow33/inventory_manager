import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cinema_provider.dart';
import '../../models/cinema_hall.dart';

class ManageCinemaHallSeatsScreen extends StatefulWidget {
  final CinemaHall hall;

  const ManageCinemaHallSeatsScreen({super.key, required this.hall});

  @override
  State<ManageCinemaHallSeatsScreen> createState() => _ManageCinemaHallSeatsScreenState();
}

class _ManageCinemaHallSeatsScreenState extends State<ManageCinemaHallSeatsScreen> {
  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  Future<void> _loadSeats() async {
    await context.read<CinemaProvider>().loadSeats(widget.hall.id, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Места: ${widget.hall.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateSeatDialog(),
            tooltip: 'Добавить место',
          ),
          IconButton(
            icon: const Icon(Icons.grid_on),
            onPressed: () => _showGenerateSeatsDialog(),
            tooltip: 'Сгенерировать места',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSeats,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Column(
        children: [
          // Информация о зале
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Icon(Icons.meeting_room),
                const SizedBox(width: 8),
                Text(
                  '${widget.hall.name} - ${widget.hall.totalSeats} мест',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Легенда
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Свободно', Colors.grey.shade300),
                const SizedBox(width: 16),
                _buildLegendItem('Занято', Colors.red.shade300),
                const SizedBox(width: 16),
                _buildLegendItem('VIP', Colors.purple.shade300),
              ],
            ),
          ),
          
          // Схема мест
          Expanded(
            child: Consumer<CinemaProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.seats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_seat, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Нет мест',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showGenerateSeatsDialog(),
                          icon: const Icon(Icons.grid_on),
                          label: const Text('Сгенерировать места'),
                        ),
                      ],
                    ),
                  );
                }

                // Группируем места по рядам
                final seatsByRow = <int, List<Seat>>{};
                for (final seat in provider.seats) {
                  seatsByRow.putIfAbsent(seat.row, () => []).add(seat);
                }
                
                // Сортируем ряды
                final sortedRows = seatsByRow.keys.toList()..sort();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Экран
                      _buildScreen(),
                      const SizedBox(height: 32),
                      
                      // Места
                      ...sortedRows.map((row) => _buildRow(row, seatsByRow[row]!)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreen() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: const Center(
        child: Text(
          'ЭКРАН',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRow(int rowNum, List<Seat> seats) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Номер ряда
          SizedBox(
            width: 30,
            child: Text(
              '$rowNum',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          
          // Места
          ...seats.map((seat) => _buildSeat(seat)),
        ],
      ),
    );
  }

  Widget _buildSeat(Seat seat) {
    final isOccupied = seat.status == 'occupied';
    final isVip = seat.seatType == SeatType.vip || seat.seatType == SeatType.premium;

    return GestureDetector(
      onTap: () => _showEditSeatDialog(seat),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isOccupied
              ? Colors.red.shade300
              : isVip
                  ? Colors.purple.shade300
                  : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isVip ? Colors.purple : Colors.grey.shade400,
            width: isVip ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            '${seat.seatNumber}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateSeatDialog() {
    final rowController = TextEditingController();
    final seatNumberController = TextEditingController();
    SeatType seatType = SeatType.standard;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить место'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rowController,
              decoration: const InputDecoration(
                labelText: 'Ряд *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: seatNumberController,
              decoration: const InputDecoration(
                labelText: 'Номер места *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SeatType>(
              value: seatType,
              decoration: const InputDecoration(
                labelText: 'Тип места',
                border: OutlineInputBorder(),
              ),
              items: SeatType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.label),
                );
              }).toList(),
              onChanged: (value) => seatType = value ?? SeatType.standard,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final row = int.tryParse(rowController.text.trim());
              final seatNumber = int.tryParse(seatNumberController.text.trim());

              if (row == null || seatNumber == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите корректные данные')),
                );
                return;
              }

              final seat = Seat(
                id: 'seat_${DateTime.now().millisecondsSinceEpoch}',
                hallId: widget.hall.id,
                row: row,
                seatNumber: seatNumber,
                seatType: seatType,
                priceModifier: seatType.priceModifier,
                isAccessible: false,
                status: 'available',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              await context.read<CinemaProvider>().createSeat(seat);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showEditSeatDialog(Seat seat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Место ${seat.row}-${seat.seatNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                seat.status == 'occupied' ? Icons.event_busy : Icons.event_available,
                color: seat.status == 'occupied' ? Colors.red : Colors.green,
              ),
              title: Text('Статус: ${seat.status}'),
              subtitle: const Text('Нажмите для изменения'),
              onTap: () {
                Navigator.pop(context);
                _toggleSeatStatus(seat);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить место'),
              onTap: () {
                Navigator.pop(context);
                _deleteSeat(seat);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSeatStatus(Seat seat) async {
    final newStatus = seat.status == 'available' ? 'occupied' : 'available';
    final updatedSeat = seat.copyWith(status: newStatus);
    await context.read<CinemaProvider>().updateSeat(updatedSeat);
  }

  void _deleteSeat(Seat seat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить место?'),
        content: Text('Место ${seat.row}-${seat.seatNumber}'),
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
      await context.read<CinemaProvider>().deleteSeat(seat.id);
    }
  }

  void _showGenerateSeatsDialog() {
    final rowsController = TextEditingController(text: '10');
    final seatsPerRowController = TextEditingController(text: '10');
    SeatType seatType = SeatType.standard;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сгенерировать места'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rowsController,
              decoration: const InputDecoration(
                labelText: 'Количество рядов',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: seatsPerRowController,
              decoration: const InputDecoration(
                labelText: 'Мест в ряду',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SeatType>(
              value: seatType,
              decoration: const InputDecoration(
                labelText: 'Тип мест',
                border: OutlineInputBorder(),
              ),
              items: SeatType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.label),
                );
              }).toList(),
              onChanged: (value) => seatType = value ?? SeatType.standard,
            ),
            const SizedBox(height: 8),
            Text(
              'Будет создано ${(int.tryParse(rowsController.text) ?? 0) * (int.tryParse(seatsPerRowController.text) ?? 0)} мест',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final rows = int.tryParse(rowsController.text.trim()) ?? 0;
              final seatsPerRow = int.tryParse(seatsPerRowController.text.trim()) ?? 0;

              if (rows <= 0 || seatsPerRow <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите корректные значения')),
                );
                return;
              }

              // Генерируем места
              for (int row = 1; row <= rows; row++) {
                for (int seatNum = 1; seatNum <= seatsPerRow; seatNum++) {
                  final seat = Seat(
                    id: 'seat_${widget.hall.id}_$row\_$seatNum',
                    hallId: widget.hall.id,
                    row: row,
                    seatNumber: seatNum,
                    seatType: seatType,
                    priceModifier: seatType.priceModifier,
                    isAccessible: false,
                    status: 'available',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await context.read<CinemaProvider>().createSeat(seat);
                }
              }

              if (mounted) Navigator.pop(context);
            },
            child: const Text('Сгенерировать'),
          ),
        ],
      ),
    );
  }
}
