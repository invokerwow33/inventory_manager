/// Validation utilities for data integrity
class Validators {
  Validators._();

  /// Validates equipment data before insert/update
  static String? validateEquipment(Map<String, dynamic> equipment) {
    if (equipment['name'] == null || equipment['name'].toString().trim().isEmpty) {
      return 'Название оборудования обязательно для заполнения';
    }

    if (equipment['id'] == null || equipment['id'].toString().trim().isEmpty) {
      return 'ID оборудования обязателен';
    }

    return null;
  }

  /// Validates employee data before insert/update
  static String? validateEmployee(Map<String, dynamic> employee) {
    if (employee['full_name'] == null || employee['full_name'].toString().trim().isEmpty) {
      return 'ФИО сотрудника обязательно для заполнения';
    }

    if (employee['id'] == null || employee['id'].toString().trim().isEmpty) {
      return 'ID сотрудника обязателен';
    }

    return null;
  }

  /// Validates consumable data before insert/update
  static String? validateConsumable(Map<String, dynamic> consumable) {
    if (consumable['name'] == null || consumable['name'].toString().trim().isEmpty) {
      return 'Название расходника обязательно для заполнения';
    }

    if (consumable['id'] == null || consumable['id'].toString().trim().isEmpty) {
      return 'ID расходника обязателен';
    }

    final quantity = consumable['quantity'];
    if (quantity != null && (quantity is num) && quantity < 0) {
      return 'Количество не может быть отрицательным';
    }

    return null;
  }

  /// Validates movement data before insert
  static String? validateMovement(Map<String, dynamic> movement) {
    if (movement['equipment_id'] == null || movement['equipment_id'].toString().trim().isEmpty) {
      return 'ID оборудования обязателен';
    }

    if (movement['movement_type'] == null || movement['movement_type'].toString().trim().isEmpty) {
      return 'Тип перемещения обязателен';
    }

    return null;
  }

  /// Validates consumable movement data before insert
  static String? validateConsumableMovement(Map<String, dynamic> movement) {
    if (movement['consumable_id'] == null || movement['consumable_id'].toString().trim().isEmpty) {
      return 'ID расходника обязателен';
    }

    if (movement['operation_type'] == null || movement['operation_type'].toString().trim().isEmpty) {
      return 'Тип операции обязателен';
    }

    final quantity = movement['quantity'];
    if (quantity == null || (quantity is num) && quantity <= 0) {
      return 'Количество должно быть положительным числом';
    }

    return null;
  }
}
