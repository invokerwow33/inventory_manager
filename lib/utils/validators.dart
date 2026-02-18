class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.valid()
      : isValid = true,
        errorMessage = null;

  const ValidationResult.invalid(this.errorMessage) : isValid = false;
}

abstract class Validators {
  // Common validators
  static ValidationResult required(String? value, {String fieldName = 'Поле'}) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.invalid('$fieldName обязательно для заполнения');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult minLength(String? value, int minLength, {String fieldName = 'Поле'}) {
    if (value == null || value.length < minLength) {
      return ValidationResult.invalid('$fieldName должно содержать минимум $minLength символов');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult maxLength(String? value, int maxLength, {String fieldName = 'Поле'}) {
    if (value != null && value.length > maxLength) {
      return ValidationResult.invalid('$fieldName не должно превышать $maxLength символов');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult email(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.valid();
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return const ValidationResult.invalid('Введите корректный email адрес');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult phone(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.valid();
    }
    // Russian phone number format
    final phoneRegex = RegExp(r'^[\+]?[0-9\s\-\(\)]{7,20}$');
    if (!phoneRegex.hasMatch(value)) {
      return const ValidationResult.invalid('Введите корректный номер телефона');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult numeric(String? value, {String fieldName = 'Поле'}) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.valid();
    }
    if (double.tryParse(value.replaceAll(',', '.')) == null) {
      return ValidationResult.invalid('$fieldName должно быть числом');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult positiveNumber(String? value, {String fieldName = 'Поле'}) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.valid();
    }
    final number = double.tryParse(value.replaceAll(',', '.'));
    if (number == null) {
      return ValidationResult.invalid('$fieldName должно быть числом');
    }
    if (number < 0) {
      return ValidationResult.invalid('$fieldName должно быть положительным числом');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult greaterThanZero(String? value, {String fieldName = 'Поле'}) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.valid();
    }
    final number = double.tryParse(value.replaceAll(',', '.'));
    if (number == null) {
      return ValidationResult.invalid('$fieldName должно быть числом');
    }
    if (number <= 0) {
      return ValidationResult.invalid('$fieldName должно быть больше нуля');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult inventoryNumber(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.valid();
    }
    // Allow alphanumeric, dashes, and dots
    final regex = RegExp(r'^[a-zA-Z0-9\-\.]+$');
    if (!regex.hasMatch(value)) {
      return const ValidationResult.invalid(
          'Инвентарный номер может содержать только буквы, цифры, дефисы и точки');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult serialNumber(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.valid();
    }
    // Allow alphanumeric, dashes, dots, and slashes
    final regex = RegExp(r'^[a-zA-Z0-9\-\.\/]+$');
    if (!regex.hasMatch(value)) {
      return const ValidationResult.invalid(
          'Серийный номер может содержать только буквы, цифры, дефисы, точки и слеши');
    }
    return const ValidationResult.valid();
  }

  // Equipment-specific validators
  static String? equipmentName(String? value) {
    final result = required(value, fieldName: 'Название оборудования');
    if (!result.isValid) return result.errorMessage;

    final lengthResult = minLength(value, 2, fieldName: 'Название оборудования');
    if (!lengthResult.isValid) return lengthResult.errorMessage;

    final maxResult = maxLength(value, 200, fieldName: 'Название оборудования');
    if (!maxResult.isValid) return maxResult.errorMessage;

    return null;
  }

  static String? inventoryNumberField(String? value) {
    final result = inventoryNumber(value);
    if (!result.isValid) return result.errorMessage;
    return null;
  }

  static String? serialNumberField(String? value) {
    final result = serialNumber(value);
    if (!result.isValid) return result.errorMessage;
    return null;
  }

  static String? price(String? value) {
    final result = positiveNumber(value, fieldName: 'Стоимость');
    if (!result.isValid) return result.errorMessage;
    return null;
  }

  // Employee-specific validators
  static String? fullName(String? value) {
    final result = required(value, fieldName: 'ФИО');
    if (!result.isValid) return result.errorMessage;

    final lengthResult = minLength(value, 3, fieldName: 'ФИО');
    if (!lengthResult.isValid) return lengthResult.errorMessage;

    final maxResult = maxLength(value, 200, fieldName: 'ФИО');
    if (!maxResult.isValid) return maxResult.errorMessage;

    // Check for at least two words
    final words = value!.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length < 2) {
      return 'Введите полное ФИО (минимум имя и фамилия)';
    }

    return null;
  }

  static String? employeeNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final regex = RegExp(r'^[a-zA-Z0-9\-]+$');
    if (!regex.hasMatch(value)) {
      return 'Табельный номер может содержать только буквы, цифры и дефисы';
    }
    return null;
  }

  static String? emailField(String? value) {
    final result = email(value);
    if (!result.isValid) return result.errorMessage;
    return null;
  }

  static String? phoneField(String? value) {
    final result = phone(value);
    if (!result.isValid) return result.errorMessage;
    return null;
  }

  // Consumable-specific validators
  static String? consumableName(String? value) {
    final result = required(value, fieldName: 'Название расходника');
    if (!result.isValid) return result.errorMessage;

    final lengthResult = minLength(value, 2, fieldName: 'Название расходника');
    if (!lengthResult.isValid) return lengthResult.errorMessage;

    final maxResult = maxLength(value, 200, fieldName: 'Название расходника');
    if (!maxResult.isValid) return maxResult.errorMessage;

    return null;
  }

  static String? quantity(String? value) {
    final result = required(value, fieldName: 'Количество');
    if (!result.isValid) return result.errorMessage;

    final numResult = greaterThanZero(value, fieldName: 'Количество');
    if (!numResult.isValid) return numResult.errorMessage;

    return null;
  }

  static String? minQuantity(String? value) {
    final result = positiveNumber(value, fieldName: 'Минимальное количество');
    if (!result.isValid) return result.errorMessage;
    return null;
  }

  static String? consumableQuantity(String? value, {required bool isIncoming}) {
    final result = required(value, fieldName: 'Количество');
    if (!result.isValid) return result.errorMessage;

    final numResult = greaterThanZero(value, fieldName: 'Количество');
    if (!numResult.isValid) return numResult.errorMessage;

    return null;
  }

  // Document validators
  static String? documentNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final regex = RegExp(r'^[a-zA-Z0-9\-\/]+$');
    if (!regex.hasMatch(value)) {
      return 'Номер документа может содержать только буквы, цифры, дефисы и слеши';
    }
    return null;
  }

  static String? notes(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final maxResult = maxLength(value, 2000, fieldName: 'Примечания');
    if (!maxResult.isValid) return maxResult.errorMessage;
    return null;
  }
}

// Extension for easy use with FormField validators
typedef ValidatorFunction = String? Function(String?);

class ValidatorBuilder {
  final List<ValidationResult Function(String?)> _validators = [];

  ValidatorBuilder required({String fieldName = 'Поле'}) {
    _validators.add((value) => Validators.required(value, fieldName: fieldName));
    return this;
  }

  ValidatorBuilder minLength(int length, {String fieldName = 'Поле'}) {
    _validators.add((value) => Validators.minLength(value, length, fieldName: fieldName));
    return this;
  }

  ValidatorBuilder maxLength(int length, {String fieldName = 'Поле'}) {
    _validators.add((value) => Validators.maxLength(value, length, fieldName: fieldName));
    return this;
  }

  ValidatorBuilder email() {
    _validators.add((value) => Validators.email(value));
    return this;
  }

  ValidatorBuilder phone() {
    _validators.add((value) => Validators.phone(value));
    return this;
  }

  ValidatorBuilder positiveNumber({String fieldName = 'Поле'}) {
    _validators.add((value) => Validators.positiveNumber(value, fieldName: fieldName));
    return this;
  }

  String? Function(String?) build() {
    return (String? value) {
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
