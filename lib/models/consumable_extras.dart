import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConsumablePriceHistory {
  int? id;
  String consumableId;
  String consumableName;
  String? supplier;
  double price;
  double quantity;
  String? currency;
  DateTime purchaseDate;
  String? documentNumber;
  String? notes;
  DateTime createdAt;

  ConsumablePriceHistory({
    this.id,
    required this.consumableId,
    required this.consumableName,
    this.supplier,
    required this.price,
    required this.quantity,
    this.currency = 'RUB',
    required this.purchaseDate,
    this.documentNumber,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'consumable_id': consumableId,
      'consumable_name': consumableName,
      'supplier': supplier,
      'price': price,
      'quantity': quantity,
      'currency': currency,
      'purchase_date': purchaseDate.toIso8601String(),
      'document_number': documentNumber,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ConsumablePriceHistory.fromMap(Map<String, dynamic> map) {
    return ConsumablePriceHistory(
      id: map['id'],
      consumableId: map['consumable_id']?.toString() ?? '',
      consumableName: map['consumable_name'] ?? '',
      supplier: map['supplier'],
      price: (map['price'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'RUB',
      purchaseDate: DateTime.tryParse(map['purchase_date'] ?? '') ?? DateTime.now(),
      documentNumber: map['document_number'],
      notes: map['notes'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get formattedDate {
    return DateFormat('dd.MM.yyyy').format(purchaseDate);
  }

  String get formattedPrice {
    return '${price.toStringAsFixed(2)} ${currency ?? '₽'}';
  }

  double get unitPrice {
    return quantity > 0 ? price / quantity : price;
  }
}

class ConsumableBatch {
  String id;
  String consumableId;
  String consumableName;
  String batchNumber;
  double quantity;
  DateTime receivedDate;
  DateTime? expirationDate;
  String? supplier;
  String? documentNumber;
  bool isActive;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;

  ConsumableBatch({
    required this.id,
    required this.consumableId,
    required this.consumableName,
    required this.batchNumber,
    required this.quantity,
    required this.receivedDate,
    this.expirationDate,
    this.supplier,
    this.documentNumber,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'consumable_id': consumableId,
      'consumable_name': consumableName,
      'batch_number': batchNumber,
      'quantity': quantity,
      'received_date': receivedDate.toIso8601String(),
      'expiration_date': expirationDate?.toIso8601String(),
      'supplier': supplier,
      'document_number': documentNumber,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ConsumableBatch.fromMap(Map<String, dynamic> map) {
    return ConsumableBatch(
      id: map['id']?.toString() ?? '',
      consumableId: map['consumable_id']?.toString() ?? '',
      consumableName: map['consumable_name'] ?? '',
      batchNumber: map['batch_number'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      receivedDate: DateTime.tryParse(map['received_date'] ?? '') ?? DateTime.now(),
      expirationDate: map['expiration_date'] != null
          ? DateTime.tryParse(map['expiration_date'])
          : null,
      supplier: map['supplier'],
      documentNumber: map['document_number'],
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      notes: map['notes'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get formattedReceivedDate {
    return DateFormat('dd.MM.yyyy').format(receivedDate);
  }

  String get formattedExpirationDate {
    return expirationDate != null
        ? DateFormat('dd.MM.yyyy').format(expirationDate!)
        : 'Не указано';
  }

  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final daysUntil = expirationDate!.difference(DateTime.now()).inDays;
    return daysUntil <= 30 && daysUntil > 0;
  }

  int? get daysUntilExpiration {
    if (expirationDate == null) return null;
    return expirationDate!.difference(DateTime.now()).inDays;
  }
}

class ReorderPoint {
  String id;
  String consumableId;
  String consumableName;
  double minimumStock;
  double reorderPoint;
  double reorderQuantity;
  String? preferredSupplier;
  int leadTimeDays;
  bool autoReorder;
  String? notificationEmail;
  DateTime createdAt;
  DateTime updatedAt;

  ReorderPoint({
    required this.id,
    required this.consumableId,
    required this.consumableName,
    required this.minimumStock,
    required this.reorderPoint,
    required this.reorderQuantity,
    this.preferredSupplier,
    this.leadTimeDays = 7,
    this.autoReorder = false,
    this.notificationEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'consumable_id': consumableId,
      'consumable_name': consumableName,
      'minimum_stock': minimumStock,
      'reorder_point': reorderPoint,
      'reorder_quantity': reorderQuantity,
      'preferred_supplier': preferredSupplier,
      'lead_time_days': leadTimeDays,
      'auto_reorder': autoReorder ? 1 : 0,
      'notification_email': notificationEmail,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ReorderPoint.fromMap(Map<String, dynamic> map) {
    return ReorderPoint(
      id: map['id']?.toString() ?? '',
      consumableId: map['consumable_id']?.toString() ?? '',
      consumableName: map['consumable_name'] ?? '',
      minimumStock: (map['minimum_stock'] ?? 0).toDouble(),
      reorderPoint: (map['reorder_point'] ?? 0).toDouble(),
      reorderQuantity: (map['reorder_quantity'] ?? 0).toDouble(),
      preferredSupplier: map['preferred_supplier'],
      leadTimeDays: map['lead_time_days'] ?? 7,
      autoReorder: map['auto_reorder'] == 1 || map['auto_reorder'] == true,
      notificationEmail: map['notification_email'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool shouldReorder(double currentStock) {
    return currentStock <= reorderPoint;
  }

  bool isCritical(double currentStock) {
    return currentStock <= minimumStock;
  }
}

class ConsumableForecast {
  String consumableId;
  String consumableName;
  DateTime forecastDate;
  double predictedConsumption;
  double confidenceInterval;
  String? method;
  DateTime createdAt;

  ConsumableForecast({
    required this.consumableId,
    required this.consumableName,
    required this.forecastDate,
    required this.predictedConsumption,
    required this.confidenceInterval,
    this.method,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'consumable_id': consumableId,
      'consumable_name': consumableName,
      'forecast_date': forecastDate.toIso8601String(),
      'predicted_consumption': predictedConsumption,
      'confidence_interval': confidenceInterval,
      'method': method,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ConsumableForecast.fromMap(Map<String, dynamic> map) {
    return ConsumableForecast(
      consumableId: map['consumable_id']?.toString() ?? '',
      consumableName: map['consumable_name'] ?? '',
      forecastDate: DateTime.tryParse(map['forecast_date'] ?? '') ?? DateTime.now(),
      predictedConsumption: (map['predicted_consumption'] ?? 0).toDouble(),
      confidenceInterval: (map['confidence_interval'] ?? 0).toDouble(),
      method: map['method'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get formattedDate {
    return DateFormat('dd.MM.yyyy').format(forecastDate);
  }
}
