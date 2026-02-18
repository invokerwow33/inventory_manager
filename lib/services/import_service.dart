import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';
import '../models/equipment.dart';
class ImportResult {
  final int totalRows;
  final int successCount;
  final int errorCount;
  final List<Map<String, dynamic>> errors;
  final List<Equipment> importedEquipment;
  ImportResult({
    required this.totalRows,
    required this.successCount,
    required this.errorCount,
    required this.errors,
    required this.importedEquipment,
  });
}
class ImportService {
  // ============ CSV IMPORT ============
  static Future<ImportResult> importFromCsv() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true, // Важно для веба!
    );
    if (result == null) throw Exception('Файл не выбран');
    final bytes = result.files.single.bytes;
    if (bytes == null) throw Exception('Не удалось прочитать файл');
    final content = utf8.decode(bytes);
    List<List<dynamic>> rows = const CsvToListConverter().convert(content);
    
    if (rows.isEmpty) throw Exception('CSV файл пуст');
    final dataRows = rows.skip(1).toList();
    return _processData(dataRows);
  }
  static Future<ImportResult> previewCsv() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null) throw Exception('Файл не выбран');
    final bytes = result.files.single.bytes;
    if (bytes == null) throw Exception('Не удалось прочитать файл');
    final content = utf8.decode(bytes);
    List<List<dynamic>> rows = const CsvToListConverter().convert(content);
    
    if (rows.isEmpty) throw Exception('CSV файл пуст');
    final dataRows = rows.skip(1).toList();
    return _previewData(dataRows);
  }
  // ============ EXCEL IMPORT ============
  static Future<ImportResult> importFromExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null) throw Exception('Файл не выбран');
    final bytes = result.files.single.bytes;
    if (bytes == null) throw Exception('Не удалось прочитать файл');
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;
    if (sheet.rows.isEmpty) throw Exception('Excel файл пуст');
    final dataRows = sheet.rows.skip(1).toList();
    return _processExcelData(dataRows);
  }
  static Future<ImportResult> previewExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null) throw Exception('Файл не выбран');
    final bytes = result.files.single.bytes;
    if (bytes == null) throw Exception('Не удалось прочитать файл');
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;
    if (sheet.rows.isEmpty) throw Exception('Excel файл пуст');
    final dataRows = sheet.rows.skip(1).toList();
    return _previewExcelData(dataRows);
  }
  static Equipment _createEquipment({
    required String name,
    required String typeStr,
    required String statusStr,
    String? serial,
    String? inventory,
    String? manufacturer,
    String? model,
    String? department,
    String? responsible,
    String? location,
    required int rowNum,
  }) {
    if (name.isEmpty) throw Exception('Название обязательно (строка $rowNum)');
    final type = EquipmentType.values.firstWhere(
      (t) => t.toString().split('.').last.toLowerCase() == typeStr.toLowerCase(),
      orElse: () => EquipmentType.computer,
    );
    final status = EquipmentStatus.values.firstWhere(
      (s) => s.toString().split('.').last.toLowerCase() == statusStr.toLowerCase(),
      orElse: () => EquipmentStatus.inUse,
    );
    final now = DateTime.now();
    return Equipment(
      id: 'eq_${now.millisecondsSinceEpoch}_$rowNum',
      name: name,
      type: type,
      status: status,
      serialNumber: serial,
      inventoryNumber: inventory,
      manufacturer: manufacturer,
      model: model,
      department: department,
      responsiblePerson: responsible,
      location: location,
      createdAt: now,
      updatedAt: now,
    );
  }
  static Future<ImportResult> _processData(List<List<dynamic>> rows) async {
    final imported = <Equipment>[];
    final errors = <Map<String, dynamic>>[];
    int success = 0;
    for (int i = 0; i < rows.length; i++) {
      try {
        final row = rows[i];
        final eq = _createEquipment(
          name: row.isNotEmpty ? row[0]?.toString().trim() ?? '' : '',
          typeStr: row.length > 1 ? row[1]?.toString().trim() ?? 'computer' : 'computer',
          statusStr: row.length > 2 ? row[2]?.toString().trim() ?? 'inUse' : 'inUse',
          serial: row.length > 3 ? row[3]?.toString() : null,
          inventory: row.length > 4 ? row[4]?.toString() : null,
          manufacturer: row.length > 5 ? row[5]?.toString() : null,
          model: row.length > 6 ? row[6]?.toString() : null,
          department: row.length > 7 ? row[7]?.toString() : null,
          responsible: row.length > 8 ? row[8]?.toString() : null,
          location: row.length > 9 ? row[9]?.toString() : null,
          rowNum: i + 2,
        );
        await DatabaseHelper.instance.insertEquipment(Map<String, dynamic>.from(eq.toMap()));
        imported.add(eq);
        success++;
      } catch (e) {
        errors.add({'row': i + 2, 'error': e.toString()});
      }
    }
    return ImportResult(
      totalRows: rows.length,
      successCount: success,
      errorCount: errors.length,
      errors: errors,
      importedEquipment: imported,
    );
  }
  static Future<ImportResult> _previewData(List<List<dynamic>> rows) async {
    final imported = <Equipment>[];
    final errors = <Map<String, dynamic>>[];
    for (int i = 0; i < rows.length && i < 100; i++) {
      try {
        final row = rows[i];
        final eq = _createEquipment(
          name: row.isNotEmpty ? row[0]?.toString().trim() ?? '' : '',
          typeStr: row.length > 1 ? row[1]?.toString().trim() ?? 'computer' : 'computer',
          statusStr: row.length > 2 ? row[2]?.toString().trim() ?? 'inUse' : 'inUse',
          serial: row.length > 3 ? row[3]?.toString() : null,
          inventory: row.length > 4 ? row[4]?.toString() : null,
          manufacturer: row.length > 5 ? row[5]?.toString() : null,
          model: row.length > 6 ? row[6]?.toString() : null,
          department: row.length > 7 ? row[7]?.toString() : null,
          responsible: row.length > 8 ? row[8]?.toString() : null,
          location: row.length > 9 ? row[9]?.toString() : null,
          rowNum: i + 2,
        );
        imported.add(eq);
      } catch (e) {
        errors.add({'row': i + 2, 'error': e.toString()});
      }
    }
    return ImportResult(
      totalRows: rows.length,
      successCount: imported.length,
      errorCount: errors.length,
      errors: errors,
      importedEquipment: imported,
    );
  }
  static Future<ImportResult> _processExcelData(List<List<Data?>> rows) async {
    final imported = <Equipment>[];
    final errors = <Map<String, dynamic>>[];
    int success = 0;
    for (int i = 0; i < rows.length; i++) {
      try {
        final row = rows[i];
        final eq = _createEquipment(
          name: row.isNotEmpty ? row[0]?.value?.toString().trim() ?? '' : '',
          typeStr: row.length > 1 ? row[1]?.value?.toString().trim() ?? 'computer' : 'computer',
          statusStr: row.length > 2 ? row[2]?.value?.toString().trim() ?? 'inUse' : 'inUse',
          serial: row.length > 3 ? row[3]?.value?.toString() : null,
          inventory: row.length > 4 ? row[4]?.value?.toString() : null,
          manufacturer: row.length > 5 ? row[5]?.value?.toString() : null,
          model: row.length > 6 ? row[6]?.value?.toString() : null,
          department: row.length > 7 ? row[7]?.value?.toString() : null,
          responsible: row.length > 8 ? row[8]?.value?.toString() : null,
          location: row.length > 9 ? row[9]?.value?.toString() : null,
          rowNum: i + 2,
        );
        await DatabaseHelper.instance.insertEquipment(Map<String, dynamic>.from(eq.toMap()));
        imported.add(eq);
        success++;
      } catch (e) {
        errors.add({'row': i + 2, 'error': e.toString()});
      }
    }
    return ImportResult(
      totalRows: rows.length,
      successCount: success,
      errorCount: errors.length,
      errors: errors,
      importedEquipment: imported,
    );
  }
  static Future<ImportResult> _previewExcelData(List<List<Data?>> rows) async {
    final imported = <Equipment>[];
    final errors = <Map<String, dynamic>>[];
    for (int i = 0; i < rows.length && i < 100; i++) {
      try {
        final row = rows[i];
        final eq = _createEquipment(
          name: row.isNotEmpty ? row[0]?.value?.toString().trim() ?? '' : '',
          typeStr: row.length > 1 ? row[1]?.value?.toString().trim() ?? 'computer' : 'computer',
          statusStr: row.length > 2 ? row[2]?.value?.toString().trim() ?? 'inUse' : 'inUse',
          serial: row.length > 3 ? row[3]?.value?.toString() : null,
          inventory: row.length > 4 ? row[4]?.value?.toString() : null,
          manufacturer: row.length > 5 ? row[5]?.value?.toString() : null,
          model: row.length > 6 ? row[6]?.value?.toString() : null,
          department: row.length > 7 ? row[7]?.value?.toString() : null,
          responsible: row.length > 8 ? row[8]?.value?.toString() : null,
          location: row.length > 9 ? row[9]?.value?.toString() : null,
          rowNum: i + 2,
        );
        imported.add(eq);
      } catch (e) {
        errors.add({'row': i + 2, 'error': e.toString()});
      }
    }
    return ImportResult(
      totalRows: rows.length,
      successCount: imported.length,
      errorCount: errors.length,
      errors: errors,
      importedEquipment: imported,
    );
  }
}
