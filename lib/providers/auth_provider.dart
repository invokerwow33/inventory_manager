import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../database/database_helper.dart';
import '../models/user.dart';
import '../services/audit_service.dart';

class AuthProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AuditService _auditService = AuditService();
  
  User? _currentUser;
  UserSession? _currentSession;
  bool _isLoading = false;
  String? _error;
  Timer? _sessionTimer;
  int _sessionTimeoutMinutes = 30;

  // Getters
  User? get currentUser => _currentUser;
  UserSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null && _currentSession != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isManager => _currentUser?.isManager ?? false;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString('current_session');
    final userJson = prefs.getString('current_user');
    
    if (sessionJson != null && userJson != null) {
      try {
        _currentSession = UserSession.fromMap(jsonDecode(sessionJson));
        _currentUser = User.fromMap(jsonDecode(userJson));
        
        if (_currentSession!.isExpired) {
          await logout();
        } else {
          _startSessionTimer();
          notifyListeners();
        }
      } catch (e) {
        await logout();
      }
    }
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentSession != null && _currentUser != null) {
      await prefs.setString('current_session', jsonEncode(_currentSession!.toMap()));
      await prefs.setString('current_user', jsonEncode(_currentUser!.toMap()));
    } else {
      await prefs.remove('current_session');
      await prefs.remove('current_user');
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(Duration(minutes: _sessionTimeoutMinutes), () {
      logout();
    });
  }

  void _resetSessionTimer() {
    _startSessionTimer();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final userData = await _dbHelper.getUserByUsername(username);
      
      if (userData == null) {
        _setError('Пользователь не найден');
        return false;
      }

      final user = User.fromMap(userData);
      
      if (!user.isActive) {
        _setError('Пользователь заблокирован');
        return false;
      }

      // In production, use bcrypt for proper password hashing
      // For now, using simple SHA256 for demonstration
      if (!_verifyPassword(password, user.passwordHash)) {
        _setError('Неверный пароль');
        await _auditService.logLoginAttempt(username, false);
        return false;
      }

      _currentUser = user;
      _currentSession = UserSession(
        id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.id,
        token: _generateToken(),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(minutes: _sessionTimeoutMinutes)),
      );

      await _dbHelper.updateLastLogin(user.id);
      await _saveSession();
      await _auditService.logLogin(user.id, user.username);
      
      _startSessionTimer();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Ошибка входа: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    if (_currentUser != null) {
      await _auditService.logLogout(_currentUser!.id, _currentUser!.username);
    }
    
    _sessionTimer?.cancel();
    _currentUser = null;
    _currentSession = null;
    await _saveSession();
    notifyListeners();
  }

  Future<bool> createUser({
    required String username,
    required String password,
    String? email,
    UserRole role = UserRole.user,
    String? employeeId,
  }) async {
    if (!isAdmin) {
      _setError('Недостаточно прав');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final existingUser = await _dbHelper.getUserByUsername(username);
      if (existingUser != null) {
        _setError('Пользователь с таким именем уже существует');
        return false;
      }

      final user = User(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        email: email,
        passwordHash: _hashPassword(password),
        role: role,
        isActive: true,
        employeeId: employeeId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _dbHelper.insertUser(user.toMap());
      await _auditService.logUserCreated(
        currentUser!.id,
        user.id,
        username,
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Ошибка создания пользователя: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUser(User user) async {
    if (!isAdmin && currentUser?.id != user.id) {
      _setError('Недостаточно прав');
      return false;
    }

    _setLoading(true);
    try {
      await _dbHelper.updateUser(user.toMap());
      
      if (currentUser?.id == user.id) {
        _currentUser = user;
        await _saveSession();
      }
      
      await _auditService.logUserUpdated(currentUser!.id, user.id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Ошибка обновления пользователя: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword(String userId, String newPassword) async {
    if (!isAdmin && currentUser?.id != userId) {
      _setError('Недостаточно прав');
      return false;
    }

    try {
      final userData = await _dbHelper.getUserById(userId);
      if (userData == null) return false;

      final user = User.fromMap(userData);
      final updatedUser = user.copyWith(
        passwordHash: _hashPassword(newPassword),
        updatedAt: DateTime.now(),
      );

      await _dbHelper.updateUser(updatedUser.toMap());
      await _auditService.logPasswordChanged(currentUser!.id, userId);
      return true;
    } catch (e) {
      _setError('Ошибка изменения пароля: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    if (!isAdmin) {
      _setError('Недостаточно прав');
      return false;
    }

    if (userId == currentUser?.id) {
      _setError('Нельзя удалить текущего пользователя');
      return false;
    }

    try {
      await _dbHelper.deleteUser(userId);
      await _auditService.logUserDeleted(currentUser!.id, userId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Ошибка удаления пользователя: $e');
      return false;
    }
  }

  Future<List<User>> getUsers() async {
    try {
      final data = await _dbHelper.getUsers(includeInactive: true);
      return data.map((m) => User.fromMap(m)).toList();
    } catch (e) {
      _setError('Ошибка загрузки пользователей: $e');
      return [];
    }
  }

  Future<User?> getUserById(String id) async {
    try {
      final data = await _dbHelper.getUserById(id);
      return data != null ? User.fromMap(data) : null;
    } catch (e) {
      return null;
    }
  }

  void checkPermission(String action) {
    if (!isAuthenticated) {
      throw Exception('Требуется авторизация');
    }
    
    switch (action) {
      case 'admin':
        if (!isAdmin) throw Exception('Требуются права администратора');
        break;
      case 'manage':
        if (!isManager) throw Exception('Требуются права менеджера');
        break;
      case 'write':
        if (_currentUser!.role == UserRole.user && !isManager) {
          throw Exception('Недостаточно прав для записи');
        }
        break;
    }
  }

  bool hasPermission(String action) {
    if (!isAuthenticated) return false;
    
    switch (action) {
      case 'admin':
        return isAdmin;
      case 'manage':
        return isManager;
      case 'write':
        return _currentUser!.role != UserRole.user || isManager;
      case 'read':
        return true;
      default:
        return false;
    }
  }

  String _generateToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    final data = utf8.encode('$timestamp$random${_currentUser?.id}');
    return sha256.convert(data).toString();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void recordActivity() {
    _resetSessionTimer();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
