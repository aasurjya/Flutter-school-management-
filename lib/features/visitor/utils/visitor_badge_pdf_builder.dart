import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../data/models/visitor.dart';

/// Builds a 4×6 inch visitor badge PDF — one page, designed to be
/// printed and pinned to a lanyard at reception. Falls back gracefully
/// when optional fields are null.
class VisitorBadgePdfBuilder {
  static Future<Uint8List> build({
    required Visitor visitor,
    required VisitorLog log,
    String? schoolName,
  }) async {
    final doc = pw.Document();
    const format = PdfPageFormat(
      4 * PdfPageFormat.inch,
      6 * PdfPageFormat.inch,
      marginAll: 18,
    );
    final df = DateFormat('MMM d, yyyy');
    final tf = DateFormat('h:mm a');

    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // School name header
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              alignment: pw.Alignment.center,
              child: pw.Text(
                (schoolName ?? 'School').toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            // VISITOR banner
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              decoration: const pw.BoxDecoration(color: PdfColors.black),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'VISITOR',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
            pw.SizedBox(height: 14),
            // Name
            pw.Text(
              visitor.fullName,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
            if (visitor.company != null && visitor.company!.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                visitor.company!,
                style: const pw.TextStyle(fontSize: 11),
                textAlign: pw.TextAlign.center,
              ),
            ],
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 8),
            // Detail rows
            _detailRow('Purpose', _purposeLabel(log.purpose)),
            _detailRow('Host',
                log.personToMeetName ?? log.personToMeet ?? '—'),
            if (log.department != null && log.department!.isNotEmpty)
              _detailRow('Dept', log.department!),
            _detailRow('Date', df.format(log.checkInTime)),
            _detailRow('Time', tf.format(log.checkInTime)),
            if (log.badgeNumber != null && log.badgeNumber!.isNotEmpty)
              _detailRow('Badge #', log.badgeNumber!),
            pw.Spacer(),
            // QR code → visitor log id for re-scan on check-out
            pw.Center(
              child: pw.SizedBox(
                width: 96,
                height: 96,
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: 'visitor:${log.id}',
                  drawText: false,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Return at exit',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey700),
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _detailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 54,
            child: pw.Text(
              label.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  static String _purposeLabel(VisitorLogPurpose p) => p.label;
}
