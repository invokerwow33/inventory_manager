import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../database/database_helper.dart';
import '../models/equipment.dart';

class AddEquipmentScreen extends StatefulWidget {
  final Map<String, dynamic>? equipment;
  
  const AddEquipmentScreen({super.key, this.equipment});
  
  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  // Поля формы
  String _name = '';
  EquipmentType _type = EquipmentType.computer;
  String? _serialNumber;
  String? _inventoryNumber;
  String? _manufacturer;
  String? _model;
  DateTime? _purchaseDate;
  double? _purchasePrice;
  String? _department;
  String? _responsiblePerson;
  String? _location;
  EquipmentStatus _status = EquipmentStatus.inUse;
  String? _notes;
  
  bool _isEditMode = false;
  String? _editingId;
  
  @override
  void initState() {
    super.initState();
    _isEditMode = widget.equipment != null;
    
    if (_isEditMode && widget.equipment != null) {
      // Загружаем данные из Map
      _editingId = widget.equipment!['id'];
      _name = widget.equipment!['name'] ?? '';
      
      // Преобразуем строку типа в EquipmentType
      final typeString = widget.equipment!['type'] ?? 'computer';
      _type = EquipmentType.values.firstWhere(
        (e) => e.toString().split('.').last == typeString,
        orElse: () => EquipmentType.computer,
      );
      
      // Преобразуем строку статуса в EquipmentStatus
      final statusString = widget.equipment!['status'] ?? 'inUse';
      _status = EquipmentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == statusString,
        orElse: () => EquipmentStatus.inUse,
      );
      
      _serialNumber = widget.equipment!['serialNumber'];
      _inventoryNumber = widget.equipment!['inventoryNumber'];
      _manufacturer = widget.equipment!['manufacturer'];
      _model = widget.equipment!['model'];
      
      if (widget.equipment!['purchaseDate'] != null) {
        _purchaseDate = DateTime.tryParse(widget.equipment!['purchaseDate']);
      }
      
      _purchasePrice = widget.equipment!['purchasePrice']?.toDouble();
      _department = widget.equipment!['department'];
      _responsiblePerson = widget.equipment!['responsiblePerson'];
      _location = widget.equipment!['location'];
      _notes = widget.equipment!['notes'];
    } else {
      // Генерируем ID для нового оборудования
      _editingId = 'eq_${DateTime.now().millisecondsSinceEpoch}';
      // Генерируем инвентарный номер
      _generateInventoryNumber();
    }
  }
  
  Future<void> _generateInventoryNumber() async {
    try {
      final count = await _dbHelper.getEquipmentCount();
      setState(() {
        _inventoryNumber = 'INV-${DateTime.now().year}-${(count + 1).toString().padLeft(5, '0')}';
      });
    } catch (e) {
      // Если не удалось получить количество, используем простой номер
      setState(() {
        _inventoryNumber = 'INV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      });
    }
  }
  
  Future<void> _saveEquipment() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final now = DateTime.now();
      
      final equipment = Equipment(
        id: _editingId!,
        name: _name,
        type: _type,
        serialNumber: _serialNumber,
        inventoryNumber: _inventoryNumber,
        manufacturer: _manufacturer,
        model: _model,
        purchaseDate: _purchaseDate,
        purchasePrice: _purchasePrice,
        department: _department,
        responsiblePerson: _responsiblePerson,
        location: _location,
        status: _status,
        notes: _notes,
        createdAt: _isEditMode 
            ? DateTime.parse(widget.equipment!['createdAt'] ?? now.toIso8601String())
            : now,
        updatedAt: now,
      );
      
      try {
        if (_isEditMode) {
          // Обновляем существующее оборудование
          await _dbHelper.updateEquipment(equipment);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Оборудование обновлено')),
          );
        } else {
          // Добавляем новое оборудование
          await _dbHelper.insertEquipment(equipment);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Оборудование добавлено')),
          );
        }
        
        Navigator.pop(context, true); // Возвращаем успешный результат
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Редактировать оборудование' : 'Добавить оборудование'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveEquipment,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Основная информация
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Основная информация',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Название оборудования *',
                        initialValue: _name,
                        onSaved: (value) => _name = value!,
                        validator: (value) => value!.isEmpty ? 'Введите название' : null,
                      ),
                      
                      _buildDropdown<EquipmentType>(
                        label: 'Тип оборудования',
                        value: _type,
                        items: EquipmentType.values,
                        itemBuilder: (type) => DropdownMenuItem<EquipmentType>(
                          value: type,
                          child: Row(
                            children: [
                              Icon(type.icon, size: 20),
                              const SizedBox(width: 8),
                              Text(type.label),
                            ],
                          ),
                        ),
                        onChanged: (value) => setState(() => _type = value!),
                      ),
                      
                      _buildDropdown<EquipmentStatus>(
                        label: 'Статус',
                        value: _status,
                        items: EquipmentStatus.values,
                        itemBuilder: (status) => DropdownMenuItem<EquipmentStatus>(
                          value: status,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: status.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(status.label),
                            ],
                          ),
                        ),
                        onChanged: (value) => setState(() => _status = value!),
                      ),
                      
                      _buildTextField(
                        label: 'Инвентарный номер',
                        initialValue: _inventoryNumber,
                        onSaved: (value) => _inventoryNumber = value,
                      ),
                      
                      _buildTextField(
                        label: 'Серийный номер',
                        initialValue: _serialNumber,
                        onSaved: (value) => _serialNumber = value,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Производитель и модель
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Производитель и модель',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Производитель',
                        initialValue: _manufacturer,
                        onSaved: (value) => _manufacturer = value,
                      ),
                      
                      _buildTextField(
                        label: 'Модель',
                        initialValue: _model,
                        onSaved: (value) => _model = value,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Приобретение и стоимость
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Приобретение и стоимость',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildDatePicker(
                        label: 'Дата приобретения',
                        date: _purchaseDate,
                        onDateSelected: (date) => setState(() => _purchaseDate = date),
                      ),
                      
                      _buildTextField(
                        label: 'Стоимость (₽)',
                        initialValue: _purchasePrice?.toString(),
                        keyboardType: TextInputType.number,
                        onSaved: (value) {
                          if (value != null && value.isNotEmpty) {
                            _purchasePrice = double.tryParse(value.replaceAll(',', '.'));
                          } else {
                            _purchasePrice = null;
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Расположение и ответственные
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Расположение и ответственные',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Отдел/Подразделение',
                        initialValue: _department,
                        onSaved: (value) => _department = value,
                      ),
                      
                      _buildTextField(
                        label: 'Ответственное лицо',
                        initialValue: _responsiblePerson,
                        onSaved: (value) => _responsiblePerson = value,
                      ),
                      
                      _buildTextField(
                        label: 'Местоположение',
                        initialValue: _location,
                        onSaved: (value) => _location = value,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Дополнительная информация
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Дополнительная информация',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Примечания',
                        initialValue: _notes,
                        maxLines: 4,
                        onSaved: (value) => _notes = value,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Кнопка сохранения
              ElevatedButton.icon(
                onPressed: _saveEquipment,
                icon: const Icon(Icons.save),
                label: const Text('Сохранить оборудование'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              const SizedBox(height: 16),
              
              if (_isEditMode)
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Отмена'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required String label,
    String? initialValue,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    required void Function(String?) onSaved,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        initialValue: initialValue,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }
  
  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required DropdownMenuItem<T> Function(T) itemBuilder,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        value: value,
        items: items.map(itemBuilder).toList(),
        onChanged: onChanged,
        isExpanded: true,
      ),
    );
  }
  
Widget _buildDatePicker({
    required String label,
    DateTime? date,
    required void Function(DateTime?) onDateSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _showDatePicker(context, date, onDateSelected),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      date != null 
                          ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}'
                          : 'Выберите дату',
                      style: TextStyle(
                        fontSize: 16,
                        color: date != null ? Colors.black : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _showDatePicker(
    BuildContext context, 
    DateTime? currentDate,
    void Function(DateTime?) onDateSelected,
  ) async {
    DateTime? selectedDate = currentDate ?? DateTime.now();
  
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.4,
        child: Column(
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена', style: TextStyle(color: Colors.white)),
                  ),
                  const Text(
                    'Выберите дату',
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      onDateSelected(selectedDate);
                      Navigator.pop(context);
                    },
                    child: const Text('Готово', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          
            // Датапикер
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: currentDate ?? DateTime.now(),
                minimumDate: DateTime(2000),
                maximumDate: DateTime.now(),
                onDateTimeChanged: (DateTime newDate) {
                  selectedDate = newDate;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
}