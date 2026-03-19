import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/cinema_hall.dart';
import '../models/event.dart';

class CinemaProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<CinemaHall> _cinemaHalls = [];
  List<Seat> _seats = [];
  List<Event> _events = [];
  List<Screening> _screenings = [];
  List<Ticket> _tickets = [];
  List<TicketSale> _ticketSales = [];
  
  CinemaHall? _selectedHall;
  Event? _selectedEvent;
  Screening? _selectedScreening;
  
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CinemaHall> get cinemaHalls => _cinemaHalls;
  List<Seat> get seats => _seats;
  List<Event> get events => _events;
  List<Screening> get screenings => _screenings;
  List<Ticket> get tickets => _tickets;
  List<TicketSale> get ticketSales => _ticketSales;
  
  CinemaHall? get selectedHall => _selectedHall;
  Event? get selectedEvent => _selectedEvent;
  Screening? get selectedScreening => _selectedScreening;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Statistics
  Map<String, int> get statistics {
    return {
      'halls': _cinemaHalls.where((h) => h.isActive).length,
      'events': _events.where((e) => e.isActive).length,
      'screenings': _screenings.where((s) => s.status == 'scheduled').length,
      'tickets_sold': _ticketSales.where((s) => s.status == 'sold').length,
    };
  }

  // Load cinema halls
  Future<void> loadCinemaHalls({bool forceRefresh = false}) async {
    if (!forceRefresh && _cinemaHalls.isNotEmpty) return;

    _setLoading(true);
    _clearError();

    try {
      final data = await _dbHelper.getCinemaHalls();
      _cinemaHalls = data.map((map) => CinemaHall.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки кинозалов: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create cinema hall
  Future<void> createCinemaHall(CinemaHall hall) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.insertCinemaHall(hall.toMap());
      _cinemaHalls.add(hall);
      notifyListeners();
    } catch (e) {
      _setError('Ошибка создания кинозала: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update cinema hall
  Future<void> updateCinemaHall(CinemaHall hall) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.updateCinemaHall(hall.toMap());
      final index = _cinemaHalls.indexWhere((h) => h.id == hall.id);
      if (index != -1) {
        _cinemaHalls[index] = hall;
      }
      notifyListeners();
    } catch (e) {
      _setError('Ошибка обновления кинозала: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete cinema hall
  Future<void> deleteCinemaHall(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.deleteCinemaHall(id);
      _cinemaHalls.removeWhere((h) => h.id == id);
      notifyListeners();
    } catch (e) {
      _setError('Ошибка удаления кинозала: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Load seats for hall
  Future<void> loadSeats(String hallId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _seats.isNotEmpty && _seats.first.hallId == hallId) return;

    _setLoading(true);
    _clearError();

    try {
      final data = await _dbHelper.getSeats(hallId: hallId);
      _seats = data.map((map) => Seat.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки мест: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create seat
  Future<void> createSeat(Seat seat) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.insertSeat(seat.toMap());
      _seats.add(seat);
      notifyListeners();
    } catch (e) {
      _setError('Ошибка создания места: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update seat
  Future<void> updateSeat(Seat seat) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.updateSeat(seat.toMap());
      final index = _seats.indexWhere((s) => s.id == seat.id);
      if (index != -1) {
        _seats[index] = seat;
      }
      notifyListeners();
    } catch (e) {
      _setError('Ошибка обновления места: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete seat
  Future<void> deleteSeat(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.deleteSeat(id);
      _seats.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      _setError('Ошибка удаления места: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Load events
  Future<void> loadEvents({bool? isActive, bool forceRefresh = false}) async {
    if (!forceRefresh && _events.isNotEmpty) return;

    _setLoading(true);
    _clearError();

    try {
      final data = await _dbHelper.getEvents(isActive: isActive);
      _events = data.map((map) => Event.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки мероприятий: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create event
  Future<void> createEvent(Event event) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.insertEvent(event.toMap());
      _events.add(event);
      notifyListeners();
    } catch (e) {
      _setError('Ошибка создания мероприятия: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update event
  Future<void> updateEvent(Event event) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.updateEvent(event.toMap());
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = event;
      }
      notifyListeners();
    } catch (e) {
      _setError('Ошибка обновления мероприятия: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete event
  Future<void> deleteEvent(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.deleteEvent(id);
      _events.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      _setError('Ошибка удаления мероприятия: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Load screenings
  Future<void> loadScreenings({String? eventId, String? hallId, DateTime? date, bool forceRefresh = false}) async {
    if (!forceRefresh && _screenings.isNotEmpty) return;

    _setLoading(true);
    _clearError();

    try {
      final data = await _dbHelper.getScreenings(eventId: eventId, hallId: hallId, date: date);
      _screenings = data.map((map) => Screening.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки сеансов: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create screening
  Future<void> createScreening(Screening screening) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.insertScreening(screening.toMap());
      _screenings.add(screening);
      
      // Создаём билеты для всех мест в зале
      await _createTicketsForScreening(screening);
      
      notifyListeners();
    } catch (e) {
      _setError('Ошибка создания сеанса: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Create tickets for screening
  Future<void> _createTicketsForScreening(Screening screening) async {
    final seats = await _dbHelper.getSeats(hallId: screening.hallId);
    
    for (final seatMap in seats) {
      final seat = Seat.fromMap(seatMap);
      final ticket = Ticket(
        id: 'tkt_${screening.id}_${seat.id}',
        screeningId: screening.id,
        screeningInfo: '${screening.eventTitle} - ${screening.startTimeLabel}',
        seatId: seat.id,
        seatLabel: seat.label,
        price: screening.basePrice * seat.priceModifier,
        status: 'available',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _dbHelper.insertTicket(ticket.toMap());
    }
  }

  // Update screening
  Future<void> updateScreening(Screening screening) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.updateScreening(screening.toMap());
      final index = _screenings.indexWhere((s) => s.id == screening.id);
      if (index != -1) {
        _screenings[index] = screening;
      }
      notifyListeners();
    } catch (e) {
      _setError('Ошибка обновления сеанса: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete screening
  Future<void> deleteScreening(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _dbHelper.deleteScreening(id);
      _screenings.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      _setError('Ошибка удаления сеанса: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Load tickets for screening
  Future<void> loadTickets(String screeningId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _tickets.isNotEmpty && _tickets.first.screeningId == screeningId) return;

    _setLoading(true);
    _clearError();

    try {
      final data = await _dbHelper.getTickets(screeningId: screeningId);
      _tickets = data.map((map) => Ticket.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки билетов: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Sell ticket
  Future<void> sellTicket(Ticket ticket, TicketSale sale) async {
    _setLoading(true);
    _clearError();

    try {
      // Обновляем статус билета
      final updatedTicket = ticket.copyWith(status: 'sold');
      await _dbHelper.updateTicket(updatedTicket.toMap());
      
      // Создаём запись о продаже
      await _dbHelper.insertTicketSale(sale.toMap());
      
      // Обновляем локальные данные
      final index = _tickets.indexWhere((t) => t.id == ticket.id);
      if (index != -1) {
        _tickets[index] = updatedTicket;
      }
      _ticketSales.add(sale);
      
      notifyListeners();
    } catch (e) {
      _setError('Ошибка продажи билета: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Return ticket
  Future<void> returnTicket(String ticketId, String saleId, String reason) async {
    _setLoading(true);
    _clearError();

    try {
      // Обновляем статус билета
      final ticketIndex = _tickets.indexWhere((t) => t.id == ticketId);
      if (ticketIndex != -1) {
        final updatedTicket = _tickets[ticketIndex].copyWith(status: 'returned');
        await _dbHelper.updateTicket(updatedTicket.toMap());
        _tickets[ticketIndex] = updatedTicket;
      }
      
      // Обновляем запись о продаже
      final saleIndex = _ticketSales.indexWhere((s) => s.id == saleId);
      if (saleIndex != -1) {
        final updatedSale = _ticketSales[saleIndex].copyWith(
          status: 'returned',
          refundDate: DateTime.now(),
          refundReason: reason,
        );
        await _dbHelper.updateTicketSale(updatedSale.toMap());
        _ticketSales[saleIndex] = updatedSale;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Ошибка возврата билета: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Get available seats for screening
  List<Ticket> getAvailableTickets(String screeningId) {
    return _tickets.where((t) => t.screeningId == screeningId && t.status == 'available').toList();
  }

  // Get sold tickets for screening
  List<Ticket> getSoldTickets(String screeningId) {
    return _tickets.where((t) => t.screeningId == screeningId && t.status == 'sold').toList();
  }

  // Get ticket by seat and screening
  Ticket? getTicketBySeat(String screeningId, String seatId) {
    try {
      return _tickets.firstWhere((t) => t.screeningId == screeningId && t.seatId == seatId);
    } catch (_) {
      return null;
    }
  }

  // Select hall
  void selectHall(CinemaHall? hall) {
    _selectedHall = hall;
    notifyListeners();
  }

  // Select event
  void selectEvent(Event? event) {
    _selectedEvent = event;
    notifyListeners();
  }

  // Select screening
  void selectScreening(Screening? screening) {
    _selectedScreening = screening;
    notifyListeners();
  }

  // Clear selection
  void clearSelection() {
    _selectedHall = null;
    _selectedEvent = null;
    _selectedScreening = null;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
