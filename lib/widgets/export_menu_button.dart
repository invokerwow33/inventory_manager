import 'package:flutter/material.dart';
import '../services/export_service.dart';
class ExportMenuButton extends StatelessWidget {
  const ExportMenuButton({super.key});
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.download),
      tooltip: 'Экспорт',
      onSelected: (value) => _handleExport(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'csv',
          child: Row(
            children: [
              Icon(Icons.description, color: Colors.green),
              SizedBox(width: 8),
              Text('Экспорт в CSV'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'excel',
          child: Row(
            children: [
              Icon(Icons.table_chart, color: Colors.blue),
              SizedBox(width: 8),
              Text('Экспорт в Excel'),
            ],
          ),
        ),
      ],
    );
  }
  Future<void> _handleExport(BuildContext context, String format) async {
    try {
      if (format == 'csv') {
        await ExportService.exportToCsv();
      } else {
        await ExportService.exportToExcel();
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Файл успешно скачан'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка экспорта: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
