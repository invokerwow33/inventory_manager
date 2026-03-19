import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cinema_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/event.dart';
import '../../models/cinema_hall.dart';
import '../../services/ticket_print_service.dart';

class CinemaSeatSelectionScreen extends StatefulWidget {
  final Screening screening;

  const CinemaSeatSelectionScreen({super.key, required this.screening});

  @override
  State<CinemaSeatSelectionScreen> createState() => _CinemaSeatSelectionScreenState();
}

class _CinemaSeatSelectionScreenState extends State<CinemaSeatSelectionScreen> {
  final List<String> _selectedSeatIds = [];
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final provider = context.read<CinemaProvider>();
    await provider.loadTickets(widget.screening.id, forceRefresh: true);
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор мест'),
        actions: [
          if (_selectedSeatIds.isNotEmpty)
            ElevatedButton(
              onPressed: () => _sellTickets(auth),
              child: Text('Продать (${_selectedSeatIds.length})'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Информация о сеансе
          _buildScreeningInfo(),
          
          // Легенда
          _buildLegend(),
          
          // Схема зала
          Expanded(
            child: Consumer<CinemaProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
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
                      ...sortedRows.map((row) => _buildRow(row, seatsByRow[row]!, provider)),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Итого
          if (_selectedSeatIds.isNotEmpty)
            _buildTotalSection(),
        ],
      ),
    );
  }

  Widget _buildScreeningInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.screening.eventTitle ?? 'Без названия',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 4),
              Text(widget.screening.dateLabel),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16),
              const SizedBox(width: 4),
              Text(widget.screening.startTimeLabel),
              const SizedBox(width: 16),
              const Icon(Icons.location_on, size: 16),
              const SizedBox(width: 4),
              Text(widget.screening.hallName ?? 'Зал'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('Свободно', Colors.grey.shade300),
          const SizedBox(width: 16),
          _buildLegendItem('Выбрано', Colors.green),
          const SizedBox(width: 16),
          _buildLegendItem('Занято', Colors.red.shade300),
        ],
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

  Widget _buildRow(int rowNum, List<Seat> seats, CinemaProvider provider) {
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
          ...seats.map((seat) => _buildSeat(seat, provider)),
        ],
      ),
    );
  }

  Widget _buildSeat(Seat seat, CinemaProvider provider) {
    // Получаем билет для этого места
    final ticket = provider.getTicketBySeat(widget.screening.id, seat.id);
    final isSold = ticket?.status == 'sold';
    final isSelected = _selectedSeatIds.contains(seat.id);
    
    final price = (widget.screening.basePrice * seat.priceModifier).toInt();

    return GestureDetector(
      onTap: isSold ? null : () => _toggleSeat(seat, price),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSold
              ? Colors.red.shade300
              : isSelected
                  ? Colors.green
                  : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade400,
          ),
        ),
        child: Center(
          child: Text(
            '${seat.seatNumber}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSold ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  void _toggleSeat(Seat seat, int price) {
    setState(() {
      if (_selectedSeatIds.contains(seat.id)) {
        _selectedSeatIds.remove(seat.id);
      } else {
        _selectedSeatIds.add(seat.id);
      }
    });
  }

  Widget _buildTotalSection() {
    final provider = context.read<CinemaProvider>();
    int total = 0;
    
    for (final seatId in _selectedSeatIds) {
      final ticket = provider.getTicketBySeat(widget.screening.id, seatId);
      if (ticket != null) {
        total += ticket.price.toInt();
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Выбрано мест: ${_selectedSeatIds.length}',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Итого: $total ₽',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sellTickets(AuthProvider auth) async {
    final provider = context.read<CinemaProvider>();
    final cashier = auth.currentUser;

    // Показываем диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Продажа билетов'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Продать ${_selectedSeatIds.length} бил.(а/ов)?'),
            const SizedBox(height: 16),
            TextField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Имя покупателя',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customerPhoneController,
              decoration: const InputDecoration(
                labelText: 'Телефон',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Продать'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final soldTickets = <Map<String, dynamic>>[];
      final screening = widget.screening;
      
      // Загружаем данные
      final hall = provider.cinemaHalls.firstWhere((h) => h.id == screening.hallId);
      final event = provider.events.firstWhere((e) => e.id == screening.eventId);

      // Продаём каждое место
      for (final seatId in _selectedSeatIds) {
        final ticket = provider.getTicketBySeat(screening.id, seatId);
        if (ticket == null) continue;

        final seat = provider.seats.firstWhere((s) => s.id == seatId);

        final sale = TicketSale(
          id: 'sale_${DateTime.now().millisecondsSinceEpoch}_$seatId',
          ticketId: ticket.id,
          cashierId: cashier!.id,
          cashierName: cashier.username,
          customerName: _customerNameController.text.trim().isEmpty
              ? null
              : _customerNameController.text.trim(),
          customerPhone: _customerPhoneController.text.trim().isEmpty
              ? null
              : _customerPhoneController.text.trim(),
          salePrice: ticket.price,
          paymentMethod: 'cash',
          saleDate: DateTime.now(),
          status: 'sold',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await provider.sellTicket(ticket, sale);
        
        soldTickets.add({
          'ticket': ticket,
          'sale': sale,
          'screening': screening,
          'event': event,
          'hall': hall,
          'seat': seat,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Продано ${_selectedSeatIds.length} бил.(а/ов)'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Печать',
              textColor: Colors.white,
              onPressed: () {
                TicketPrintService.printTickets(tickets: soldTickets);
              },
            ),
          ),
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
}
