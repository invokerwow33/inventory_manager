import 'package:flutter/material.dart';
import 'package:inventory_manager/database/simple_database_helper.dart';
import 'package:inventory_manager/models/employee.dart';

class AddEmployeeScreen extends StatefulWidget {
  final Employee? employee;
  
  const AddEmployeeScreen({super.key, this.employee});
  
  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final SimpleDatabaseHelper _dbHelper = SimpleDatabaseHelper();
  
  late TextEditingController _fullNameController;
  late TextEditingController _departmentController;
  late TextEditingController _positionController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _employeeNumberController;
  late TextEditingController _notesController;
  
  bool get _isEditMode => widget.employee != null;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    
    if (_isEditMode && widget.employee != null) {
      _editingId = widget.employee!.id;
      _fullNameController = TextEditingController(text: widget.employee!.fullName);
      _departmentController = TextEditingController(text: widget.employee!.department ?? '');
      _positionController = TextEditingController(text: widget.employee!.position ?? '');
      _emailController = TextEditingController(text: widget.employee!.email ?? '');
      _phoneController = TextEditingController(text: widget.employee!.phone ?? '');
      _employeeNumberController = TextEditingController(text: widget.employee!.employeeNumber ?? '');
      _notesController = TextEditingController(text: widget.employee!.notes ?? '');
    } else {
      _editingId = 'emp_${DateTime.now().millisecondsSinceEpoch}';
      _fullNameController = TextEditingController();
      _departmentController = TextEditingController();
      _positionController = TextEditingController();
      _emailController = TextEditingController();
      _phoneController = TextEditingController();
      _employeeNumberController = TextEditingController();
      _notesController = TextEditingController();
    }
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    
    final now = DateTime.now();
    
    final employee = Employee(
      id: _editingId!,
      fullName: _fullNameController.text.trim(),
      department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
      position: _positionController.text.trim().isEmpty ? null : _positionController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      employeeNumber: _employeeNumberController.text.trim().isEmpty ? null : _employeeNumberController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: _isEditMode ? widget.employee!.createdAt : now,
      updatedAt: now,
    );
    
    try {
      if (_isEditMode) {
        await _dbHelper.updateEmployee(employee.toMap());
      } else {
        await _dbHelper.insertEmployee(employee.toMap());
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Сотрудник обновлен' : 'Сотрудник добавлен'),
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
        title: Text(_isEditMode ? 'Редактировать сотрудника' : 'Добавить сотрудника'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveEmployee,
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
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'ФИО *',
                          border: OutlineInputBorder(),
                          hintText: 'Иванов Иван Иванович',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите ФИО';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _employeeNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Табельный номер',
                          border: OutlineInputBorder(),
                          hintText: '00123',
                          prefixIcon: Icon(Icons.badge),
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
                        'Рабочая информация',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _departmentController,
                        decoration: const InputDecoration(
                          labelText: 'Отдел / Подразделение',
                          border: OutlineInputBorder(),
                          hintText: 'IT-отдел',
                          prefixIcon: Icon(Icons.business),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _positionController,
                        decoration: const InputDecoration(
                          labelText: 'Должность',
                          border: OutlineInputBorder(),
                          hintText: 'Системный администратор',
                          prefixIcon: Icon(Icons.work),
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
                        'Контактная информация',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          hintText: 'ivanov@company.ru',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Телефон',
                          border: OutlineInputBorder(),
                          hintText: '+7 (999) 123-45-67',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
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
                onPressed: _saveEmployee,
                icon: const Icon(Icons.save),
                label: Text(_isEditMode ? 'Сохранить изменения' : 'Добавить сотрудника'),
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
    _fullNameController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
