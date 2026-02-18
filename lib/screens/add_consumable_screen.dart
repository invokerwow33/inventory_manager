import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/consumable.dart';
import '../providers/consumable_provider.dart';
import '../utils/validators.dart';
import '../widgets/common/common_widgets.dart';

class AddConsumableScreen extends StatefulWidget {
  final Consumable? consumable;
  
  const AddConsumableScreen({super.key, this.consumable});
  
  @override
  State<AddConsumableScreen> createState() => _AddConsumableScreenState();
}

class _AddConsumableScreenState extends State<AddConsumableScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minQuantityController;
  late final TextEditingController _supplierController;
  late final TextEditingController _notesController;
  
  // Form values
  ConsumableCategory _category = ConsumableCategory.other;
  ConsumableUnit _unit = ConsumableUnit.pieces;
  bool get _isEditMode => widget.consumable != null;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _nameController = TextEditingController();
    _quantityController = TextEditingController(text: '0');
    _minQuantityController = TextEditingController(text: '0');
    _supplierController = TextEditingController();
    _notesController = TextEditingController();
    
    if (_isEditMode && widget.consumable != null) {
      _editingId = widget.consumable!.id;
      _nameController.text = widget.consumable!.name;
      _category = widget.consumable!.category;
      _unit = widget.consumable!.unit;
      _quantityController.text = widget.consumable!.quantity.toString();
      _minQuantityController.text = widget.consumable!.minQuantity.toString();
      _supplierController.text = widget.consumable!.supplier ?? '';
      _notesController.text = widget.consumable!.notes ?? '';
    } else {
      _editingId = 'cons_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _supplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveConsumable() async {
    if (!_formKey.currentState!.validate()) return;
    
    final now = DateTime.now();
    
    final quantity = double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0;
    final minQuantity = double.tryParse(_minQuantityController.text.replaceAll(',', '.')) ?? 0;
    
    final consumable = Consumable(
      id: _editingId!,
      name: _nameController.text.trim(),
      category: _category,
      unit: _unit,
      quantity: quantity,
      minQuantity: minQuantity,
      supplier: _supplierController.text.trim().isEmpty 
          ? null 
          : _supplierController.text.trim(),
      notes: _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim(),
      createdAt: _isEditMode ? widget.consumable!.createdAt : now,
      updatedAt: now,
    );
    
    try {
      final provider = context.read<ConsumableProvider>();
      
      if (_isEditMode) {
        await provider.updateConsumable(consumable);
      } else {
        await provider.addConsumable(consumable);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Расходник обновлен' : 'Расходник добавлен'),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Редактировать расходник' : 'Добавить расходник'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveConsumable,
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
                icon: Icons.inventory_2_outlined,
                children: [
                  ValidationTextField.required(
                    label: 'Название',
                    controller: _nameController,
                    minLength: 2,
                    maxLength: 200,
                    prefixIcon: const Icon(Icons.label_outline),
                    validator: Validators.consumableName,
                  ),
                  
                  FormDropdown<ConsumableCategory>(
                    label: 'Категория',
                    value: _category,
                    items: ConsumableCategory.values,
                    displayMapper: (category) => category.label,
                    iconMapper: (category) => Icon(category.icon, 
                      color: category.color, 
                      size: 20,
                    ),
                    onChanged: (value) => setState(() => _category = value!),
                  ),
                  
                  FormDropdown<ConsumableUnit>(
                    label: 'Единица измерения',
                    value: _unit,
                    items: ConsumableUnit.values,
                    displayMapper: (unit) => '${unit.shortLabel} (${unit.fullLabel})',
                    onChanged: (value) => setState(() => _unit = value!),
                  ),
                ],
              ),
              
              // Количество
              FormSectionCard(
                title: 'Количество',
                icon: Icons.balance_outlined,
                children: [
                  ValidationTextField.number(
                    label: 'Текущее количество',
                    controller: _quantityController,
                    positiveOnly: true,
                    fieldName: 'Количество',
                    prefixIcon: const Icon(Icons.format_list_numbered),
                  ),
                  
                  ValidationTextField.number(
                    label: 'Минимальное количество',
                    controller: _minQuantityController,
                    positiveOnly: true,
                    fieldName: 'Минимальное количество',
                    prefixIcon: const Icon(Icons.warning_amber),
                  ),
                  
                  if (_isEditMode && widget.consumable != null)
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text(
                        widget.consumable!.isLowStock 
                            ? 'Текущее количество ниже минимального'
                            : 'Текущее количество в норме',
                        style: TextStyle(
                          color: widget.consumable!.isLowStock 
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              
              // Поставщик
              FormSectionCard(
                title: 'Поставщик',
                icon: Icons.local_shipping_outlined,
                children: [
                  ValidationTextField(
                    label: 'Название поставщика',
                    controller: _supplierController,
                    prefixIcon: const Icon(Icons.business_outlined),
                    maxLength: 200,
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
                onSave: _saveConsumable,
                saveLabel: _isEditMode ? 'Сохранить изменения' : 'Добавить расходник',
                showCancel: _isEditMode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
