import 'package:intl/intl.dart';

class DocumentData {
  String fio;
  String inventoryNumber;
  String equipmentName;
  int quantity;
  double? price;
  DateTime date;

  DocumentData({
    required this.fio,
    required this.inventoryNumber,
    required this.equipmentName,
    this.quantity = 1,
    this.price,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'fio': fio,
      'inventoryNumber': inventoryNumber,
      'equipmentName': equipmentName,
      'quantity': quantity,
      'price': price,
      'date': date.toIso8601String(),
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
  String department;
  String address;
  String phone;

  DocumentHeaderSettings({
    this.organizationName = '',
    this.department = '',
    this.address = '',
    this.phone = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'organizationName': organizationName,
      'department': department,
      'address': address,
      'phone': phone,
    };
  }

  factory DocumentHeaderSettings.fromMap(Map<String, dynamic> map) {
    return DocumentHeaderSettings(
      organizationName: map['organizationName'] ?? '',
      department: map['department'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
    );
  }
}
