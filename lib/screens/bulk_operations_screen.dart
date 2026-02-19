import 'package:flutter/material.dart';
import 'package:inventory_manager/database/simple_database_helper.dart';
import 'package:inventory_manager/screens/equipment_selection_screen.dart';
import 'package:intl/intl.dart';

class BulkOperationsScreen extends StatefulWidget {
  final List<String>? preselectedEquipmentIds;
  
  const BulkOperationsScreen({super.key, this.preselectedEquipmentIds});
  
  @override
  State<BulkOperationsScreen> createState() => _BulkOperationsScreenState();
}

class _BulkOperationsScreenState extends State<BulkOperationsScreen> {
  final SimpleDatabaseHelper _dbHelper = SimpleDatabaseHelper();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Step 1: Selected equipment
  List<String> _selectedEquipmentIds = [];
  List<Map<String, dynamic>> _selectedEquipment = [];
  
  // Step 2: Operation type
  String _operationType = 'Выдача';
  final List<String> _operationTypes = ['Выдача', 'Возврат', 'Перемещение', 'Списание'];
  
  // Step 3: Common parameters
  final TextEditingController _toLocationController = TextEditingController();
  final TextEditingController _toResponsibleController = TextEditingController();
  final TextEditingController _documentNumberController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _movementDate = DateTime.now();
  
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _dbHelper.initDatabase();
    
