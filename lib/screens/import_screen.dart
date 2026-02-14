import 'package:flutter/material.dart';
import '../services/import_service.dart';
import '../models/equipment.dart';
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}
class _ImportScreenState extends State<ImportScreen> {
  bool _isLoading = false;
  List<Equipment> _previewData = [];
  List<Map<String, dynamic>> _errors = [];
  int _totalRows = 0;
  bool _hasFile = false;
  String _selectedFormat = 'csv';
  Future<void> _selectAndPreview() async {
    setState(() => _isLoading = true);
    try {
      final result = _selectedFormat == 'csv' 
          ? await ImportService.previewCsv()
          : await ImportService.previewExcel();
      
      setState(() {
        _previewData = result.importedEquipment;
        _errors = result.errors;
        _totalRows = result.totalRows;
        _hasFile = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  Future<void> _importData() async {
    setState(() => _isLoading = true);
    try {
      final result = _selectedFormat == 'csv'
          ? await ImportService.importFromCsv()
          : await ImportService.importFromExcel();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Импортировано: ${result.successCount} из ${result.totalRows}'),
          backgroundColor: result.errorCount > 0 ? Colors.orange : Colors.green,
        ),
      );
      if (result.errorCount == 0) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка импорта: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Импорт оборудования')),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildBody(),
    );
  }
  Widget _buildBody() {
    if (!_hasFile) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.upload_file, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Выберите формат и файл', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'csv', label: Text('CSV')),
                ButtonSegment(value: 'excel', label: Text('Excel')),
              ],
              selected: {_selectedFormat},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _selectedFormat = newSelection.first);
              },
            ),
            
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _selectAndPreview,
              icon: const Icon(Icons.file_open),
              label: const Text('Выбрать файл'),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Всего', _totalRows.toString(), Colors.blue),
                _buildStat('OK', _previewData.length.toString(), Colors.green),
                _buildStat('Ошибок', _errors.length.toString(), Colors.red),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _previewData.length,
            itemBuilder: (context, index) {
              final eq = _previewData[index];
              return ListTile(
                leading: Icon(eq.type.icon),
                title: Text(eq.name),
                subtitle: Text('${eq.type.label} • ${eq.status.label}'),
                trailing: Icon(Icons.check_circle, color: Colors.green.shade300),
              );
            },
          ),
        ),
        if (_errors.isNotEmpty) ...[
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Ошибки:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              itemCount: _errors.length,
              itemBuilder: (context, i) => ListTile(
                dense: true,
                leading: const Icon(Icons.error, color: Colors.red, size: 20),
                title: Text('Строка ${_errors[i]['row']}', style: const TextStyle(fontSize: 14)),
                subtitle: Text(_errors[i]['error'].toString(), style: const TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _hasFile = false),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Другой файл'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _previewData.isNotEmpty ? _importData : null,
                  icon: const Icon(Icons.download),
                  label: const Text('Импортировать'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}