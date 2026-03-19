/// Мероприятие (фильм, концерт и т.д.)
class Event {
  String id;
  String title;
  String? description;
  String? eventType; // movie, concert, theater
  String? genre;
  int? durationMinutes;
  String? ageRating;
  String? director;
  String? cast;
  String? country;
  int? year;
  String? posterUrl;
  String? trailerUrl;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    this.description,
    this.eventType,
    this.genre,
    this.durationMinutes,
    this.ageRating,
    this.director,
    this.cast,
    this.country,
    this.year,
    this.posterUrl,
    this.trailerUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'event_type': eventType,
      'genre': genre,
      'duration_minutes': durationMinutes,
      'age_rating': ageRating,
      'director': director,
      'cast': cast,
      'country': country,
      'year': year,
      'poster_url': posterUrl,
      'trailer_url': trailerUrl,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      eventType: map['event_type'],
      genre: map['genre'],
      durationMinutes: map['duration_minutes'],
      ageRating: map['age_rating'],
      director: map['director'],
      cast: map['cast'],
      country: map['country'],
      year: map['year'],
      posterUrl: map['poster_url'],
      trailerUrl: map['trailer_url'],
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? eventType,
    String? genre,
    int? durationMinutes,
    String? ageRating,
    String? director,
    String? cast,
    String? country,
    int? year,
    String? posterUrl,
    String? trailerUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      genre: genre ?? this.genre,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      ageRating: ageRating ?? this.ageRating,
      director: director ?? this.director,
      cast: cast ?? this.cast,
      country: country ?? this.country,
      year: year ?? this.year,
      posterUrl: posterUrl ?? this.posterUrl,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get durationLabel {
    if (durationMinutes == null) return '—';
    final hours = durationMinutes! ~/ 60;
    final minutes = durationMinutes! % 60;
    if (hours > 0) {
      return '$hours ч $minutes мин';
    }
    return '$minutes мин';
  }
}

/// Сеанс
class Screening {
  String id;
  String eventId;
  String? eventTitle;
  String hallId;
  String? hallName;
  DateTime startTime;
  DateTime? endTime;
  double basePrice;
  String currency;
  String status; // scheduled, active, completed, cancelled
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;

