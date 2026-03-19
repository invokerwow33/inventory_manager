import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../models/event.dart';
import '../models/cinema_hall.dart';

class TicketPrintService {
  /// Генерация PDF билета
  static Future<void> printTicket({
    required Ticket ticket,
    required TicketSale sale,
    required Screening screening,
    required Event event,
    required CinemaHall hall,
    required Seat seat,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                // Заголовок
                pw.Text(
                  'КИНОТЕАТР',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                
                // Название фильма
                pw.Text(
                  event.title,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 10),
                
                // Разделитель
                pw.Container(
                  width: double.infinity,
                  height: 1,
                  color: PdfColors.grey,
                ),
                pw.SizedBox(height: 10),
                
                // Информация о сеансе
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Дата:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(screening.dateLabel),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Время:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(screening.startTimeLabel),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Зал:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(hall.name),
                  ],
                ),
                pw.SizedBox(height: 10),
                
                // Разделитель
                pw.Container(
                  width: double.infinity,
                  height: 1,
                  color: PdfColors.grey,
                ),
                pw.SizedBox(height: 10),
                
                // Место
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Ряд:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${seat.row}'),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Место:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${seat.seatNumber}'),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Тип:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(seat.seatType.label),
                  ],
                ),
                pw.SizedBox(height: 10),
                
                // Разделитель
                pw.Container(
                  width: double.infinity,
                  height: 1,
                  color: PdfColors.grey,
                ),
                pw.SizedBox(height: 10),
                
                // Цена
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Цена:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${ticket.price.toStringAsFixed(0)} ₽'),
                  ],
                ),
                pw.SizedBox(height: 10),
                
                // Разделитель
                pw.Container(
                  width: double.infinity,
                  height: 1,
                  color: PdfColors.grey,
                ),
                pw.SizedBox(height: 10),
                
                // Номер билета
                pw.Text(
                  'Билет № ${ticket.id.substring(0, 8)}',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 5),
                
                // Дата продажи
                pw.Text(
                  'Продан: ${sale.saleDate.day.toString().padLeft(2, '0')}.${sale.saleDate.month.toString().padLeft(2, '0')}.${sale.saleDate.year} ${sale.saleDate.hour.toString().padLeft(2, '0')}:${sale.saleDate.minute.toString().padLeft(2, '0')}',
                  style: pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 10),
                
                // Кассир
                if (sale.cashierName.isNotEmpty) ...[
                  pw.Text(
                    'Кассир: ${sale.cashierName}',
                    style: pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 5),
                ],
                
                // Призыв
                pw.SizedBox(height: 10),
                pw.Text(
                  'Приятного просмотра!',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );

    // Печать или сохранение
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Билет_${ticket.id.substring(0, 8)}.pdf',
    );
  }

  /// Печать нескольких билетов
  static Future<void> printTickets({
    required List<Map<String, dynamic>> tickets,
  }) async {
    final pdf = pw.Document();

    for (final ticketData in tickets) {
      final ticket = ticketData['ticket'] as Ticket;
      final screening = ticketData['screening'] as Screening;
      final event = ticketData['event'] as Event;
      final hall = ticketData['hall'] as CinemaHall;
      final seat = ticketData['seat'] as Seat;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Text(
                    'КИНОТЕАТР',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    event.title,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    width: double.infinity,
                    height: 1,
                    color: PdfColors.grey,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Дата:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(screening.dateLabel),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Время:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(screening.startTimeLabel),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Зал:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(hall.name),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    width: double.infinity,
                    height: 1,
                    color: PdfColors.grey,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Ряд:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${seat.row}'),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Место:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${seat.seatNumber}'),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Цена:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${ticket.price.toStringAsFixed(0)} ₽'),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    width: double.infinity,
                    height: 1,
                    color: PdfColors.grey,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    ticket.barcode ?? ticket.id,
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Приятного просмотра!',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Билеты.pdf',
    );
  }

  /// Сохранение билета в файл
  static Future<String?> saveTicketToFile({
    required Ticket ticket,
    required TicketSale sale,
    required Screening screening,
    required Event event,
    required CinemaHall hall,
    required Seat seat,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Text('КИНОТЕАТР', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text(event.title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Container(width: double.infinity, height: 1, color: PdfColors.grey),
                  pw.SizedBox(height: 10),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text('Дата:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(screening.dateLabel),
                  ]),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text('Время:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(screening.startTimeLabel),
                  ]),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text('Зал:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(hall.name),
                  ]),
                  pw.SizedBox(height: 10),
                  pw.Container(width: double.infinity, height: 1, color: PdfColors.grey),
                  pw.SizedBox(height: 10),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text('Ряд:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${seat.row}'),
                  ]),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text('Место:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${seat.seatNumber}'),
                  ]),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text('Цена:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${ticket.price.toStringAsFixed(0)} ₽'),
                  ]),
                  pw.SizedBox(height: 10),
                  pw.Container(width: double.infinity, height: 1, color: PdfColors.grey),
                  pw.SizedBox(height: 5),
                  pw.Text(ticket.id, style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 10),
                  pw.Text('Приятного просмотра!', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
                ],
              ),
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/tickets/ticket_${ticket.id.substring(0, 8)}.pdf';
      final file = File(filePath);
      
      await file.create(recursive: true);
      await file.writeAsBytes(await pdf.save());
      
      return filePath;
    } catch (e) {
      print('Ошибка сохранения билета: $e');
      return null;
    }
  }
}
