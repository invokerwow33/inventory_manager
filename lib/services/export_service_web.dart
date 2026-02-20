import 'dart:html' as html;
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import '../models/equipment.dart';

class ExportService {
  static Future<void> exportToCsv({List<Equipment>? equipmentList}) async {
    final dbHelper = getDatabaseHelper();
    final equipmentData = equipmentList == null
        ? await dbHelper.getAllEquipment()
        : equipmentList.map((e) => e.toMap()).toList();
    final equipment = equipmentList ?? equipmentData.map((m) => Equipment.fromMap(m)).toList();

    if (equipment.isEmpty) {
      throw Exception('Нет данных для экспорта');
    }

    final rows = [
      [
        'Название',
        'Тип',
        'Статус',
        'Серийный номер',
        'Инв. номер',
        'Производитель',
        'Модель',
        'Отдел',
        'Ответственный',
        'Местоположение'
      ]
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

    _downloadFile(bytes, 'equipment_export_${_timestamp()}.csv', 'text/csv');
  }

  static Future<void> exportToExcel({List<Equipment>? equipmentList}) async {
    final dbHelper = getDatabaseHelper();
    final equipmentData = equipmentList == null
        ? await dbHelper.getAllEquipment()
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
      _downloadFile(
        bytes,
        'equipment_export_${_timestamp()}.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }
  }

  static void _downloadFile(List<int> bytes, String filename, String mimeType) {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static String _timestamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }
}
