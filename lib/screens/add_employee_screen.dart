import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/employee.dart';
import '../providers/employee_provider.dart';
import '../utils/validators.dart';
import '../widgets/common/common_widgets.dart';

class AddEmployeeScreen extends StatefulWidget {
  final Employee? employee;
  
  const AddEmployeeScreen({super.key, this.employee});
  
  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  // Controllers
  late final TextEditingController _fullNameController;
  late final TextEditingController _departmentController;
  late final TextEditingController _positionController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _employeeNumberController;
  late final TextEditingController _notesController;
  
  bool get _isEditMode => widget.employee != null;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _fullNameController = TextEditingController();
    _departmentController = TextEditingController();
    _positionController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _employeeNumberController = TextEditingController();
    _notesController = TextEditingController();
    
    if (_isEditMode && widget.employee != null) {
      _editingId = widget.employee!.id;
      _fullNameController.text = widget.employee!.fullName;
      _departmentController.text = widget.employee!.department ?? '';
      _positionController.text = widget.employee!.position ?? '';
      _emailController.text = widget.employee!.email ?? '';
      _phoneController.text = widget.employee!.phone ?? '';
      _employeeNumberController.text = widget.employee!.employeeNumber ?? '';
      _notesController.text = widget.employee!.notes ?? '';
    } else {
      _editingId = 'emp_${DateTime.now().millisecondsSinceEpoch}';
    }
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

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    
    final now = DateTime.now();
    
    final employee = Employee(
      id: _editingId!,
      fullName: _fullNameController.text.trim(),
      department: _departmentController.text.trim().isEmpty 
          ? null 
          : _departmentController.text.trim(),
      position: _positionController.text.trim().isEmpty 
          ? null 
          : _positionController.text.trim(),
      email: _emailController.text.trim().isEmpty 
          ? null 
          : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty 
          ? null 
          : _phoneController.text.trim(),
      employeeNumber: _employeeNumberController.text.trim().isEmpty 
          ? null 
          : _employeeNumberController.text.trim(),
      notes: _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim(),
      isActive: _isEditMode ? widget.employee!.isActive : true,
      createdAt: _isEditMode ? widget.employee!.createdAt : now,
      updatedAt: now,
    );
    
    try {
      final provider = context.read<EmployeeProvider>();
      
      if (_isEditMode) {
        await provider.updateEmployee(employee);
      } else {
        await provider.addEmployee(employee);
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
              // Основная информация
              FormSectionCard(
                title: 'Основная информация',
                icon: Icons.person_outline,
                children: [
                  ValidationTextField(
                    label: 'ФИО',
                    controller: _fullNameController,
                    prefixIcon: const Icon(Icons.badge_outlined),
                    validator: Validators.fullName,
                    hint: 'Иванов Иван Иванович',
                  ),
                  
                  ValidationTextField(
                    label: 'Табельный номер',
                    controller: _employeeNumberController,
                    prefixIcon: const Icon(Icons.numbers_outlined),
                    validator: Validators.employeeNumber,
                  ),
                  
                  ValidationTextField(
                    label: 'Должность',
                    controller: _positionController,
                    prefixIcon: const Icon(Icons.work_outline),
                    validator: (value) {
                      final result = Validators.maxLength(value, 100, fieldName: 'Должность');
                      return result.isValid ? null : result.errorMessage;
                    },
                  ),
                  
                  ValidationTextField(
                    label: 'Отдел',
                    controller: _departmentController,
                    prefixIcon: const Icon(Icons.account_balance_outlined),
                    validator: (value) {
                      final result = Validators.maxLength(value, 100, fieldName: 'Отдел');
                      return result.isValid ? null : result.errorMessage;
                    },
                  ),
                ],
              ),
              
              // Контактная информация
              FormSectionCard(
                title: 'Контактная информация',
                icon: Icons.contacts_outlined,
                children: [
                  ValidationTextField.email(
                    label: 'Email',
                    controller: _emailController,
                    onSaved: (_) {},
                  ),
                  
                  ValidationTextField.phone(
                    label: 'Телефон',
                    controller: _phoneController,
                    onSaved: (_) {},
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
                onSave: _saveEmployee,
                saveLabel: _isEditMode ? 'Сохранить изменения' : 'Добавить сотрудника',
                showCancel: _isEditMode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
