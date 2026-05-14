import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/location.dart';
import '../services/storage_service.dart';

class LocationProvider extends ChangeNotifier {
  final _storage = StorageService();
  List<Location> _locations = [];
  bool _isLoading = false;
  String? _error;

  List<Location> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLocations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = _storage.getLocations();
      _locations = data.map((item) => Location.fromMap(item)).toList();
      
      // Создаем локации по умолчанию если пустой список
      if (_locations.isEmpty) {
        await _createDefaultLocations();
      }
      
      debugPrint('[Location] Загружено ${_locations.length} локаций');
    } catch (e) {
      _error = 'Ошибка загрузки: $e';
      debugPrint('[Location] Ошибка загрузки: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _createDefaultLocations() async {
    final defaultLocations = [
      Location(
        id: const Uuid().v4(),
        name: 'Склад',
        description: 'Основной склад',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Location(
        id: const Uuid().v4(),
        name: 'Офис',
        description: 'Офисные помещения',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Location(
        id: const Uuid().v4(),
        name: 'Архив',
        description: 'Архивное помещение',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (final location in defaultLocations) {
      await _storage.saveLocation(location.toMap());
      _locations.add(location);
    }
    
    debugPrint('[Location] Созданы локации по умолчанию');
  }

  Future<bool> addLocation({
    required String name,
    String? description,
    String? parentId,
  }) async {
    try {
      final item = Location(
        id: const Uuid().v4(),
        name: name,
        description: description,
        parentId: parentId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _storage.saveLocation(item.toMap());
      _locations.add(item);
      
      debugPrint('[Location] Добавлена: $name');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка добавления: $e';
      debugPrint('[Location] Ошибка добавления: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLocation(String id, {
    String? name,
    String? description,
    String? parentId,
  }) async {
    try {
      final index = _locations.indexWhere((l) => l.id == id);
      if (index < 0) {
        _error = 'Локация не найдена';
        notifyListeners();
        return false;
      }

      final item = _locations[index].copyWith(
        name: name,
        description: description,
        parentId: parentId,
        updatedAt: DateTime.now(),
      );

      await _storage.saveLocation(item.toMap());
      _locations[index] = item;
      
      debugPrint('[Location] Обновлена: $name');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка обновления: $e';
      debugPrint('[Location] Ошибка обновления: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteLocation(String id) async {
    try {
      await _storage.deleteLocation(id);
      _locations.removeWhere((l) => l.id == id);
      
      debugPrint('[Location] Удалена: $id');
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Ошибка удаления: $e';
      debugPrint('[Location] Ошибка удаления: $e');
      notifyListeners();
      return false;
    }
  }

  Location? getById(String id) {
    try {
      return _locations.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  String? getNameById(String id) {
    final location = getById(id);
    return location?.name;
  }
}
