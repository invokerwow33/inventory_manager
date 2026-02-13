import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/equipment.dart';
import 'add_equipment_screen.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final String equipmentId;
  
  const EquipmentDetailScreen({Key? key, required this.equipmentId}) : super(key: key);
  
  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  Equipment? _equipment;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }
  
  Future<void> _loadEquipment() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final equipment = await dbHelper.getEquipment(widget.equipmentId);
      
      if (mounted) {
        setState(() {
          _equipment = equipment;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_equipment?.name ?? 'Детали оборудования'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _equipment != null 
                ? () => _navigateToEdit()
                : null,
            tooltip: 'Редактировать',
          ),
        ],
      ),
      body: _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_equipment == null) {
      return const Center(child: Text('Оборудование не найдено'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Основная информация
          _buildDetailCard(),
          
          const SizedBox(height: 16),
          
          // QR код оборудования (временно заглушка)
          _buildQrCodeSection(),
          
          const SizedBox(height: 16),
          
          // История обслуживания (заглушка)
          _buildMaintenanceHistory(),
          
          const SizedBox(height: 20),
          
          // Кнопка удаления
          _buildDeleteButton(),
        ],
      ),
    );
  }
  
  Widget _buildDetailCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_equipment!.type.icon, size: 40, color: Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _equipment!.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _equipment!.status.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _equipment!.status.label,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Детальная информация
            _buildDetailRow('Инвентарный номер:', _equipment!.inventoryNumber ?? 'Не указан'),
            _buildDetailRow('Серийный номер:', _equipment!.serialNumber ?? 'Не указан'),
            _buildDetailRow('Производитель:', _equipment!.manufacturer ?? 'Не указан'),
            _buildDetailRow('Модель:', _equipment!.model ?? 'Не указан'),
            _buildDetailRow('Тип:', _equipment!.type.label),
            _buildDetailRow('Статус:', _equipment!.status.label),
            _buildDetailRow('Расположение:', _equipment!.location ?? 'Не указано'),
            _buildDetailRow('Отдел:', _equipment!.department ?? 'Не указан'),
            _buildDetailRow('Ответственное лицо:', _equipment!.responsiblePerson ?? 'Не указано'),
            
            if (_equipment!.purchaseDate != null)
              _buildDetailRow('Дата приобретения:', _equipment!.formattedPurchaseDate),
            
            if (_equipment!.purchasePrice != null)
              _buildDetailRow('Стоимость:', _equipment!.formattedPrice),
            
            if (_equipment!.notes?.isNotEmpty ?? false)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Примечания:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _equipment!.notes!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            
            const SizedBox(height: 16),
            
            // Даты создания и обновления
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Создано: ${_formatDate(_equipment!.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Обновлено: ${_formatDate(_equipment!.updatedAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQrCodeSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QR код оборудования',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2, size: 60, color: Colors.blue),
                    const SizedBox(height: 16),
                    Text(
                      _equipment!.inventoryNumber ?? 'Без номера',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _equipment!.name,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Сканируйте для получения информации об оборудовании',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showQrOptions(context),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Поделиться'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _printQrCode(context),
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Печать'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMaintenanceHistory() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'История обслуживания',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Column(
                children: [
                  Icon(Icons.history, size: 40, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'История обслуживания не ведется',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Добавьте первый запись об обслуживании',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _addMaintenanceRecord(),
              icon: const Icon(Icons.add),
              label: const Text('Добавить запись об обслуживании'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDeleteButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () => _confirmDelete(context),
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        label: const Text(
          'Удалить оборудование',
          style: TextStyle(color: Colors.red),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
  
  void _navigateToEdit() {
    if (_equipment != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEquipmentScreen(
            equipment: _equipment!.toMap(),
          ),
        ),
      ).then((_) {
        // Обновить данные после редактирования
        _loadEquipment();
      });
    }
  }
  
  void _showQrOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR код'),
        content: const Text('Выберите действие с QR кодом'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('QR код сохранен (функция в разработке)'),
                ),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
  
  void _printQrCode(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция печати QR кода в разработке'),
      ),
    );
  }
  
  void _addMaintenanceRecord() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция добавления записи об обслуживании в разработке'),
      ),
    );
  }
  
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление оборудования'),
        content: Text('Вы уверены, что хотите удалить "${_equipment!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => _deleteEquipment(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Удалить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteEquipment(BuildContext context) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteEquipment(_equipment!.id);
      
      Navigator.pop(context); // Закрыть диалог
      Navigator.pop(context); // Вернуться к списку оборудования
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Оборудование "${_equipment!.name}" удалено'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка удаления: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}