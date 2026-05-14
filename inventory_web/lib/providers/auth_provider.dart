import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = StorageService();
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _storage.initialize();
      
      final userId = _storage.getCurrentUserId();
      if (userId != null) {
        final users = _storage.getUsers();
        _currentUser = users.firstWhere(
          (u) => u.id == userId,
          orElse: () => throw Exception('User not found'),
        );
      }
    } catch (e) {
      _error = 'Ошибка инициализации: $e';
      debugPrint('[Auth] Ошибка инициализации: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _storage.getUserByUsername(username);
      
      if (user == null) {
        _error = 'Пользователь не найден';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!user.isActive) {
        _error = 'Пользователь деактивирован';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!_storage.verifyPassword(password, user.passwordHash)) {
        _error = 'Неверный пароль';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      await _storage.setCurrentUserId(user.id);
      
      debugPrint('[Auth] Вход выполнен: ${user.username}');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка входа: $e';
      debugPrint('[Auth] Ошибка входа: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.setCurrentUserId(null);
    _currentUser = null;
    _error = null;
    debugPrint('[Auth] Выход выполнен');
    notifyListeners();
  }

  Future<bool> createUser({
    required String username,
    required String password,
    required String fullName,
    String role = 'user',
  }) async {
    try {
      final existingUser = _storage.getUserByUsername(username);
      if (existingUser != null) {
        _error = 'Пользователь с таким именем уже существует';
        notifyListeners();
        return false;
      }

      final user = User(
        id: const Uuid().v4(),
        username: username,
        passwordHash: _hashPassword(password),
        fullName: fullName,
        role: role,
        createdAt: DateTime.now(),
      );

      await _storage.saveUser(user);
      debugPrint('[Auth] Пользователь создан: $username');
      return true;
    } catch (e) {
      _error = 'Ошибка создания пользователя: $e';
      debugPrint('[Auth] Ошибка создания: $e');
      notifyListeners();
      return false;
    }
  }

  String _hashPassword(String password) {
    // Простое хеширование для демонстрации
    return base64Encode(utf8.encode(password));
  }
}
