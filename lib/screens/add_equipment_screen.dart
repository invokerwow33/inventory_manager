import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/equipment.dart';
import '../providers/equipment_provider.dart';
import '../utils/validators.dart';
import '../widgets/common/common_widgets.dart';

class AddEquipmentScreen extends StatefulWidget {
  final Map<String, dynamic>? equipment;
  
  const AddEquipmentScreen({super.key, this.equipment});
  
  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _serialNumberController;
  late final TextEditingController _inventoryNumberController;
  late final TextEditingController _manufacturerController;
  late final TextEditingController _modelController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _departmentController;
  late final TextEditingController _responsiblePersonController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;
  
  // Form values
  EquipmentType _type = EquipmentType.computer;
  EquipmentStatus _status = EquipmentStatus.inUse;
  DateTime? _purchaseDate;
  bool _isEditMode = false;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.equipment != null;
    
    // Initialize controllers
    _nameController = TextEditingController();
    _serialNumberController = TextEditingController();
    _inventoryNumberController = TextEditingController();
    _manufacturerController = TextEditingController();
    _modelController = TextEditingController();
    _purchasePriceController = TextEditingController();
    _departmentController = TextEditingController();
    _responsiblePersonController = TextEditingController();
    _locationController = TextEditingController();
    _notesController = TextEditingController();
    