    if (widget.preselectedEquipmentIds != null) {
      _selectedEquipmentIds = List.from(widget.preselectedEquipmentIds!);
      _loadSelectedEquipment();
    }
  }

  Future<void> _loadSelectedEquipment() async {
    if (_selectedEquipmentIds.isEmpty) return;

    final equipment = <Map<String, dynamic>>[];
    for (final id in _selectedEquipmentIds) {
      final item = await _dbHelper.getEquipmentById(id);
      if (item != null && item.isNotEmpty) {
        equipment.add(item);
      }
    }

    if (mounted) {
      setState(() {
        _selectedEquipment = equipment;
      });
    }
  }

  Future<void> _selectEquipment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquipmentSelectionScreen(
          selectedEquipmentIds: _selectedEquipmentIds,
          multipleSelection: true,
        ),
      ),
    );

    if (result != null && result is List<String>) {
      setState(() {
        _selectedEquipmentIds = result;
      });
      await _loadSelectedEquipment();
    }
  }

  void _goToStep(int step) {
    if (step >= 0 && step <= 3) {
      setState(() => _currentStep = step);
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _movementDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() => _movementDate = picked);
    }
  }

  Future<void> _executeBulkOperation() async {
    if (_selectedEquipmentIds.isEmpty) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final results = await _dbHelper.performBulkMovement(
        equipmentIds: _selectedEquipmentIds,
        movementType: _operationType,
        toLocation: _toLocationController.text.trim(),
        toResponsible: _toResponsibleController.text.trim().isEmpty 
            ? null 
            : _toResponsibleController.text.trim(),
        documentNumber: _documentNumberController.text.trim().isEmpty 
            ? null 
            : _documentNumberController.text.trim(),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        movementDate: _movementDate,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Выполнено операций: ${results.length}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Массовая операция'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Выбор', Icons.check_box),
                _buildStepConnector(0),
                _buildStepIndicator(1, 'Тип', Icons.category),
                _buildStepConnector(1),
                _buildStepIndicator(2, 'Параметры', Icons.settings),
                _buildStepConnector(2),
                _buildStepIndicator(3, 'Подтверждение', Icons.check_circle),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1Selection(),
                _buildStep2OperationType(),
                _buildStep3Parameters(),
                _buildStep4Confirmation(),
              ],
            ),
          ),
          
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _goToStep(_currentStep - 1),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Назад'),
                    ),
                  ),
                if (_currentStep > 0)
                  const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing 
                        ? null 
                        : _currentStep == 3 
                            ? _executeBulkOperation
                            : () => _goToStep(_currentStep + 1),
                    icon: _isProcessing 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_currentStep == 3 ? Icons.check : Icons.arrow_forward),
                    label: Text(_currentStep == 3 ? 'Выполнить' : 'Далее'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: isCurrent ? 20 : 16,
            backgroundColor: isActive ? Colors.blue : Colors.grey.shade300,
            child: Icon(
              icon,
              size: isCurrent ? 20 : 16,
              color: isActive ? Colors.white : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.blue : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Colors.blue : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildStep1Selection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Выберите оборудование',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Выбрано: ${_selectedEquipment.length} единиц',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: _selectEquipment,
            icon: const Icon(Icons.add),
            label: const Text('Выбрать оборудование'),
          ),
          
          const SizedBox(height: 16),
          
          if (_selectedEquipment.isNotEmpty)
            Expanded(
              child: Card(
                child: ListView.builder(
                  itemCount: _selectedEquipment.length,
                  itemBuilder: (context, index) {
                    final item = _selectedEquipment[index];
                    return ListTile(
                      leading: const Icon(Icons.devices),
                      title: Text(item['name'] ?? 'Без названия'),
                      subtitle: Text('${item['category'] ?? 'Без категории'} • ${item['inventory_number'] ?? '-'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedEquipmentIds.remove(item['id'].toString());
                            _selectedEquipment.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          
          if (_selectedEquipment.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.devices_other, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      'Ничего не выбрано',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep2OperationType() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Тип операции',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          ..._operationTypes.map((type) {
            IconData icon;
            Color color;
            String description;
            
            switch (type) {
              case 'Выдача':
                icon = Icons.arrow_forward;
                color = Colors.green;
                description = 'Выдача оборудования сотруднику';
                break;
              case 'Возврат':
                icon = Icons.arrow_back;
                color = Colors.blue;
                description = 'Возврат оборудования на склад';
                break;
              case 'Перемещение':
                icon = Icons.swap_horiz;
                color = Colors.orange;
                description = 'Перемещение между локациями';
                break;
              case 'Списание':
                icon = Icons.delete;
                color = Colors.red;
                description = 'Списание оборудования';
                break;
              default:
                icon = Icons.help;
                color = Colors.grey;
                description = '';
            }
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: _operationType == type ? color.withOpacity(0.1) : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(icon, color: color),
                ),
                title: Text(type),
                subtitle: Text(description),
                trailing: _operationType == type
                    ? Icon(Icons.check_circle, color: color)
                    : const Icon(Icons.radio_button_unchecked),
                onTap: () => setState(() => _operationType = type),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStep3Parameters() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Параметры операции',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Местоположение',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _toLocationController,
                    decoration: InputDecoration(
                      labelText: _operationType == 'Возврат' 
                          ? 'Место возврата (склад)' 
                          : 'Новое местоположение',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
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
                    'Ответственный',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _toResponsibleController,
                    decoration: InputDecoration(
                      labelText: _operationType == 'Выдача' 
                          ? 'Кому выдается' 
                          : 'Ответственное лицо',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                    ),
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
                    'Документ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Дата операции',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd.MM.yyyy').format(_movementDate)),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _documentNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Номер документа',
                      hintText: 'Акт выдачи №123',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
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
                    'Примечания',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Дополнительная информация',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Confirmation() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Подтверждение',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Сводка операции
          Card(
            color: Colors.blue.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfirmationRow('Тип операции:', _operationType),
                  _buildConfirmationRow('Количество единиц:', '${_selectedEquipment.length}'),
                  _buildConfirmationRow('Дата:', DateFormat('dd.MM.yyyy').format(_movementDate)),
                  if (_toLocationController.text.isNotEmpty)
                    _buildConfirmationRow('Местоположение:', _toLocationController.text),
                  if (_toResponsibleController.text.isNotEmpty)
                    _buildConfirmationRow('Ответственный:', _toResponsibleController.text),
                  if (_documentNumberController.text.isNotEmpty)
                    _buildConfirmationRow('Документ:', _documentNumberController.text),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Список оборудования
          Expanded(
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Оборудование (${_selectedEquipment.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _selectedEquipment.length,
                      itemBuilder: (context, index) {
                        final item = _selectedEquipment[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.devices, size: 20),
                          title: Text(
                            item['name'] ?? 'Без названия',
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '${item['inventory_number'] ?? '-'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_operationType == 'Списание')
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Внимание: Оборудование будет помечено как "Списано"',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _toLocationController.dispose();
    _toResponsibleController.dispose();
    _documentNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
