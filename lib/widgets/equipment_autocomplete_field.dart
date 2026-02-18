import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/simple_database_helper.dart';

/// Интерактивное поле выбора оборудования с автодополнением.
/// 
/// Предоставляет двустороннюю связь между названием оборудования и инвентарным номером:
/// - При выборе оборудования из списка автоматически подставляется инвентарный номер
/// - При вводе инвентарного номера подтягивается название оборудования
/// - Поддерживается ручной ввод (не из базы данных)
class EquipmentAutocompleteField extends StatefulWidget {
  /// Контроллер для названия оборудования
  final TextEditingController? nameController;
  
  /// Контроллер для инвентарного номера
  final TextEditingController? inventoryNumberController;
  
  /// Callback при изменении выбранного оборудования
  final Function(Map<String, dynamic>? equipment)? onEquipmentSelected;
  
  /// Разрешить ручной ввод (не из базы данных)
  final bool allowManualInput;
  
  /// Валидатор для названия оборудования
  final String? Function(String?)? nameValidator;
  
  /// Валидатор для инвентарного номера
  final String? Function(String?)? inventoryNumberValidator;
  
  /// Подпись поля названия оборудования
  final String nameLabel;
  
  /// Подпись поля инвентарного номера
  final String inventoryNumberLabel;
  
  /// Подсказка для поля названия оборудования
  final String? nameHint;
  
  /// Подсказка для поля инвентарного номера
  final String? inventoryNumberHint;
  
  /// Отступ между полями
  final double spacing;

  const EquipmentAutocompleteField({
    super.key,
    this.nameController,
    this.inventoryNumberController,
    this.onEquipmentSelected,
    this.allowManualInput = true,
    this.nameValidator,
    this.inventoryNumberValidator,
    this.nameLabel = 'Наименование оборудования',
    this.inventoryNumberLabel = 'Инвентарный номер',
    this.nameHint,
    this.inventoryNumberHint,
    this.spacing = 16,
  });

  @override
  State<EquipmentAutocompleteField> createState() => _EquipmentAutocompleteFieldState();
}

class _EquipmentAutocompleteFieldState extends State<EquipmentAutocompleteField> {
  late final TextEditingController _nameController;
  late final TextEditingController _inventoryNumberController;
  final SimpleDatabaseHelper _dbHelper = SimpleDatabaseHelper();
  
  Timer? _searchDebounce;
  bool _isUpdating = false;
  Map<String, dynamic>? _selectedEquipment;
  
  // Опции для autocomplete
  List<Map<String, dynamic>> _equipmentOptions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = widget.nameController ?? TextEditingController();
    _inventoryNumberController = widget.inventoryNumberController ?? TextEditingController();
    
    // Инициализируем базу данных
    _dbHelper.initDatabase();
    
    // Добавляем слушатели для двусторонней связи
    _inventoryNumberController.addListener(_onInventoryNumberChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _inventoryNumberController.removeListener(_onInventoryNumberChanged);
    // Удаляем контроллеры только если они были созданы внутри виджета
    if (widget.nameController == null) {
      _nameController.dispose();
    }
    if (widget.inventoryNumberController == null) {
      _inventoryNumberController.dispose();
    }
    super.dispose();
  }

