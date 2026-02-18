import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/document_data.dart';
import '../services/document_generator_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _headerFormKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Контроллеры для полей документа
  final _fioController = TextEditingController();
  final _inventoryNumberController = TextEditingController();
  final _equipmentNameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Контроллеры для настроек шапки
  final _orgNameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  // Ключи для SharedPreferences
  static const String _orgNameKey = 'doc_org_name';
  static const String _departmentKey = 'doc_dept';
  static const String _addressKey = 'doc_address';
  static const String _phoneKey = 'doc_phone';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHeaderSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fioController.dispose();
    _inventoryNumberController.dispose();
    _equipmentNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _orgNameController.dispose();
    _departmentController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadHeaderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orgNameController.text = prefs.getString(_orgNameKey) ?? '';
      _departmentController.text = prefs.getString(_departmentKey) ?? '';
      _addressController.text = prefs.getString(_addressKey) ?? '';
      _phoneController.text = prefs.getString(_phoneKey) ?? '';
    });
  }

  Future<void> _saveHeaderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_orgNameKey, _orgNameController.text.trim());
    await prefs.setString(_departmentKey, _departmentController.text.trim());
    await prefs.setString(_addressKey, _addressController.text.trim());
    await prefs.setString(_phoneKey, _phoneController.text.trim());
  }

  Future<void> _selectDate() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text('Готово'),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                initialDateTime: _selectedDate,
                mode: CupertinoDatePickerMode.date,
                onDateTimeChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  DocumentData _buildDocumentData() {
    return DocumentData(
      fio: _fioController.text.trim(),
      inventoryNumber: _inventoryNumberController.text.trim(),
      equipmentName: _equipmentNameController.text.trim(),
      quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
      price: double.tryParse(_priceController.text.trim().replaceAll(',', '.')),
      date: _selectedDate,
    );
  }

  DocumentHeaderSettings _buildHeaderSettings() {
    return DocumentHeaderSettings(
      organizationName: _orgNameController.text.trim(),
      department: _departmentController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
    );
  }

  Future<void> _generateAndPreview() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, заполните обязательные поля'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = _buildDocumentData();
      final header = _buildHeaderSettings();
      final service = DocumentGeneratorService();

      await service.previewDocument(context, data, header);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _printDocument() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, заполните обязательные поля'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = _buildDocumentData();
      final header = _buildHeaderSettings();
      final service = DocumentGeneratorService();

      await service.printDocument(data, header);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Документ отправлен на печать'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка печати: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, заполните обязательные поля'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = _buildDocumentData();
      final header = _buildHeaderSettings();
      final service = DocumentGeneratorService();

      final filePath = await service.saveDocument(data, header);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Документ сохранен: $filePath'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Документы'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.article), text: 'Форма документа'),
            Tab(icon: Icon(Icons.settings), text: 'Настройки шапки'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDocumentFormTab(),
                _buildHeaderSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildDocumentFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок раздела
            const Text(
              'Данные документа',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // ФИО
            TextFormField(
              controller: _fioController,
              decoration: const InputDecoration(
                labelText: 'ФИО получателя *',
                hintText: 'Введите ФИО сотрудника',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Пожалуйста, введите ФИО';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Инвентарный номер
            TextFormField(
              controller: _inventoryNumberController,
              decoration: const InputDecoration(
                labelText: 'Инвентарный номер *',
                hintText: 'Введите инвентарный номер',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Пожалуйста, введите инвентарный номер';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Наименование оборудования
            TextFormField(
              controller: _equipmentNameController,
              decoration: const InputDecoration(
                labelText: 'Наименование оборудования *',
                hintText: 'Введите наименование',
                prefixIcon: Icon(Icons.devices),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Пожалуйста, введите наименование';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Количество и стоимость
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Количество *',
                      prefixIcon: Icon(Icons.format_list_numbered),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите количество';
                      }
                      if (int.tryParse(value.trim()) == null ||
                          int.parse(value.trim()) <= 0) {
                        return 'Некорректное значение';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Стоимость за ед.',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Дата
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Дата документа *',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  DateFormat('dd.MM.yyyy').format(_selectedDate),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Кнопки действий
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generateAndPreview,
                    icon: const Icon(Icons.preview),
                    label: const Text('Предпросмотр'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _printDocument,
                    icon: const Icon(Icons.print),
                    label: const Text('Печать'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saveDocument,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Сохранить PDF'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _headerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок раздела
            const Text(
              'Настройки шапки документа',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Эти данные будут отображаться в верхней части всех сгенерированных документов',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            // Название организации
            TextFormField(
              controller: _orgNameController,
              decoration: const InputDecoration(
                labelText: 'Название организации',
                hintText: 'ООО "Пример"',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Отдел
            TextFormField(
              controller: _departmentController,
              decoration: const InputDecoration(
                labelText: 'Отдел / Подразделение',
                hintText: 'IT-отдел',
                prefixIcon: Icon(Icons.account_tree),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Адрес
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Адрес',
                hintText: 'г. Москва, ул. Примерная, д. 1',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Телефон
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Телефон',
                hintText: '+7 (999) 123-45-67',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 30),
            // Кнопка сохранения настроек
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _saveHeaderSettings();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Настройки сохранены'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Сохранить настройки'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
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
