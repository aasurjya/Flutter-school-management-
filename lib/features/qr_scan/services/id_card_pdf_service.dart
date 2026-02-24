import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/models/student.dart';
import '../utils/qr_data_utils.dart';

/// Generates, prints, and shares student ID card PDFs.
class IdCardPdfService {
  IdCardPdfService._();

  /// Build the PDF document for a student ID card.
  static Future<pw.Document> generateIdCard(
    Student student, {
    String schoolName = 'School Management',
  }) async {
    final pdf = pw.Document();

    final qrData = QrDataUtils.encode(
      tenantId: student.tenantId,
      admissionNumber: student.admissionNumber,
    );

    // Credit-card size: 85.6mm x 53.98mm
    const cardWidth = 85.6 * PdfPageFormat.mm;
    const cardHeight = 53.98 * PdfPageFormat.mm;

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(cardWidth, cardHeight),
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Container(
            width: cardWidth,
            height: cardHeight,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#6366F1'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // School name
                pw.Text(
                  schoolName.toUpperCase(),
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'STUDENT ID CARD',
                  style: const pw.TextStyle(
                    color: PdfColor.fromInt(0xBBFFFFFF),
                    fontSize: 6,
                    letterSpacing: 1,
                  ),
                ),
                pw.Spacer(),
                // Bottom row: info + QR
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Student initials box
                    pw.Container(
                      width: 32,
                      height: 32,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        student.initials,
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#6366F1'),
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    // Name / class / admission
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            student.fullName,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            maxLines: 1,
                          ),
                          pw.SizedBox(height: 1),
                          pw.Text(
                            student.currentClass,
                            style: const pw.TextStyle(
                              color: PdfColor.fromInt(0xCCFFFFFF),
                              fontSize: 7,
                            ),
                          ),
                          pw.SizedBox(height: 1),
                          pw.Text(
                            'ADM: ${student.admissionNumber}',
                            style: const pw.TextStyle(
                              color: PdfColor.fromInt(0xAAFFFFFF),
                              fontSize: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // QR barcode
                    pw.Container(
                      padding: const pw.EdgeInsets.all(3),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.BarcodeWidget(
                        data: qrData,
                        barcode: pw.Barcode.qrCode(),
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  /// Print the student ID card directly.
  static Future<void> printIdCard(
    Student student, {
    String schoolName = 'School Management',
  }) async {
    final pdf = await generateIdCard(student, schoolName: schoolName);
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'ID_Card_${student.admissionNumber}',
    );
  }

  /// Share the student ID card via the system share sheet.
  static Future<void> shareIdCard(
    Student student, {
    String schoolName = 'School Management',
  }) async {
    final pdf = await generateIdCard(student, schoolName: schoolName);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'ID_Card_${student.admissionNumber}.pdf',
    );
  }

  /// Save the PDF to the app's documents directory and return the path.
  static Future<String> saveIdCardPdf(
    Student student, {
    String schoolName = 'School Management',
  }) async {
    final pdf = await generateIdCard(student, schoolName: schoolName);
    final dir = await getApplicationDocumentsDirectory();
    final file =
        File('${dir.path}/ID_Card_${student.admissionNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}
