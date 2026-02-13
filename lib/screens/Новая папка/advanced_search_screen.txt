import 'package:flutter/material.dart';
import 'package:inventory_manager/database/simple_database_helper.dart';
import 'package:intl/intl.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({Key? key}) : super(key: key);

  @override
  _AdvancedSearchScreenState createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final SimpleDatabaseHelper _dbHelper = SimpleDatabaseHelper();
  
  // Поля поиска
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _responsibleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String _selectedStatus = 'Любой';
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _searchInNotes = true;
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];
  int _resultsCount = 0;

  final List<String> _statusOptions = [
    'Любой',
    'На складе',
    'В использовании',
    'В ремонте',
    'Списано',
    'В резерве'
  ];

  final List<String> _categoryOptions = [
    'Любая',
    'Компьютеры',
    'Ноутбуки',
    'Серверы',
    'Сетевое оборудование',
    'Периферия',
    'Оргтехника',
    'Мебель',
    'Инструменты',
    'Другое'
  ];

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _searchResults = [];
      _resultsCount = 0;
    });

    try {
      await _dbHelper.initDatabase();
      final allEquipment = await _dbHelper.getEquipment();
      
      final filtered = allEquipment.where((item) {
        // Поиск по названию
        if (_nameController.text.isNotEmpty) {
          final name = item['name']?.toString().toLowerCase() ?? '';
          if (!name.contains(_nameController.text.toLowerCase())) {
            return false;
          }
        }
        
        // Поиск по категории
        if (_categoryController.text.isNotEmpty && _categoryController.text != 'Любая') {
          final category = item['category']?.toString() ?? '';
          if (category != _categoryController.text) {
            return false;
          }
        }
        
        // Поиск по серийному номеру
        if (_serialController.text.isNotEmpty) {
          final serial = item['serial_number']?.toString().toLowerCase() ?? '';
          if (!serial.contains(_serialController.text.toLowerCase())) {
            return false;
          }
        }
        
        // Поиск по ответственному
        if (_responsibleController.text.isNotEmpty) {
          final responsible = item['responsible_person']?.toString().toLowerCase() ?? '';
          if (!responsible.contains(_responsibleController.text.toLowerCase())) {
            return false;
          }
        }
        
        // Поиск по местоположению
        if (_locationController.text.isNotEmpty) {
          final location = item['location']?.toString().toLowerCase() ?? '';
          if (!location.contains(_locationController.text.toLowerCase())) {
            return false;
          }
        }
        
        // Поиск по статусу
        if (_selectedStatus != 'Любой') {
          final status = item['status']?.toString() ?? '';
          if (status != _selectedStatus) {
            return false;
          }
        }
        
        // Поиск по примечаниям
        if (_notesController.text.isNotEmpty && _searchInNotes) {
          final notes = item['notes']?.toString().toLowerCase() ?? '';
          if (!notes.contains(_notesController.text.toLowerCase())) {
            return false;
          }
        }
        
        // Фильтр по дате покупки
        if (_dateFrom != null || _dateTo != null) {
          final purchaseDateStr = item['purchase_date']?.toString();
          if (purchaseDateStr != null && purchaseDateStr.isNotEmpty) {
            try {
              final purchaseDate = DateTime.parse(purchaseDateStr);
              
              if (_dateFrom != null && purchaseDate.isBefore(_dateFrom!)) {
                return false;
              }
              
              if (_dateTo != null && purchaseDate.isAfter(_dateTo!)) {
                return false;
              }
            } catch (e) {
              // Если дата не парсится, пропускаем фильтр
            }
          }
        }
        
        return true;
      }).toList();
      
      setState(() {
        _searchResults = filtered;
        _resultsCount = filtered.length;
      });
      
    } catch (e) {
      print('Ошибка поиска: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_dateFrom ?? DateTime.now()) : (_dateTo ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _nameController.clear();
      _categoryController.clear();
      _serialController.clear();
      _responsibleController.clear();
      _locationController.clear();
      _notesController.clear();
      _selectedStatus = 'Любой';
      _dateFrom = null;
      _dateTo = null;
      _searchInNotes = true;
      _searchResults = [];
      _resultsCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Расширенный поиск'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _performSearch,
            tooltip: 'Выполнить поиск',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearFilters,
            tooltip: 'Очистить фильтры',
          ),
        ],
      ),
      body: Column(
        children: [
          // Фильтры
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Быстрые фильтры
                  const Text(
                    'Быстрый поиск',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Название',
                            prefixIcon: Icon(Icons.devices),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _serialController,
                          decoration: const InputDecoration(
                            labelText: 'Серийный номер',
                            prefixIcon: Icon(Icons.confirmation_number),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Расширенные фильтры
                  const Text(
                    'Расширенные фильтры',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  // Категория и статус
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _categoryController.text.isEmpty 
                              ? 'Любая' 
                              : _categoryController.text,
                          decoration: const InputDecoration(
                            labelText: 'Категория',
                            border: OutlineInputBorder(),
                          ),
                          items: _categoryOptions.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _categoryController.text = value ?? '';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Статус',
                            border: OutlineInputBorder(),
                          ),
                          items: _statusOptions.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value ?? 'Любой';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Ответственный и местоположение
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _responsibleController,
                          decoration: const InputDecoration(
                            labelText: 'Ответственный',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Местоположение',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Диапазон дат
                  const Text(
                    'Дата покупки',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'От',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _dateFrom != null
                                      ? DateFormat('dd.MM.yyyy').format(_dateFrom!)
                                      : 'Выберите дату',
                                ),
                                const Icon(Icons.calendar_today, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'До',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _dateTo != null
                                      ? DateFormat('dd.MM.yyyy').format(_dateTo!)
                                      : 'Выберите дату',
                                ),
                                const Icon(Icons.calendar_today, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Поиск в примечаниях
                  Row(
                    children: [
                      Checkbox(
                        value: _searchInNotes,
                        onChanged: (value) {
                          setState(() {
                            _searchInNotes = value ?? true;
                          });
                        },
                      ),
                      const Text('Искать в примечаниях'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Текст в примечаниях',
                            border: OutlineInputBorder(),
                          ),
                          enabled: _searchInNotes,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Кнопки
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text('Поиск'),
                          onPressed: _isLoading ? null : _performSearch,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.clear),
                          label: const Text('Очистить'),
                          onPressed: _clearFilters,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Результаты
          Expanded(
            flex: 3,
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_searchResults.isEmpty && _resultsCount == 0) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Введите параметры поиска',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'и нажмите кнопку "Поиск"',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Найдено: $_resultsCount',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_resultsCount > 0)
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Экспорт'),
                  onPressed: _exportResults,
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final equipment = _searchResults[index];
              final status = equipment['status']?.toString() ?? 'Не указан';
              
              Color _getStatusColor(String status) {
                switch (status) {
                  case 'В использовании': return Colors.green;
                  case 'На складе': return Colors.blue;
                  case 'В ремонте': return Colors.orange;
                  case 'Списано': return Colors.red;
                  case 'В резерве': return Colors.purple;
                  default: return Colors.grey;
                }
              }
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(status).withOpacity(0.1),
                    child: Icon(
                      Icons.devices,
                      color: _getStatusColor(status),
                    ),
                  ),
                  title: Text(
                    equipment['name']?.toString() ?? 'Без названия',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Категория: ${equipment['category'] ?? 'Не указана'}'),
                      if (equipment['serial_number']?.toString().isNotEmpty ?? false)
                        Text('Серийный: ${equipment['serial_number']}'),
                      Text('Статус: $status'),
                      if (equipment['responsible_person']?.toString().isNotEmpty ?? false)
                        Text('Ответственный: ${equipment['responsible_person']}'),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Можно добавить навигацию к деталям
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _exportResults() async {
    if (_searchResults.isEmpty) return;
    
    // Здесь можно реализовать экспорт результатов
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Экспорт ${_searchResults.length} записей')),
    );
  }
}