  Screening({
    required this.id,
    required this.eventId,
    this.eventTitle,
    required this.hallId,
    this.hallName,
    required this.startTime,
    this.endTime,
    this.basePrice = 0,
    this.currency = 'RUB',
    this.status = 'scheduled',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'event_title': eventTitle,
      'hall_id': hallId,
      'hall_name': hallName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'base_price': basePrice,
      'currency': currency,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Screening.fromMap(Map<String, dynamic> map) {
    return Screening(
      id: map['id']?.toString() ?? '',
      eventId: map['event_id']?.toString() ?? '',
      eventTitle: map['event_title'],
      hallId: map['hall_id']?.toString() ?? '',
      hallName: map['hall_name'],
      startTime: DateTime.tryParse(map['start_time'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(map['end_time'] ?? ''),
      basePrice: map['base_price'] ?? 0.0,
      currency: map['currency'] ?? 'RUB',
      status: map['status'] ?? 'scheduled',
      notes: map['notes'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Screening copyWith({
    String? id,
    String? eventId,
    String? eventTitle,
    String? hallId,
    String? hallName,
    DateTime? startTime,
    DateTime? endTime,
    double? basePrice,
    String? currency,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Screening(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      hallId: hallId ?? this.hallId,
      hallName: hallName ?? this.hallName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      basePrice: basePrice ?? this.basePrice,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isToday => DateTime.now().difference(startTime).inDays == 0;
  
  String get startTimeLabel {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  String get dateLabel {
    return '${startTime.day.toString().padLeft(2, '0')}.${startTime.month.toString().padLeft(2, '0')}.${startTime.year}';
  }
}

/// Билет
class Ticket {
  String id;
  String screeningId;
  String? screeningInfo;
  String seatId;
  String? seatLabel;
  double price;
  String status; // available, reserved, sold, returned
  String? barcode;
  String? qrCode;
  DateTime createdAt;
  DateTime updatedAt;

  Ticket({
    required this.id,
    required this.screeningId,
    this.screeningInfo,
    required this.seatId,
    this.seatLabel,
    required this.price,
    this.status = 'available',
    this.barcode,
    this.qrCode,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'screening_id': screeningId,
      'screening_info': screeningInfo,
      'seat_id': seatId,
      'seat_label': seatLabel,
      'price': price,
      'status': status,
      'barcode': barcode,
      'qr_code': qrCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id']?.toString() ?? '',
      screeningId: map['screening_id']?.toString() ?? '',
      screeningInfo: map['screening_info'],
      seatId: map['seat_id']?.toString() ?? '',
      seatLabel: map['seat_label'],
      price: map['price'] ?? 0.0,
      status: map['status'] ?? 'available',
      barcode: map['barcode'],
      qrCode: map['qr_code'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Ticket copyWith({
    String? id,
    String? screeningId,
    String? screeningInfo,
    String? seatId,
    String? seatLabel,
    double? price,
    String? status,
    String? barcode,
    String? qrCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ticket(
      id: id ?? this.id,
      screeningId: screeningId ?? this.screeningId,
      screeningInfo: screeningInfo ?? this.screeningInfo,
      seatId: seatId ?? this.seatId,
      seatLabel: seatLabel ?? this.seatLabel,
      price: price ?? this.price,
      status: status ?? this.status,
      barcode: barcode ?? this.barcode,
      qrCode: qrCode ?? this.qrCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isSold => status == 'sold';
  bool get isAvailable => status == 'available';
}

/// Продажа билета
class TicketSale {
  String id;
  String ticketId;
  String cashierId;
  String cashierName;
  String? customerName;
  String? customerPhone;
  String? customerEmail;
  double salePrice;
  String paymentMethod; // cash, card, online
  String? receiptNumber;
  DateTime saleDate;
  DateTime? refundDate;
  String? refundReason;
  String status; // sold, returned
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;

  TicketSale({
    required this.id,
    required this.ticketId,
    required this.cashierId,
    required this.cashierName,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.salePrice,
    this.paymentMethod = 'cash',
    this.receiptNumber,
    required this.saleDate,
    this.refundDate,
    this.refundReason,
    this.status = 'sold',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'cashier_id': cashierId,
      'cashier_name': cashierName,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'sale_price': salePrice,
      'payment_method': paymentMethod,
      'receipt_number': receiptNumber,
      'sale_date': saleDate.toIso8601String(),
      'refund_date': refundDate?.toIso8601String(),
      'refund_reason': refundReason,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TicketSale.fromMap(Map<String, dynamic> map) {
    return TicketSale(
      id: map['id']?.toString() ?? '',
      ticketId: map['ticket_id']?.toString() ?? '',
      cashierId: map['cashier_id']?.toString() ?? '',
      cashierName: map['cashier_name'] ?? '',
      customerName: map['customer_name'],
      customerPhone: map['customer_phone'],
      customerEmail: map['customer_email'],
      salePrice: map['sale_price'] ?? 0.0,
      paymentMethod: map['payment_method'] ?? 'cash',
      receiptNumber: map['receipt_number'],
      saleDate: DateTime.tryParse(map['sale_date'] ?? '') ?? DateTime.now(),
      refundDate: DateTime.tryParse(map['refund_date'] ?? ''),
      refundReason: map['refund_reason'],
      status: map['status'] ?? 'sold',
      notes: map['notes'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  TicketSale copyWith({
    String? id,
    String? ticketId,
    String? cashierId,
    String? cashierName,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    double? salePrice,
    String? paymentMethod,
    String? receiptNumber,
    DateTime? saleDate,
    DateTime? refundDate,
    String? refundReason,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TicketSale(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      salePrice: salePrice ?? this.salePrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      saleDate: saleDate ?? this.saleDate,
      refundDate: refundDate ?? this.refundDate,
      refundReason: refundReason ?? this.refundReason,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
