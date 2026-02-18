import 'package:intl/intl.dart';

class DocumentData {
  String fio;
  String inventoryNumber;
  String equipmentName;
  int quantity;
  double? price;
  DateTime date;
  String outgoingNumber;

  DocumentData({
    required this.fio,
    required this.inventoryNumber,
    required this.equipmentName,
    this.quantity = 1,
    this.price,
    required this.date,
    this.outgoingNumber = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'fio': fio,
      'inventoryNumber': inventoryNumber,
      'equipmentName': equipmentName,
      'quantity': quantity,
      'price': price,
      'date': date.toIso8601String(),
      'outgoingNumber': outgoingNumber,
    };
  }

  factory DocumentData.fromMap(Map<String, dynamic> map) {
    return DocumentData(
      fio: map['fio'] ?? '',
      inventoryNumber: map['inventoryNumber'] ?? '',
      equipmentName: map['equipmentName'] ?? '',
      quantity: map['quantity'] ?? 1,
      price: map['price']?.toDouble(),
      date: DateTime.parse(map['date']),
      outgoingNumber: map['outgoingNumber'] ?? '',
    );
  }

  String get formattedDate {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String get formattedPrice {
    return price != null
        ? '${price!.toStringAsFixed(2)} ₽'
        : 'Не указано';
  }
}

class DocumentHeaderSettings {
  String organizationName;
  String address;
  String inn;
  String kpp;
  String email;
  String phone;

  DocumentHeaderSettings({
    this.organizationName = '',
    this.address = '',
    this.inn = '',
    this.kpp = '',
    this.email = '',
    this.phone = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'organizationName': organizationName,
      'address': address,
      'inn': inn,
      'kpp': kpp,
      'email': email,
      'phone': phone,
    };
  }

  factory DocumentHeaderSettings.fromMap(Map<String, dynamic> map) {
    return DocumentHeaderSettings(
      organizationName: map['organizationName'] ?? '',
      address: map['address'] ?? '',
      inn: map['inn'] ?? '',
      kpp: map['kpp'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
    );
  }
}
