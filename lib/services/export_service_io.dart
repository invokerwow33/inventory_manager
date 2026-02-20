import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import '../models/equipment.dart';

class ExportService {
  static Future<void> exportToCsv({List<Equipment>? equipmentList}) async {
    final dbHelper = DatabaseHelper.instance;
    final equipmentData = equipmentList == null
        ? await dbHelper.getEquipment()
        : equipmentList.map((e) => e.toMap()).toList();
    final equipment = equipmentList ?? equipmentData.map((m) => Equipment.fromMap(m)).toList();

    if (equipment.isEmpty) {
      throw Exception('Нет данных для экспорта');
    }
    
    final rows = [
      ['Название', 'Тип', 'Статус', 'Серийный номер', 'Инв. номер', 'Производитель', 'Модель', 'Отдел', 'Ответственный', 'Местоположение']
    ];
    
    for (final eq in equipment) {
      rows.add([
        eq.name,
        eq.type.toString().split('.').last,
        eq.status.toString().split('.').last,
        eq.serialNumber ?? '',
        eq.inventoryNumber ?? '',
        eq.manufacturer ?? '',
        eq.model ?? '',
        eq.department ?? '',
        eq.responsiblePerson ?? '',
        eq.location ?? '',
      ]);
    }
    
    final csv = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csv);
    
    // Используем file_picker для сохранения
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить CSV файл',
      fileName: 'equipment_export_${_timestamp()}.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    
    if (result != null) {
      final file = File(result);
      await file.writeAsBytes(bytes);
    }
  }
  static Future<void> exportToExcel({List<Equipment>? equipmentList}) async {
    final dbHelper = DatabaseHelper.instance;
    final equipmentData = equipmentList == null
        ? await dbHelper.getEquipment()
        : equipmentList.map((e) => e.toMap()).toList();
    final equipment = equipmentList ?? equipmentData.map((m) => Equipment.fromMap(m)).toList();

    if (equipment.isEmpty) {
      throw Exception('Нет данных для экспорта');
    }
    
    final excel = Excel.createExcel();
    final sheet = excel['Оборудование'];
    
    sheet.appendRow([
      TextCellValue('Название'),
      TextCellValue('Тип'),
      TextCellValue('Статус'),
      TextCellValue('Серийный номер'),
      TextCellValue('Инв. номер'),
      TextCellValue('Производитель'),
      TextCellValue('Модель'),
      TextCellValue('Отдел'),
      TextCellValue('Ответственный'),
      TextCellValue('Местоположение'),
    ]);
    
    for (final eq in equipment) {
      sheet.appendRow([
        TextCellValue(eq.name),
        TextCellValue(eq.type.label),
        TextCellValue(eq.status.label),
        TextCellValue(eq.serialNumber ?? ''),
        TextCellValue(eq.inventoryNumber ?? ''),
        TextCellValue(eq.manufacturer ?? ''),
        TextCellValue(eq.model ?? ''),
        TextCellValue(eq.department ?? ''),
        TextCellValue(eq.responsiblePerson ?? ''),
        TextCellValue(eq.location ?? ''),
      ]);
    }
    
    final bytes = excel.encode();
    if (bytes != null) {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить Excel файл',
        fileName: 'equipment_export_${_timestamp()}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      
      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(bytes);
      }
    }
  }
  static String _timestamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }
}
