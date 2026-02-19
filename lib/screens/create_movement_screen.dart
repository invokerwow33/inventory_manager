import 'package:flutter/material.dart';
import 'package:inventory_manager/database/simple_database_helper.dart';
import 'package:inventory_manager/screens/equipment_selection_screen.dart'; // Исправленный импорт
import 'package:intl/intl.dart';

class CreateMovementScreen extends StatefulWidget {
  final Map<String, dynamic>? equipment;
  final String? preselectedResponsible;
  
  const CreateMovementScreen({Key? key, this.equipment, this.preselectedResponsible}) : super(key: key);

  @override
  _CreateMovementScreenState createState() => _CreateMovementScreenState();
}

class _CreateMovementScreenState extends State<CreateMovementScreen> {
  final _formKey = GlobalKey<FormState>();
  final SimpleDatabaseHelper _dbHelper = SimpleDatabaseHelper();
  
  // Контроллеры
  final TextEditingController _equipmentController = TextEditingController();
  final TextEditingController _fromLocationController = TextEditingController();
  final TextEditingController _toLocationController = TextEditingController();
  final TextEditingController _fromResponsibleController = TextEditingController();
  final TextEditingController _toResponsibleController = TextEditingController();
  final TextEditingController _documentNumberController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  // Переменные состояния
  String _movementType = 'Перемещение';
  DateTime _movementDate = DateTime.now();
  Map<String, dynamic>? _selectedEquipment;
  bool _isLoading = false;
  
  final List<String> _movementTypes = [
    'Перемещение',
    'Выдача',
    'Возврат',
    'Списание',
  ];

  @override
  void initState() {
    super.initState();
    _dbHelper.initDatabase();
    
    // Если передано оборудование, заполняем данные
    if (widget.equipment != null) {
      _selectedEquipment = widget.equipment;
      _equipmentController.text = widget.equipment!['name']?.toString() ?? '';
      _fromLocationController.text = widget.equipment!['location']?.toString() ?? '';
      _fromResponsibleController.text = widget.equipment!['responsible_person']?.toString() ?? '';
    }
    
    // Если передан ответственный (из карточки сотрудника)
    if (widget.preselectedResponsible != null) {
      _toResponsibleController.text = widget.preselectedResponsible!;
    }
  }

  Future<void> _selectEquipment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          final selectedId = _selectedEquipment?['id']?.toString();
          return EquipmentSelectionScreen(
            selectedEquipmentIds: selectedId != null && selectedId.isNotEmpty
                ? [selectedId]
                : [],
            multipleSelection: false, // Для перемещения выбираем только одно оборудование
          );
        },
      ),
    );
    
    if (result != null && result is List && result.isNotEmpty) {
      // Загружаем детали выбранного оборудования
      final selectedId = result.first;
      if (selectedId == null) {
        return;
      }
      await _loadSelectedEquipment(selectedId.toString());
    }
  }

  Future<void> _loadSelectedEquipment(String equipmentId) async {
    try {
      final equipment = await _dbHelper.getEquipmentById(equipmentId);
      if (equipment != null && mounted) {
        setState(() {
          _selectedEquipment = equipment;
          _equipmentController.text = equipment['name']?.toString() ?? '';
          _fromLocationController.text = equipment['location']?.toString() ?? '';
          _fromResponsibleController.text = equipment['responsible_person']?.toString() ?? '';
        });
      }
    } catch (e) {
      print('Ошибка загрузки оборудования: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки оборудования: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _movementDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _movementDate) {
      setState(() {
        _movementDate = picked;
      });
    }
  }

  Future<void> _saveMovement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите оборудование')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final movement = {
        'equipment_id': _selectedEquipment!['id'],
        'equipment_name': _selectedEquipment!['name'],
        'from_location': _fromLocationController.text.trim(),
        'to_location': _toLocationController.text.trim(),
        'from_responsible': _fromResponsibleController.text.trim(),
        'to_responsible': _toResponsibleController.text.trim(),
        'movement_date': _movementDate.toIso8601String(),
        'movement_type': _movementType,
        'document_number': _documentNumberController.text.trim(),
        'notes': _notesController.text.trim(),
      };

      // Сохраняем перемещение
      await _dbHelper.addMovement(movement);
      
      // Обновляем данные оборудования (если это не списание)
      if (_movementType != 'Списание') {
        final updatedEquipment = Map<String, dynamic>.from(_selectedEquipment!);
        updatedEquipment['location'] = _toLocationController.text.trim();
        updatedEquipment['responsible_person'] = _toResponsibleController.text.trim();
        
        // Если оборудование выдается, меняем статус
        if (_movementType == 'Выдача') {
          updatedEquipment['status'] = 'В использовании';
        } else if (_movementType == 'Возврат') {
          updatedEquipment['status'] = 'На складе';
        }
        
        updatedEquipment['id'] = _selectedEquipment!['id'];
        await _dbHelper.safeUpdateEquipment(updatedEquipment);
      } else {
        // Для списания меняем статус
        final updatedEquipment = Map<String, dynamic>.from(_selectedEquipment!);
        updatedEquipment['status'] = 'Списано';
        updatedEquipment['id'] = _selectedEquipment!['id'];
        await _dbHelper.safeUpdateEquipment(updatedEquipment);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Перемещение "${_movementType.toLowerCase()}" сохранено'),
            duration: const Duration(seconds: 2),
          ),
        );

        // Возвращаемся назад
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Ошибка сохранения перемещения: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать перемещение'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveMovement,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Оборудование
            InkWell(
              onTap: _selectEquipment,
              child: IgnorePointer(
                child: TextFormField(
                  controller: _equipmentController,
                  decoration: InputDecoration(
                    labelText: 'Оборудование *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.devices),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _selectEquipment,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Выберите оборудование';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Тип перемещения
            DropdownButtonFormField<String>(
              value: _movementType,
              decoration: const InputDecoration(
                labelText: 'Тип перемещения *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.swap_horiz),
              ),
              items: _movementTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _movementType = value ?? 'Перемещение';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Выберите тип перемещения';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Дата перемещения
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Дата перемещения',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd.MM.yyyy').format(_movementDate),
                    ),
                    const Icon(Icons.calendar_today, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Откуда (текущее местоположение)
            TextFormField(
              controller: _fromLocationController,
              decoration: const InputDecoration(
                labelText: 'Откуда (текущее местоположение) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите текущее местоположение';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Куда (новое местоположение)
            TextFormField(
              controller: _toLocationController,
              decoration: const InputDecoration(
                labelText: 'Куда (новое местоположение) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите новое местоположение';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Ответственный от
            TextFormField(
              controller: _fromResponsibleController,
              decoration: const InputDecoration(
                labelText: 'Ответственный (от кого)',
                hintText: 'Иванов Иван Иванович',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // Ответственный кому
            TextFormField(
              controller: _toResponsibleController,
              decoration: const InputDecoration(
                labelText: 'Ответственный (кому)',
                hintText: 'Петров Петр Петрович',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // Номер документа
            TextFormField(
              controller: _documentNumberController,
              decoration: const InputDecoration(
                labelText: 'Номер документа (акта/накладной)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),

            // Примечания
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Примечания',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // Предупреждение для списания
            if (_movementType == 'Списание')
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Внимание: При списании оборудование будет помечено как "Списано"',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Сохранить перемещение'),
                    onPressed: _isLoading ? null : _saveMovement,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Отмена'),
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}