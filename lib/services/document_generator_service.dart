import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/document_data.dart';

class DocumentGeneratorService {
  static final DocumentGeneratorService _instance =
      DocumentGeneratorService._internal();
  factory DocumentGeneratorService() => _instance;
  DocumentGeneratorService._internal();

  Future<Uint8List> generatePdf(
    DocumentData data,
    DocumentHeaderSettings header,
  ) async {
    final pdf = pw.Document();
    final formattedDate = DateFormat('dd.MM.yyyy').format(data.date);
    final totalPrice = data.price != null
        ? (data.price! * data.quantity).toStringAsFixed(2)
        : '0.00';

    // Load fonts with Cyrillic support using PdfGoogleFont
    final fontRegular = await PdfGoogleFont.roboto();
    final fontBold = await PdfGoogleFont.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Шапка документа
              _buildHeader(header, fontRegular, fontBold),
              pw.SizedBox(height: 30),
              // Заголовок документа
              pw.Center(
                child: pw.Text(
                  'АКТ ПРИЕМА-ПЕРЕДАЧИ ОБОРУДОВАНИЯ',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    font: fontBold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              // Дата документа
              pw.Text(
                'Дата составления: $formattedDate',
                style: pw.TextStyle(fontSize: 12, font: fontRegular),
              ),
              pw.SizedBox(height: 20),
              // Информация о передаче
              pw.Text(
                'Настоящий акт составлен в том, что между сторонами произведена передача '
                'оборудования со следующими характеристиками:',
                style: pw.TextStyle(fontSize: 11, font: fontRegular),
              ),
              pw.SizedBox(height: 20),
              // Таблица с оборудованием
              _buildEquipmentTable(data, totalPrice, fontRegular, fontBold),
              pw.SizedBox(height: 30),
              // Информация о сторонах
              pw.Text(
                'Получатель: ${data.fio}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  font: fontBold,
                ),
              ),
              pw.SizedBox(height: 20),
              // Подписи
              _buildSignatures(fontRegular, fontBold),
              pw.SizedBox(height: 30),
              // Примечание
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                ),
                child: pw.Text(
                  'Примечание: Оборудование передано в исправном состоянии, '
                  'комплектация полная. Претензий к качеству и комплектности не имею.',
                  style: pw.TextStyle(fontSize: 10, font: fontRegular),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(
    DocumentHeaderSettings header,
    pw.Font fontRegular,
    pw.Font fontBold,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (header.organizationName.isNotEmpty)
          pw.Text(
            header.organizationName,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: fontBold,
            ),
          ),
        if (header.department.isNotEmpty)
          pw.Text(
            'Отдел: ${header.department}',
            style: pw.TextStyle(fontSize: 11, font: fontRegular),
          ),
        if (header.address.isNotEmpty)
          pw.Text(
            'Адрес: ${header.address}',
            style: pw.TextStyle(fontSize: 11, font: fontRegular),
          ),
        if (header.phone.isNotEmpty)
          pw.Text(
            'Телефон: ${header.phone}',
            style: pw.TextStyle(fontSize: 11, font: fontRegular),
          ),
      ],
    );
  }

  pw.Widget _buildEquipmentTable(
    DocumentData data,
    String totalPrice,
    pw.Font fontRegular,
    pw.Font fontBold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Заголовок таблицы
        pw.TableRow(
          children: [
            _buildTableCell('Наименование оборудования',
                isHeader: true, fontRegular: fontRegular, fontBold: fontBold),
            _buildTableCell('Кол-во',
                isHeader: true, fontRegular: fontRegular, fontBold: fontBold),
            _buildTableCell('Цена за ед.',
                isHeader: true, fontRegular: fontRegular, fontBold: fontBold),
            _buildTableCell('Сумма',
                isHeader: true, fontRegular: fontRegular, fontBold: fontBold),
          ],
        ),
        // Данные
        pw.TableRow(
          children: [
            _buildTableCell(data.equipmentName,
                fontRegular: fontRegular, fontBold: fontBold),
            _buildTableCell(data.quantity.toString(),
                fontRegular: fontRegular, fontBold: fontBold),
            _buildTableCell(data.formattedPrice,
                fontRegular: fontRegular, fontBold: fontBold),
            _buildTableCell('$totalPrice ₽',
                fontRegular: fontRegular, fontBold: fontBold),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    required pw.Font fontRegular,
    required pw.Font fontBold,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
          font: isHeader ? fontBold : fontRegular,
        ),
      ),
    );
  }

  pw.Widget _buildSignatures(
    pw.Font fontRegular,
    pw.Font fontBold,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Сдал:',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  font: fontBold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      height: 30,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.black),
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text('(подпись)',
                      style: pw.TextStyle(fontSize: 8, font: fontRegular)),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Принял:',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  font: fontBold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      height: 30,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.black),
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text('(подпись)',
                      style: pw.TextStyle(fontSize: 8, font: fontRegular)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> printDocument(
    DocumentData data,
    DocumentHeaderSettings header,
  ) async {
    try {
      final pdfBytes = await generatePdf(data, header);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      throw Exception('Ошибка печати документа: $e');
    }
  }

  Future<String> saveDocument(
    DocumentData data,
    DocumentHeaderSettings header,
  ) async {
    try {
      final pdfBytes = await generatePdf(data, header);
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'document_${data.inventoryNumber}_${DateFormat('yyyyMMdd').format(data.date)}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      throw Exception('Ошибка сохранения документа: $e');
    }
  }

  Future<void> previewDocument(
    BuildContext context,
    DocumentData data,
    DocumentHeaderSettings header,
  ) async {
    try {
      final pdfBytes = await generatePdf(data, header);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Предпросмотр документа'),
            ),
            body: PdfPreview(
              build: (format) => pdfBytes,
              canChangeOrientation: false,
              canChangePageFormat: false,
              allowPrinting: true,
              allowSharing: true,
            ),
          ),
        ),
      );
    } catch (e) {
      throw Exception('Ошибка предпросмотра документа: $e');
    }
  }
}
