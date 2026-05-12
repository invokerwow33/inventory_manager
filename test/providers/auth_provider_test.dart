import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_manager/providers/auth_provider.dart';

void main() {
  group('AuthProvider', () {
    late AuthProvider provider;

    setUp(() {
      provider = AuthProvider();
    });

    test('should not be authenticated initially', () {
      expect(provider.isAuthenticated, false);
      expect(provider.currentUser, isNull);
      expect(provider.currentSession, isNull);
      expect(provider.isAdmin, false);
      expect(provider.isManager, false);
    });

    test('should have correct initial state', () {
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });

    test('should clear error', () {
      provider.clearError();
      expect(provider.error, isNull);
    });
  });

  group('AuthProvider Permissions', () {
    late AuthProvider provider;

    setUp(() {
      provider = AuthProvider();
    });

    test('isAdmin should be false when not authenticated', () {
      expect(provider.isAdmin, false);
    });

    test('isManager should be false when not authenticated', () {
      expect(provider.isManager, false);
    });
  });

  group('AuthProvider Login/Logout', () {
    late AuthProvider provider;

    setUp(() {
      provider = AuthProvider();
    });

    test('logout should clear user and session', () async {
      await provider.logout();
      expect(provider.isAuthenticated, false);
      expect(provider.currentUser, isNull);
      expect(provider.currentSession, isNull);
    });
  });
}
