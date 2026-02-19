import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import '../models/sync_queue.dart';

class SyncProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Connectivity _connectivity = Connectivity();
  
  List<SyncQueueItem> _pendingItems = [];
  List<SyncConflict> _conflicts = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  bool _isOnline = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _autoSyncTimer;
  
  DateTime? _lastSync;
  int _pendingCount = 0;
  int _syncedCount = 0;
  int _failedCount = 0;

  // Getters
  List<SyncQueueItem> get pendingItems => _pendingItems;
  List<SyncConflict> get conflicts => _conflicts;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  bool get isOnline => _isOnline;
  DateTime? get lastSync => _lastSync;
  int get pendingCount => _pendingCount;
  int get syncedCount => _syncedCount;
  int get failedCount => _failedCount;
  bool get hasPendingItems => _pendingItems.isNotEmpty;
  bool get hasConflicts => _conflicts.isNotEmpty;

  SyncProvider() {
    _initConnectivity();
    loadPendingItems();
  }

  void _initConnectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
      
      if (_isOnline && hasPendingItems) {
        sync();
      }
    });
  }

  void startAutoSync({int intervalMinutes = 15}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(Duration(minutes: intervalMinutes), (_) {
      if (_isOnline && hasPendingItems) {
        sync();
      }
    });
  }

  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  Future<void> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    notifyListeners();
  }

  Future<void> loadPendingItems() async {
    _setLoading(true);
    try {
      final data = await _dbHelper.getPendingSyncItems();
      _pendingItems = data.map((m) => SyncQueueItem.fromMap(m)).toList();
      _pendingCount = _pendingItems.length;
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки очереди синхронизации: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<String> queueOperation({
    required SyncOperationType operation,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? data,
    SyncPriority priority = SyncPriority.normal,
    String? deviceId,
    String? userId,
  }) async {
    final item = SyncQueueItem(
      id: 'sync_${DateTime.now().millisecondsSinceEpoch}_${_pendingItems.length}',
      operation: operation,
      entityType: entityType,
      entityId: entityId,
      data: data,
      priority: priority,
      createdAt: DateTime.now(),
      deviceId: deviceId,
      userId: userId,
    );

    try {
      await _dbHelper.addToSyncQueue(item.toMap());
      _pendingItems.add(item);
      _pendingCount = _pendingItems.length;
      notifyListeners();
      
      // Try to sync immediately if online
      if (_isOnline) {
        sync();
      }
      
      return item.id;
    } catch (e) {
      _setError('Ошибка добавления в очередь: $e');
      rethrow;
    }
  }

  Future<void> sync() async {
    if (_isSyncing || !_isOnline || _pendingItems.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    try {
      // Sort by priority
      _pendingItems.sort((a, b) => b.priority.value.compareTo(a.priority.value));
      
      for (final item in _pendingItems.where((i) => i.status == SyncStatus.pending)) {
        if (!_isOnline) break;
        
        await _processSyncItem(item);
      }

      _lastSync = DateTime.now();
      await loadPendingItems(); // Refresh list
    } catch (e) {
      _setError('Ошибка синхронизации: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _processSyncItem(SyncQueueItem item) async {
    try {
      await _dbHelper.updateSyncItemStatus(item.id, 'syncing');
      
      // Simulate sync operation - in production, this would call your API
      await Future.delayed(Duration(milliseconds: 100));
      
      // Mark as completed
      await _dbHelper.updateSyncItemStatus(item.id, 'completed');
      await _dbHelper.deleteSyncItem(item.id);
      
      _syncedCount++;
      
    } catch (e) {
      _failedCount++;
      await _dbHelper.incrementRetryCount(item.id);
      await _dbHelper.updateSyncItemStatus(
        item.id, 
        'failed',
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> resolveConflict(String conflictId, {required bool useLocal}) async {
    try {
      // Find and resolve conflict
      final conflictIndex = _conflicts.indexWhere((c) => c.id == conflictId);
      if (conflictIndex != -1) {
        final conflict = _conflicts[conflictIndex];
        final resolved = SyncConflict(
          id: conflict.id,
          entityType: conflict.entityType,
          entityId: conflict.entityId,
          localData: conflict.localData,
          remoteData: conflict.remoteData,
          localTimestamp: conflict.localTimestamp,
          remoteTimestamp: conflict.remoteTimestamp,
          isResolved: true,
          resolution: useLocal ? 'local' : 'remote',
          resolvedData: useLocal ? jsonEncode(conflict.localData) : jsonEncode(conflict.remoteData),
          createdAt: conflict.createdAt,
          resolvedAt: DateTime.now(),
        );
        
        _conflicts[conflictIndex] = resolved;
        
        // Update the sync queue item
        final item = _pendingItems.firstWhere(
          (i) => i.entityId == conflict.entityId && i.entityType == conflict.entityType,
          orElse: () => throw Exception('Sync item not found'),
        );
        
        await _dbHelper.updateSyncItemStatus(item.id, 'pending');
        notifyListeners();
      }
    } catch (e) {
      _setError('Ошибка разрешения конфликта: $e');
    }
  }

  Future<void> retryFailed() async {
    final failed = _pendingItems.where((i) => i.status == SyncStatus.failed).toList();
    
    for (final item in failed) {
      if (item.canRetry) {
        await _dbHelper.updateSyncItemStatus(item.id, 'pending');
      }
    }
    
    await loadPendingItems();
    if (_isOnline) {
      await sync();
    }
  }

  Future<void> clearCompleted() async {
    try {
      final completed = _pendingItems.where((i) => i.status == SyncStatus.completed).toList();
      for (final item in completed) {
        await _dbHelper.deleteSyncItem(item.id);
      }
      await loadPendingItems();
    } catch (e) {
      _setError('Ошибка очистки завершенных: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      for (final item in _pendingItems) {
        await _dbHelper.deleteSyncItem(item.id);
      }
      _pendingItems.clear();
      _pendingCount = 0;
      notifyListeners();
    } catch (e) {
      _setError('Ошибка очистки очереди: $e');
    }
  }

  // P2P sync methods for LAN synchronization
  Future<void> startP2PSyncServer(int port) async {
    // Implementation for starting a local HTTP server for P2P sync
    // This would use the shelf package
  }

  Future<void> discoverP2PDevices() async {
    // Implementation for discovering other devices on the local network
  }

  Future<void> syncWithDevice(String deviceIp, int port) async {
    // Implementation for syncing with a specific device
  }

  // Cloud sync methods
  Future<void> syncWithCloud() async {
    if (!_isOnline) {
      _setError('Нет подключения к интернету');
      return;
    }
    
    _isSyncing = true;
    notifyListeners();
    
    try {
      // Implementation for cloud sync
      // This would use Dio to communicate with your cloud API
      await Future.delayed(Duration(seconds: 2)); // Placeholder
      
      _lastSync = DateTime.now();
    } catch (e) {
      _setError('Ошибка синхронизации с облаком: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}
