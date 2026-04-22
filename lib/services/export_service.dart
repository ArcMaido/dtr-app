import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/time_record.dart';

class ExportService {
  static Future<List<Directory>> _getPreferredExportDirectories() async {
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      final documentsDir = Directory('/storage/emulated/0/Documents');
      return [downloadDir, documentsDir];
    }

    return [await getApplicationDocumentsDirectory()];
  }

  static Future<File> _writeToPreferredLocation(
    String fileName,
    Future<File> Function(File file) writer,
  ) async {
    final directories = await _getPreferredExportDirectories();
    Object? lastError;

    for (final dir in directories) {
      try {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        final file = File('${dir.path}/$fileName');
        return await writer(file);
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception(
      'Unable to save file in Downloads or Documents. Please allow Files permission and try again. ($lastError)',
    );
  }

  // Export records to CSV format
  static Future<String> exportToCSV(List<TimeRecord> records) async {
    final List<List<String>> csvData = [
      ['Date', 'Time In', 'Time Out', 'Total Hours'],
    ];

    for (var record in records) {
      csvData.add([
        DateFormat('MMM dd, yyyy').format(record.date),
        record.timeIn != null
            ? DateFormat('hh:mm a').format(record.timeIn!)
            : 'N/A',
        record.timeOut != null
            ? DateFormat('hh:mm a').format(record.timeOut!)
            : 'N/A',
        (record.totalHours ?? 0).toStringAsFixed(2),
      ]);
    }

    return const ListToCsvConverter(eol: '\n').convert(csvData);
  }

  // Save CSV to file
  static Future<File> saveCSVFile(String csv, String fileName) async {
    return _writeToPreferredLocation(
      fileName,
      (file) => file.writeAsString(csv),
    );
  }

  // Export records to PDF format with pagination
  static Future<Uint8List> exportToPDF(List<TimeRecord> records) async {
    final pdf = pw.Document();
    const int recordsPerPage = 15;
    final totalPages = (records.length / recordsPerPage).ceil();
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    for (int pageNum = 0; pageNum < totalPages; pageNum++) {
      final startIdx = pageNum * recordsPerPage;
      final endIdx = (startIdx + recordsPerPage > records.length)
          ? records.length
          : startIdx + recordsPerPage;
      final pageRecords = records.sublist(startIdx, endIdx);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Text(
              'Daily Time Record Export',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                font: boldFont,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Page ${pageNum + 1} of $totalPages',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromInt(0xFF999999),
                font: regularFont,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: const ['Date', 'Time In', 'Time Out', 'Total Hours'],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                font: boldFont,
              ),
              cellStyle: pw.TextStyle(font: regularFont),
              data: pageRecords
                  .map(
                    (record) => [
                      DateFormat('MMM dd, yyyy').format(record.date),
                      record.timeIn != null
                          ? DateFormat('hh:mm a').format(record.timeIn!)
                          : 'N/A',
                      record.timeOut != null
                          ? DateFormat('hh:mm a').format(record.timeOut!)
                          : 'N/A',
                      (record.totalHours ?? 0).toStringAsFixed(2),
                    ],
                  )
                  .toList(),
            ),
          ],
        ),
      );
    }

    return pdf.save();
  }

  // Save PDF to file
  static Future<File> savePdfFile(Uint8List pdfBytes, String fileName) async {
    return _writeToPreferredLocation(
      fileName,
      (file) => file.writeAsBytes(pdfBytes),
    );
  }

  // Generate timestamp for file naming
  static String generateTimestamp() {
    return DateFormat('yyyy_MM_dd_HHmmss').format(DateTime.now());
  }
}