  /// Обработчик изменения инвентарного номера
  void _onInventoryNumberChanged() {
    if (_isUpdating) return;
    
    final inventoryNumber = _inventoryNumberController.text.trim();
    if (inventoryNumber.isEmpty) {
      setState(() {
        _selectedEquipment = null;
      });
      widget.onEquipmentSelected?.call(null);
      return;
    }
    
    // Отменяем предыдущий дебаунс
    _searchDebounce?.cancel();
    
    // Устанавливаем новый дебаунс для поиска
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _searchByInventoryNumber(inventoryNumber);
    });
  }

  /// Поиск оборудования по инвентарному номеру
  Future<void> _searchByInventoryNumber(String inventoryNumber) async {
    if (inventoryNumber.isEmpty) return;
    
    try {
      final results = await _dbHelper.searchEquipmentByInventoryNumber(inventoryNumber);
      
      if (results.isNotEmpty && mounted) {
        // Ищем точное совпадение или первый результат
        final exactMatch = results.firstWhere(
          (item) => item['inventory_number']?.toString().toLowerCase() == inventoryNumber.toLowerCase(),
          orElse: () => results.first,
        );
        
        setState(() {
          _isUpdating = true;
          _selectedEquipment = exactMatch;
          _nameController.text = exactMatch['name']?.toString() ?? '';
        });
        
        widget.onEquipmentSelected?.call(exactMatch);
        
        // Сбрасываем флаг после небольшой задержки
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() => _isUpdating = false);
          }
        });
      }
    } catch (e) {
      debugPrint('Ошибка поиска по инвентарному номеру: $e');
    }
  }

  /// Поиск оборудования по названию (для autocomplete)
  Future<List<Map<String, dynamic>>> _searchByName(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final results = await _dbHelper.searchEquipmentByName(query);
      return results.take(10).toList(); // Ограничиваем до 10 результатов
    } catch (e) {
      debugPrint('Ошибка поиска по названию: $e');
      return [];
    }
  }

  /// При выборе оборудования из autocomplete
  void _onEquipmentSelected(Map<String, dynamic> equipment) {
    setState(() {
      _isUpdating = true;
      _selectedEquipment = equipment;
      _nameController.text = equipment['name']?.toString() ?? '';
      _inventoryNumberController.text = equipment['inventory_number']?.toString() ?? '';
    });
    
    widget.onEquipmentSelected?.call(equipment);
    
    // Сбрасываем флаг после небольшой задержки
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    });
  }

  /// Отображение опции в autocomplete
  String _displayStringForOption(Map<String, dynamic> option) {
    final name = option['name']?.toString() ?? '';
    final inventoryNumber = option['inventory_number']?.toString() ?? '';
    
    if (inventoryNumber.isNotEmpty) {
      return '$name (Инв. №: $inventoryNumber)';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Поле названия оборудования с autocomplete
        Autocomplete<Map<String, dynamic>>(
          initialValue: TextEditingValue(text: _nameController.text),
          displayStringForOption: _displayStringForOption,
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Map<String, dynamic>>.empty();
            }
            final results = await _searchByName(textEditingValue.text);
            return results;
          },
          onSelected: (Map<String, dynamic> selection) {
            _onEquipmentSelected(selection);
          },
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController fieldTextEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted,
          ) {
            // Синхронизируем контроллеры
            if (_nameController.text != fieldTextEditingController.text && 
                !_isUpdating) {
              fieldTextEditingController.text = _nameController.text;
            }
            
            return TextFormField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              decoration: InputDecoration(
                labelText: widget.nameLabel,
                hintText: widget.nameHint ?? 'Введите название или выберите из списка',
                prefixIcon: const Icon(Icons.devices),
                border: const OutlineInputBorder(),
                suffixIcon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.arrow_drop_down),
              ),
              validator: widget.nameValidator,
              onChanged: (value) {
                _nameController.text = value;
                // Если очищаем поле, сбрасываем выбор
                if (value.isEmpty && !_isUpdating) {
                  setState(() {
                    _selectedEquipment = null;
                  });
                  widget.onEquipmentSelected?.call(null);
                }
              },
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<Map<String, dynamic>> onSelected,
            Iterable<Map<String, dynamic>> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      final inventoryNumber = option['inventory_number']?.toString();
                      final serialNumber = option['serial_number']?.toString();
                      final status = option['status']?.toString();
                      
                      return ListTile(
                        title: Text(option['name']?.toString() ?? 'Без названия'),
                        subtitle: Row(
                          children: [
                            if (inventoryNumber != null && inventoryNumber.isNotEmpty)
                              Text('Инв. №: $inventoryNumber'),
                            if (serialNumber != null && serialNumber.isNotEmpty) ...[
                              if (inventoryNumber != null && inventoryNumber.isNotEmpty)
                                const Text(' | '),
                              Text('S/N: $serialNumber'),
                            ],
                          ],
                        ),
                        trailing: status != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        
        SizedBox(height: widget.spacing),
        
        // Поле инвентарного номера
        TextFormField(
          controller: _inventoryNumberController,
          decoration: InputDecoration(
            labelText: widget.inventoryNumberLabel,
            hintText: widget.inventoryNumberHint ?? 'Введите инвентарный номер',
            prefixIcon: const Icon(Icons.numbers),
            border: const OutlineInputBorder(),
            suffixIcon: _selectedEquipment != null
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
          validator: widget.inventoryNumberValidator,
          inputFormatters: [
            // Разрешаем буквы, цифры и некоторые спецсимволы
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Zа-яА-ЯёЁ0-9\-/_]')),
          ],
        ),
        
        // Индикатор найденного оборудования
        if (_selectedEquipment != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Оборудование найдено в базе данных',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'В использовании':
        return Colors.green;
      case 'На складе':
        return Colors.blue;
      case 'В ремонте':
        return Colors.orange;
      case 'Списано':
        return Colors.red;
      case 'В резерве':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

/// Упрощенная версия поля выбора оборудования для использования в формах
class EquipmentSelectionFormField extends FormField<Map<String, dynamic>?> {
  EquipmentSelectionFormField({
    super.key,
    super.onSaved,
    super.validator,
    super.initialValue,
    AutovalidateMode? autovalidateMode,
    String nameLabel = 'Наименование оборудования',
    String inventoryNumberLabel = 'Инвентарный номер',
    String? nameHint,
    String? inventoryNumberHint,
    double spacing = 16,
    bool allowManualInput = true,
    Function(Map<String, dynamic>? equipment)? onEquipmentSelected,
  }) : super(
          autovalidateMode: autovalidateMode ?? AutovalidateMode.disabled,
          builder: (FormFieldState<Map<String, dynamic>?> field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EquipmentAutocompleteField(
                  nameLabel: nameLabel,
                  inventoryNumberLabel: inventoryNumberLabel,
                  nameHint: nameHint,
                  inventoryNumberHint: inventoryNumberHint,
                  spacing: spacing,
                  allowManualInput: allowManualInput,
                  onEquipmentSelected: (equipment) {
                    field.didChange(equipment);
                    onEquipmentSelected?.call(equipment);
                  },
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: Text(
                      field.errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            );
          },
        );
}