    if (_isEditMode && widget.equipment != null) {
      _loadEquipmentData();
    } else {
      // Generate ID and inventory number for new equipment
      _editingId = 'eq_${DateTime.now().millisecondsSinceEpoch}';
      _generateInventoryNumber();
    }
  }

  void _loadEquipmentData() {
    _editingId = widget.equipment!['id']?.toString();
    _nameController.text = widget.equipment!['name'] ?? '';
    
    // Parse type
    final typeString = widget.equipment!['type'] ?? 'computer';
    _type = EquipmentType.values.firstWhere(
      (e) => e.toString().split('.').last == typeString,
      orElse: () => EquipmentType.computer,
    );
    
    // Parse status
    final statusString = widget.equipment!['status'] ?? 'inUse';
    _status = EquipmentStatus.values.firstWhere(
      (e) => e.toString().split('.').last == statusString,
      orElse: () => EquipmentStatus.inUse,
    );
    
    _serialNumberController.text = widget.equipment!['serialNumber'] ?? '';
    _inventoryNumberController.text = widget.equipment!['inventoryNumber'] ?? '';
    _manufacturerController.text = widget.equipment!['manufacturer'] ?? '';
    _modelController.text = widget.equipment!['model'] ?? '';
    
    if (widget.equipment!['purchaseDate'] != null) {
      _purchaseDate = DateTime.tryParse(widget.equipment!['purchaseDate']);
    }
    
    _purchasePriceController.text = widget.equipment!['purchasePrice']?.toString() ?? '';
    _departmentController.text = widget.equipment!['department'] ?? '';
    _responsiblePersonController.text = widget.equipment!['responsiblePerson'] ?? '';
    _locationController.text = widget.equipment!['location'] ?? '';
    _notesController.text = widget.equipment!['notes'] ?? '';
  }
  
  Future<void> _generateInventoryNumber() async {
    try {
      final count = await _dbHelper.getEquipmentCount();
      setState(() {
        _inventoryNumberController.text = 'INV-${DateTime.now().year}-${(count + 1).toString().padLeft(5, '0')}';
      });
    } catch (e) {
      setState(() {
        _inventoryNumberController.text = 'INV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialNumberController.dispose();
    _inventoryNumberController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _purchasePriceController.dispose();
    _departmentController.dispose();
    _responsiblePersonController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _saveEquipment() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final now = DateTime.now();
      
      final equipment = Equipment(
        id: _editingId!,
        name: _nameController.text.trim(),
        type: _type,
        serialNumber: _serialNumberController.text.trim().isEmpty 
            ? null 
            : _serialNumberController.text.trim(),
        inventoryNumber: _inventoryNumberController.text.trim().isEmpty 
            ? null 
            : _inventoryNumberController.text.trim(),
        manufacturer: _manufacturerController.text.trim().isEmpty 
            ? null 
            : _manufacturerController.text.trim(),
        model: _modelController.text.trim().isEmpty 
            ? null 
            : _modelController.text.trim(),
        purchaseDate: _purchaseDate,
        purchasePrice: _purchasePriceController.text.isEmpty 
            ? null 
            : double.tryParse(_purchasePriceController.text.replaceAll(',', '.')),
        department: _departmentController.text.trim().isEmpty 
            ? null 
            : _departmentController.text.trim(),
        responsiblePerson: _responsiblePersonController.text.trim().isEmpty 
            ? null 
            : _responsiblePersonController.text.trim(),
        location: _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
        status: _status,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        createdAt: _isEditMode 
            ? DateTime.parse(widget.equipment!['createdAt'] ?? now.toIso8601String())
            : now,
        updatedAt: now,
      );
      
      try {
        final provider = context.read<EquipmentProvider>();
        
        if (_isEditMode) {
          await provider.updateEquipment(equipment);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Оборудование обновлено')),
            );
          }
        } else {
          await provider.addEquipment(equipment);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Оборудование добавлено')),
            );
          }
        }
        
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка сохранения: $e')),
          );
        }
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
              FormSectionCard(
                title: 'Основная информация',
                icon: Icons.info_outline,
                children: [
                  ValidationTextField.required(
                    label: 'Название оборудования',
                    controller: _nameController,
                    minLength: 2,
                    maxLength: 200,
                    prefixIcon: const Icon(Icons.devices_outlined),
                  ),
                  
                  FormDropdown<EquipmentType>(
                    label: 'Тип оборудования',
                    value: _type,
                    items: EquipmentType.values,
                    displayMapper: (type) => type.label,
                    iconMapper: (type) => Icon(type.icon, size: 20),
                    onChanged: (value) => setState(() => _type = value!),
                  ),
                  
                  FormDropdown<EquipmentStatus>(
                    label: 'Статус',
                    value: _status,
                    items: EquipmentStatus.values,
                    displayMapper: (status) => status.label,
                    iconMapper: (status) => Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onChanged: (value) => setState(() => _status = value!),
                  ),
                  
                  ValidationTextField(
                    label: 'Инвентарный номер',
                    controller: _inventoryNumberController,
                    prefixIcon: const Icon(Icons.qr_code_outlined),
                    validator: Validators.inventoryNumberField,
                  ),
                  
                  ValidationTextField(
                    label: 'Серийный номер',
                    controller: _serialNumberController,
                    prefixIcon: const Icon(Icons.tag_outlined),
                    validator: Validators.serialNumberField,
                  ),
                ],
              ),
              
              // Производитель и модель
              FormSectionCard(
                title: 'Производитель и модель',
                icon: Icons.build_outlined,
                children: [
                  ValidationTextField(
                    label: 'Производитель',
                    controller: _manufacturerController,
                    prefixIcon: const Icon(Icons.business_outlined),
                    validator: (value) {
                      final result = Validators.maxLength(value, 100, fieldName: 'Производитель');
                      return result.isValid ? null : result.errorMessage;
                    },
                  ),
                  
                  ValidationTextField(
                    label: 'Модель',
                    controller: _modelController,
                    prefixIcon: const Icon(Icons.category_outlined),
                    validator: (value) {
                      final result = Validators.maxLength(value, 100, fieldName: 'Модель');
                      return result.isValid ? null : result.errorMessage;
                    },
                  ),
                ],
              ),
              
              // Приобретение и стоимость
              FormSectionCard(
                title: 'Приобретение и стоимость',
                icon: Icons.shopping_cart_outlined,
                children: [
                  DatePickerField(
                    label: 'Дата приобретения',
                    date: _purchaseDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    onDateSelected: (date) => setState(() => _purchaseDate = date),
                  ),
                  
                  ValidationTextField.number(
                    label: 'Стоимость (₽)',
                    controller: _purchasePriceController,
                    positiveOnly: true,
                    fieldName: 'Стоимость',
                    prefixIcon: const Icon(Icons.currency_ruble),
                  ),
                ],
              ),
              
              // Расположение и ответственные
              FormSectionCard(
                title: 'Расположение и ответственные',
                icon: Icons.location_on_outlined,
                children: [
                  ValidationTextField(
                    label: 'Отдел/Подразделение',
                    controller: _departmentController,
                    prefixIcon: const Icon(Icons.account_balance_outlined),
                    validator: (value) {
                      final result = Validators.maxLength(value, 100, fieldName: 'Отдел/Подразделение');
                      return result.isValid ? null : result.errorMessage;
                    },
                  ),
                  
                  ValidationTextField(
                    label: 'Ответственное лицо',
                    controller: _responsiblePersonController,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (value) {
                      final result = Validators.maxLength(value, 100, fieldName: 'Ответственное лицо');
                      return result.isValid ? null : result.errorMessage;
                    },
                  ),
                  
                  ValidationTextField(
                    label: 'Местоположение',
                    controller: _locationController,
                    prefixIcon: const Icon(Icons.place_outlined),
                    validator: (value) {
                      final result = Validators.maxLength(value, 200, fieldName: 'Местоположение');
                      return result.isValid ? null : result.errorMessage;
                    },
                  ),
                ],
              ),
              
              // Дополнительная информация
              FormSectionCard(
                title: 'Дополнительная информация',
                icon: Icons.notes_outlined,
                children: [
                  ValidationTextField(
                    label: 'Примечания',
                    controller: _notesController,
                    maxLines: 4,
                    prefixIcon: const Icon(Icons.edit_note),
                    validator: Validators.notes,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Кнопки действий
              FormActions(
                onSave: _saveEquipment,
                saveLabel: _isEditMode ? 'Сохранить изменения' : 'Добавить оборудование',
                showCancel: _isEditMode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
