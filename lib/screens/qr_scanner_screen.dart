// lib/screens/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'add_equipment_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final TextEditingController _qrCodeController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _processQRCode(String qrData) async {
    if (_isProcessing || qrData.isEmpty) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      _showResultDialog(qrData);
    } catch (e) {
      print('Error processing QR code: $e');
      if (!mounted) return;
      _showErrorDialog('Ошибка обработки: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _qrCodeController.clear();
        });
      }
    }
  }

  void _showResultDialog(String qrData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR-код отсканирован'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Содержимое QR-кода:'),
            const SizedBox(height: 10),
            Text(
              qrData,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text('Выберите действие:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEquipmentScreen(
                    equipment: {'scannedCode': qrData},
                  ),
                ),
              );
            },
            child: const Text('Добавить оборудование'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ввод QR-кода вручную'),
        content: TextField(
          controller: _qrCodeController,
          decoration: const InputDecoration(
            hintText: 'Введите QR-код или серийный номер',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final qrCode = _qrCodeController.text.trim();
              if (qrCode.isNotEmpty) {
                Navigator.pop(context);
                _processQRCode(qrCode);
              }
            },
            child: const Text('Поиск'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканирование QR-кода'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Сканирование QR-кода',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Инструкция:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildInstructionStep(
                      '1. Используйте USB-сканер QR-кодов',
                      'Подключите сканер к компьютеру',
                    ),
                    _buildInstructionStep(
                      '2. Отсканируйте QR-код оборудования',
                      'Код появится в поле ниже автоматически',
                    ),
                    _buildInstructionStep(
                      '3. Или введите код вручную',
                      'Нажмите кнопку "Ввести вручную"',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QR-код:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _qrCodeController,
                      decoration: InputDecoration(
                        hintText: 'QR-код появится здесь после сканирования...',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _qrCodeController.clear(),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () {
                                final qrCode = _qrCodeController.text.trim();
                                if (qrCode.isNotEmpty) {
                                  _processQRCode(qrCode);
                                }
                              },
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(
                          _isProcessing ? 'Обработка...' : 'Обработать QR-код',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: _showManualEntryDialog,
                icon: const Icon(Icons.keyboard),
                label: const Text('Ввести код вручную'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      )
    );
  }

  @override
  void dispose() {
    _qrCodeController.dispose();
    super.dispose();
  }
}