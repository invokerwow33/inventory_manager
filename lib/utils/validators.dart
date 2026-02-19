/// Result of a validation operation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult._(this.isValid, this.errorMessage);

  const ValidationResult.valid() : this._(true, null);
  const ValidationResult.error(String message) : this._(false, message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationResult &&
          runtimeType == other.runtimeType &&
          isValid == other.isValid &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => isValid.hashCode ^ errorMessage.hashCode;

  @override
  String toString() =>
      isValid ? 'ValidationResult.valid()' : 'ValidationResult.error($errorMessage)';
}

/// Validation utilities for data integrity
class Validators {
  Validators._();

  // ==================== ValidationResult-based validators ====================

  /// Validates that a value is not null or empty
  static ValidationResult required(String? value, {String fieldName = 'Поле'}) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.error('$fieldName обязательно для заполнения');
    }
    return const ValidationResult.valid();
  }

  /// Validates maximum length of a string
  static ValidationResult maxLength(String? value, int max, {String fieldName = 'Поле'}) {
    if (value == null || value.isEmpty) return const ValidationResult.valid();
    if (value.length > max) {
      return ValidationResult.error('$fieldName должно содержать не более $max символов');
    }
    return const ValidationResult.valid();
  }

  /// Validates minimum length of a string
  static ValidationResult minLength(String? value, int min, {String fieldName = 'Поле'}) {
    if (value == null || value.isEmpty) {
      return ValidationResult.error('$fieldName обязательно для заполнения');
    }
    if (value.length < min) {
      return ValidationResult.error('$fieldName должно содержать не менее $min символов');
    }
    return const ValidationResult.valid();
  }

  /// Validates email format
  static ValidationResult email(String? value) {
    if (value == null || value.isEmpty) return const ValidationResult.valid();
    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
    if (!emailRegex.hasMatch(value)) {
      return const ValidationResult.error('Некорректный формат email');
    }
    return const ValidationResult.valid();
  }

  /// Validates phone number format (Russian formats)
  static ValidationResult phone(String? value) {
    if (value == null || value.isEmpty) return const ValidationResult.valid();
    // Remove spaces, dashes, parentheses
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Check for Russian phone patterns: +7..., 8..., 7...
    final phoneRegex = RegExp(r'^(\+7|8|7)?\d{10}$');
    if (!phoneRegex.hasMatch(cleaned)) {
      return const ValidationResult.error('Некорректный формат телефона');
    }
    return const ValidationResult.valid();
  }

  /// Validates numeric format
  static ValidationResult numeric(String? value, {String fieldName = 'Поле'}) {
    if (value == null || value.isEmpty) return const ValidationResult.valid();
    // Allow both dot and comma as decimal separator
    final cleaned = value.replaceAll(',', '.');
    if (double.tryParse(cleaned) == null) {
      return ValidationResult.error('$fieldName должно быть числом');
    }
    return const ValidationResult.valid();
  }

  /// Validates positive number (including zero)
  static ValidationResult positiveNumber(String? value, {String fieldName = 'Поле'}) {
    if (value == null || value.isEmpty) return const ValidationResult.valid();
    final cleaned = value.replaceAll(',', '.');
    final number = double.tryParse(cleaned);
    if (number == null) {
      return ValidationResult.error('$fieldName должно быть числом');
    }
    if (number < 0) {
      return ValidationResult.error('$fieldName не может быть отрицательным');
    }
    return const ValidationResult.valid();
  }

  /// Validates number greater than zero
  static ValidationResult greaterThanZero(String? value, {String fieldName = 'Поле'}) {
    if (value == null || value.isEmpty) return const ValidationResult.valid();
    final cleaned = value.replaceAll(',', '.');
    final number = double.tryParse(cleaned);
    if (number == null) {
      return ValidationResult.error('$fieldName должно быть числом');
    }
    if (number <= 0) {
      return ValidationResult.error('$fieldName должно быть больше нуля');
    }
    return const ValidationResult.valid();
  }

  /// Validates inventory number format (alphanumeric with dashes, dots, slashes)
  static ValidationResult inventoryNumber(String? value) {
    if (value == null || value.isEmpty) return const ValidationResult.valid();
    final regex = RegExp(r'^[\w\-\.\/]+$');
    if (!regex.hasMatch(value)) {
      return const ValidationResult.error('Инвентарный номер содержит недопустимые символы');
    }
    return const ValidationResult.valid();
  }

  /// Validates serial number format (alphanumeric with dashes, dots, slashes)
  static ValidationResult serialNumber(String? value) {
    if (value == null || value.isEmpty) return const ValidationResult.valid();
    final regex = RegExp(r'^[\w\-\.\/]+$');
    if (!regex.hasMatch(value)) {
      return const ValidationResult.error('Серийный номер содержит недопустимые символы');
    }
    return const ValidationResult.valid();
  }

  // ==================== String?-returning field validators ====================

  /// Email field validator for forms (returns String? error message)
  static String? emailField(String? value) {
    final result = email(value);
    return result.isValid ? null : result.errorMessage;
  }

  /// Phone field validator for forms (returns String? error message)
  static String? phoneField(String? value) {
    final result = phone(value);
    return result.isValid ? null : result.errorMessage;
  }

  /// Inventory number field validator for forms (returns String? error message)
  static String? inventoryNumberField(String? value) {
    final result = inventoryNumber(value);
    return result.isValid ? null : result.errorMessage;
  }

  /// Serial number field validator for forms (returns String? error message)
  static String? serialNumberField(String? value) {
    final result = serialNumber(value);
    return result.isValid ? null : result.errorMessage;
  }

  /// Equipment name validator (min 2 chars, max 200)
  static String? equipmentName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Название оборудования обязательно для заполнения';
    }
    if (value.trim().length < 2) {
      return 'Название должно содержать не менее 2 символов';
    }
    if (value.length > 200) {
      return 'Название должно содержать не более 200 символов';
    }
    return null;
  }

  /// Full name validator (at least 2 words)
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ФИО обязательно для заполнения';
    }
    final words = value.trim().split(RegExp(r'\s+'));
    if (words.length < 2) {
      return 'Введите полное имя (фамилию и имя)';
    }
    return null;
  }

  /// Employee number validator (alphanumeric, max 50)
  static String? employeeNumber(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length > 50) {
      return 'Табельный номер должен содержать не более 50 символов';
    }
    final regex = RegExp(r'^[\w\-]+$');
    if (!regex.hasMatch(value)) {
      return 'Табельный номер содержит недопустимые символы';
    }
    return null;
  }

  /// Consumable name validator (min 1 char, max 200)
  static String? consumableName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Название расходника обязательно для заполнения';
    }
    if (value.length > 200) {
      return 'Название должно содержать не более 200 символов';
    }
    return null;
  }

  /// Quantity validator (positive number greater than 0)
  static String? quantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Количество обязательно для заполнения';
    }
    final cleaned = value.replaceAll(',', '.');
    final number = double.tryParse(cleaned);
    if (number == null) {
      return 'Количество должно быть числом';
    }
    if (number <= 0) {
      return 'Количество должно быть больше нуля';
    }
    return null;
  }

  /// Document number validator (alphanumeric with dashes and slashes)
  static String? documentNumber(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[\w\-\.\/]+$');
    if (!regex.hasMatch(value)) {
      return 'Номер документа содержит недопустимые символы';
    }
    return null;
  }

  /// Notes validator (max 1000 chars)
  static String? notes(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length > 1000) {
      return 'Примечания должны содержать не более 1000 символов';
    }
    return null;
  }

  // ==================== Map-based validators (for database operations) ====================

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

/// Builder class for chaining multiple validators
class ValidatorBuilder {
  final List<ValidationResult Function(String?)> _validators = [];

  /// Add required validation
  ValidatorBuilder required({String fieldName = 'Поле'}) {
    _validators.add((value) => Validators.required(value, fieldName: fieldName));
    return this;
  }

  /// Add minimum length validation
  ValidatorBuilder minLength(int min, {String fieldName = 'Поле'}) {
    _validators.add((value) => Validators.minLength(value, min, fieldName: fieldName));
    return this;
  }

  /// Add maximum length validation
  ValidatorBuilder maxLength(int max, {String fieldName = 'Поле'}) {
    _validators.add((value) => Validators.maxLength(value, max, fieldName: fieldName));
    return this;
  }

  /// Add email validation
  ValidatorBuilder email() {
    _validators.add(Validators.email);
    return this;
  }

  /// Build the validator function that returns String? for form usage
  String? Function(String?) build() {
    return (value) {
      for (final validator in _validators) {
        final result = validator(value);
        if (!result.isValid) {
          return result.errorMessage;
        }
      }
      return null;
    };
  }
}
