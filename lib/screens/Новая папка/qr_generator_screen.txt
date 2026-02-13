// screens/qr_generator_screen.dart
import 'package:flutter/material.dart';
import '../models/equipment.dart';

class QRGeneratorScreen extends StatelessWidget {
  final Equipment? equipment;
  
  const QRGeneratorScreen({super.key, this.equipment});
  
  @override
  Widget build(BuildContext context) {
    final hasEquipment = equipment != null;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR генератор'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasEquipment) ...[
                // Показываем QR для конкретного оборудования
                _buildEquipmentQR(equipment!),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => _saveQR(context),
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Сохранить QR код'),
                ),
              ] else ...[
                // Показываем общий экран
                const Icon(Icons.qr_code_2, size: 100, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  'QR генератор оборудования',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Выберите оборудование из списка для генерации QR кода',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Вернуться к списку оборудования'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEquipmentQR(Equipment equipment) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.qr_code_2, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              equipment.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            if (equipment.inventoryNumber != null)
              Text(
                'Инв. №: ${equipment.inventoryNumber}',
                style: const TextStyle(color: Colors.blue),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(equipment.type.icon, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text(equipment.type.label, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _saveQR(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR код сохранен (функция в разработке)'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}