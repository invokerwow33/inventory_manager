import 'package:flutter/foundation.dart';

abstract class IDatabaseHelper {
  Future<void> initDatabase();
  
  // Equipment operations
  Future<List<Map<String, dynamic>>> getEquipment({bool forceRefresh = false});
  Future<Map<String, dynamic>?> getEquipmentById(dynamic id);
  Future<String> insertEquipment(Map<String, dynamic> equipment);
  Future<int> updateEquipment(Map<String, dynamic> equipment);
  Future<int> deleteEquipment(dynamic id);
  Future<List<Map<String, dynamic>>> searchEquipment(String query);
  Future<List<Map<String, dynamic>>> searchEquipmentByName(String name);
  Future<List<Map<String, dynamic>>> searchEquipmentByInventoryNumber(String inventoryNumber);
  Future<int> getEquipmentCount();
  
  // Helper methods for backward compatibility
  Future<List<Map<String, dynamic>>> getAllEquipment();
  
  // Employee operations
  Future<List<Map<String, dynamic>>> getEmployees({bool includeInactive = false});
  Future<Map<String, dynamic>?> getEmployeeById(String id);
  Future<String> insertEmployee(Map<String, dynamic> employee);
  Future<int> updateEmployee(Map<String, dynamic> employee);
  Future<int> deleteEmployee(String id);
  
  // Consumables operations
  Future<List<Map<String, dynamic>>> getConsumables();
  Future<Map<String, dynamic>?> getConsumableById(String id);
  Future<String> insertConsumable(Map<String, dynamic> consumable);
  Future<int> updateConsumable(Map<String, dynamic> consumable);
  Future<int> deleteConsumable(String id);
  
  // Statistics
  Future<Map<String, int>> getStatistics();
  Future<Map<String, int>> getConsumableStats();
  Future<Map<String, int>> getEmployeeStats();
  
  // Export
  Future<String> exportToCSV();
  
  // Settings
  Future<Map<String, dynamic>?> getAppSettings();
  Future<void> saveAppSettings(Map<String, dynamic> settings);
}
