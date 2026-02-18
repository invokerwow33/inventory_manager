import 'package:flutter/material.dart';
import 'package:inventory_manager/database/simple_database_helper.dart';
import 'package:inventory_manager/models/consumable.dart';

class AddConsumableScreen extends StatefulWidget {
  final Consumable? consumable;
  
  const AddConsumableScreen({super.key, this.consumable});
  
  @override
  State<AddConsumableScreen> createState() => _AddConsumableScreenState();
}

class _AddConsumableScreenState extends State<AddConsumableScreen> {
  final _formKey = GlobalKey<FormState>();
  final SimpleDatabaseHelper _dbHelper = SimpleDatabaseHelper();
  
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _minQuantityController;
  late TextEditingController _supplierController;
  late TextEditingController _notesController;
  
  ConsumableCategory _category = ConsumableCategory.other;
  ConsumableUnit _unit = ConsumableUnit.pieces;
  
  bool get _isEditMode => widget.consumable != null;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    
    if (_isEditMode && widget.consumable != null) {
      _editingId = widget.consumable!.id;
      _nameController = TextEditingController(text: widget.consumable!.name);
      _quantityController = TextEditingController(text: widget.consumable!.quantity.toString());
      _minQuantityController = TextEditingController(text: widget.consumable!.minQuantity.toString());
      _supplierController = TextEditingController(text: widget.consumable!.supplier ?? '');
      _notesController = TextEditingController(text: widget.consumable!.notes ?? '');
      _category = widget.consumable!.category;
      _unit = widget.consumable!.unit;
    } else {
      _editingId = 'cons_${DateTime.now().millisecondsSinceEpoch}';
      _nameController = TextEditingController();
      _quantityController = TextEditingController(text: '0');
      _minQuantityController = TextEditingController(text: '0');
      _supplierController = TextEditingController();
      _notesController = TextEditingController();
    }
  }

  Future<void> _saveConsumable() async {
    if (!_formKey.currentState!.validate()) return;
    
    final now = DateTime.now();
    
    final consumable = Consumable(
      id: _editingId!,
      name: _nameController.text.trim(),
      category: _category,
      unit: _unit,
      quantity: double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0,
      minQuantity: double.tryParse(_minQuantityController.text.replaceAll(',', '.')) ?? 0,
      supplier: _supplierController.text.trim().isEmpty ? null : _supplierController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: _isEditMode ? widget.consumable!.createdAt : now,
      updatedAt: now,
    );
    
    try {
      if (_isEditMode) {
        await _dbHelper.updateConsumable(consumable.toMap());
      } else {
        await _dbHelper.insertConsumable(consumable.toMap());
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
                      
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Название *',
                          border: OutlineInputBorder(),
                          hintText: 'Например: Картридж HP 305A Black',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите название';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<ConsumableCategory>(
                        decoration: const InputDecoration(
                          labelText: 'Категория',
                          border: OutlineInputBorder(),
                        ),
                        value: _category,
                        items: ConsumableCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Icon(category.icon, size: 20, color: category.color),
                                const SizedBox(width: 8),
                                Text(category.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _category = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<ConsumableUnit>(
                        decoration: const InputDecoration(
                          labelText: 'Единица измерения',
                          border: OutlineInputBorder(),
                        ),
                        value: _unit,
                        items: ConsumableUnit.values.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text('${unit.shortLabel} (${unit.fullLabel})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _unit = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Количество',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              decoration: InputDecoration(
                                labelText: 'Текущий остаток *',
                                border: const OutlineInputBorder(),
                                suffixText: _unit.shortLabel,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Введите количество';
                                }
                                final number = double.tryParse(value.replaceAll(',', '.'));
                                if (number == null || number < 0) {
                                  return 'Введите корректное число';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _minQuantityController,
                              decoration: InputDecoration(
                                labelText: 'Мин. остаток',
                                border: const OutlineInputBorder(),
                                suffixText: _unit.shortLabel,
                                helperText: 'Для уведомлений',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final number = double.tryParse(value.replaceAll(',', '.'));
                                  if (number == null || number < 0) {
                                    return 'Введите корректное число';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
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
                      
                      TextFormField(
                        controller: _supplierController,
                        decoration: const InputDecoration(
                          labelText: 'Поставщик',
                          border: OutlineInputBorder(),
                          hintText: 'Название компании-поставщика',
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Примечания',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              ElevatedButton.icon(
                onPressed: _saveConsumable,
                icon: const Icon(Icons.save),
                label: Text(_isEditMode ? 'Сохранить изменения' : 'Добавить расходник'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              if (_isEditMode) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Отмена'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
}
