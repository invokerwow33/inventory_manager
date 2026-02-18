import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_manager/utils/validators.dart';

void main() {
  group('Validators', () {
    group('required', () {
      test('should return error for null value', () {
        final result = Validators.required(null);
        expect(result.isValid, false);
        expect(result.errorMessage, contains('обязательно'));
      });

      test('should return error for empty string', () {
        final result = Validators.required('');
        expect(result.isValid, false);
      });

      test('should return error for whitespace only', () {
        final result = Validators.required('   ');
        expect(result.isValid, false);
      });

      test('should return valid for non-empty string', () {
        final result = Validators.required('test');
        expect(result.isValid, true);
      });

      test('should use custom field name', () {
        final result = Validators.required(null, fieldName: 'Название');
        expect(result.errorMessage, contains('Название'));
      });
    });

    group('minLength', () {
      test('should return error for short string', () {
        final result = Validators.minLength('ab', 3);
        expect(result.isValid, false);
      });

      test('should return valid for exact length', () {
        final result = Validators.minLength('abc', 3);
        expect(result.isValid, true);
      });

      test('should return valid for longer string', () {
        final result = Validators.minLength('abcd', 3);
        expect(result.isValid, true);
      });
    });

    group('maxLength', () {
      test('should return error for long string', () {
        final result = Validators.maxLength('abcdef', 5);
        expect(result.isValid, false);
      });

      test('should return valid for exact length', () {
        final result = Validators.maxLength('abcde', 5);
        expect(result.isValid, true);
      });

      test('should return valid for shorter string', () {
        final result = Validators.maxLength('abcd', 5);
        expect(result.isValid, true);
      });

      test('should return valid for null value', () {
        final result = Validators.maxLength(null, 5);
        expect(result.isValid, true);
      });
    });

    group('email', () {
      test('should return valid for null value', () {
        final result = Validators.email(null);
        expect(result.isValid, true);
      });

      test('should return valid for empty string', () {
        final result = Validators.email('');
        expect(result.isValid, true);
      });

      test('should return valid for correct email', () {
        final result = Validators.email('test@example.com');
        expect(result.isValid, true);
      });

      test('should return error for invalid email', () {
        final result = Validators.email('invalid-email');
        expect(result.isValid, false);
      });

      test('should return error for email without @', () {
        final result = Validators.email('testexample.com');
        expect(result.isValid, false);
      });

      test('should return error for email without domain', () {
        final result = Validators.email('test@');
        expect(result.isValid, false);
      });
    });

    group('phone', () {
      test('should return valid for null value', () {
        final result = Validators.phone(null);
        expect(result.isValid, true);
      });

      test('should return valid for correct phone', () {
        final result = Validators.phone('+79001234567');
        expect(result.isValid, true);
      });

      test('should return valid for phone with spaces', () {
        final result = Validators.phone('+7 900 123 45 67');
        expect(result.isValid, true);
      });

      test('should return valid for phone with dashes', () {
        final result = Validators.phone('8-900-123-45-67');
        expect(result.isValid, true);
      });

      test('should return error for invalid phone', () {
        final result = Validators.phone('abc');
        expect(result.isValid, false);
      });
    });

    group('numeric', () {
      test('should return valid for null value', () {
        final result = Validators.numeric(null);
        expect(result.isValid, true);
      });

      test('should return valid for integer', () {
        final result = Validators.numeric('123');
        expect(result.isValid, true);
      });

      test('should return valid for decimal', () {
        final result = Validators.numeric('123.45');
        expect(result.isValid, true);
      });

      test('should return valid for decimal with comma', () {
        final result = Validators.numeric('123,45');
        expect(result.isValid, true);
      });

      test('should return error for non-numeric', () {
        final result = Validators.numeric('abc');
        expect(result.isValid, false);
      });
    });

    group('positiveNumber', () {
      test('should return valid for positive number', () {
        final result = Validators.positiveNumber('100');
        expect(result.isValid, true);
      });

      test('should return valid for zero', () {
        final result = Validators.positiveNumber('0');
        expect(result.isValid, true);
      });

      test('should return error for negative number', () {
        final result = Validators.positiveNumber('-10');
        expect(result.isValid, false);
      });

      test('should return error for non-numeric', () {
        final result = Validators.positiveNumber('abc');
        expect(result.isValid, false);
      });
    });

    group('greaterThanZero', () {
      test('should return valid for positive number', () {
        final result = Validators.greaterThanZero('100');
        expect(result.isValid, true);
      });

      test('should return error for zero', () {
        final result = Validators.greaterThanZero('0');
        expect(result.isValid, false);
      });

      test('should return error for negative number', () {
        final result = Validators.greaterThanZero('-10');
        expect(result.isValid, false);
      });
    });

    group('inventoryNumber', () {
      test('should return valid for null value', () {
        final result = Validators.inventoryNumber(null);
        expect(result.isValid, true);
      });

      test('should return valid for alphanumeric', () {
        final result = Validators.inventoryNumber('INV-123-ABC');
        expect(result.isValid, true);
      });

      test('should return valid with dots', () {
        final result = Validators.inventoryNumber('INV.123.456');
        expect(result.isValid, true);
      });

      test('should return error for special characters', () {
        final result = Validators.inventoryNumber('INV@123');
        expect(result.isValid, false);
      });
    });

    group('serialNumber', () {
      test('should return valid for alphanumeric with slashes', () {
        final result = Validators.serialNumber('SN/2023/12345');
        expect(result.isValid, true);
      });

      test('should return error for special characters', () {
        final result = Validators.serialNumber('SN@123');
        expect(result.isValid, false);
      });
    });

    group('equipmentName', () {
      test('should return error for empty name', () {
        final result = Validators.equipmentName('');
        expect(result, isNotNull);
      });

      test('should return error for short name', () {
        final result = Validators.equipmentName('A');
        expect(result, isNotNull);
      });

      test('should return null for valid name', () {
        final result = Validators.equipmentName('Laptop Dell');
        expect(result, isNull);
      });
    });

    group('fullName', () {
      test('should return error for empty name', () {
        final result = Validators.fullName('');
        expect(result, isNotNull);
      });

      test('should return error for single word', () {
        final result = Validators.fullName('Иванов');
        expect(result, isNotNull);
      });

      test('should return null for full name', () {
        final result = Validators.fullName('Иванов Иван Иванович');
        expect(result, isNull);
      });

      test('should return null for two words', () {
        final result = Validators.fullName('Иванов Иван');
        expect(result, isNull);
      });
    });

    group('consumableName', () {
      test('should return error for empty name', () {
        final result = Validators.consumableName('');
        expect(result, isNotNull);
      });

      test('should return null for valid name', () {
        final result = Validators.consumableName('A4 Paper');
        expect(result, isNull);
      });
    });

    group('quantity', () {
      test('should return error for empty value', () {
        final result = Validators.quantity('');
        expect(result, isNotNull);
      });

      test('should return error for zero', () {
        final result = Validators.quantity('0');
        expect(result, isNotNull);
      });

      test('should return error for negative', () {
        final result = Validators.quantity('-5');
        expect(result, isNotNull);
      });

      test('should return null for positive number', () {
        final result = Validators.quantity('10');
        expect(result, isNull);
      });
    });

    group('documentNumber', () {
      test('should return null for empty value', () {
        final result = Validators.documentNumber('');
        expect(result, isNull);
      });

      test('should return null for valid number', () {
        final result = Validators.documentNumber('DOC-123/2023');
        expect(result, isNull);
      });

      test('should return error for special characters', () {
        final result = Validators.documentNumber('DOC@123');
        expect(result, isNotNull);
      });
    });

    group('notes', () {
      test('should return null for empty value', () {
        final result = Validators.notes('');
        expect(result, isNull);
      });

      test('should return null for valid notes', () {
        final result = Validators.notes('Some notes here');
        expect(result, isNull);
      });
    });
  });

  group('ValidatorBuilder', () {
    test('should build validator with required', () {
      final validator = ValidatorBuilder()
          .required(fieldName: 'Test')
          .build();

      expect(validator(''), isNotNull);
      expect(validator('value'), isNull);
    });

    test('should build validator with multiple rules', () {
      final validator = ValidatorBuilder()
          .required(fieldName: 'Email')
          .email()
          .build();

      expect(validator(''), isNotNull);
      expect(validator('invalid'), isNotNull);
      expect(validator('test@example.com'), isNull);
    });

    test('should build validator with min and max length', () {
      final validator = ValidatorBuilder()
          .minLength(3, fieldName: 'Field')
          .maxLength(10, fieldName: 'Field')
          .build();

      expect(validator('ab'), isNotNull);
      expect(validator('abcdefghijk'), isNotNull);
      expect(validator('abcde'), isNull);
    });
  });
}
