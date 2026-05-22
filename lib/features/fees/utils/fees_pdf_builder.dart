import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/models/invoice.dart';

class _FeesPayload {
  const _FeesPayload({
    required this.invoices,
    required this.regularFontBytes,
    required this.boldFontBytes,
  });
  final List<Invoice> invoices;
  // Pre-loaded on the main isolate; rootBundle/CDN are not isolate-safe.
  final Uint8List? regularFontBytes;
  final Uint8List? boldFontBytes;
}

@pragma('vm:entry-point')
Future<Uint8List> _buildFeesPdfInIsolate(_FeesPayload p) =>
    FeesPdfBuilder.buildBytesSync(
      p.invoices,
      regularFontBytes: p.regularFontBytes,
      boldFontBytes: p.boldFontBytes,
    );

/// Builds and shares a PDF report of all invoices.
///
/// Used by:
///   - Overview quick-action "Export Report"  (fees_screen.dart)
///   - Collection tab "Export" button          (fees_screen.dart)
class FeesPdfBuilder {
  FeesPdfBuilder._();

  static const _primary = PdfColor.fromInt(0xFF6366F1);
  static const _textColor = PdfColor.fromInt(0xFF0F172A);
  static const _grey = PdfColor.fromInt(0xFF64748B);
  static const _border = PdfColor.fromInt(0xFFE2E8F0);

  /// Builds PDF bytes for [invoices] and shares them via the OS share sheet.
  /// Fonts are loaded on the main isolate (rootBundle is not isolate-safe),
  /// then the PDF assembly runs on a background isolate.
  static Future<void> buildAndShare(List<Invoice> invoices) async {
    final regularBytes = await _loadFontBytes('assets/fonts/NotoSans-Regular.ttf');
    final boldBytes = await _loadFontBytes('assets/fonts/NotoSans-Bold.ttf');
    final payload = _FeesPayload(
      invoices: invoices,
      regularFontBytes: regularBytes,
      boldFontBytes: boldBytes,
    );
    final bytes = kIsWeb
        ? await _buildFeesPdfInIsolate(payload)
        : await compute(_buildFeesPdfInIsolate, payload);
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await Printing.sharePdf(bytes: bytes, filename: 'fees-report-$date.pdf');
  }

  /// Reads a bundled font as bytes. Returns null if not found — the isolate
  /// will fall back to the bundled Helvetica.
  static Future<Uint8List?> _loadFontBytes(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// Same-isolate builder. Public for the isolate entry function.
  static Future<Uint8List> buildBytesSync(
    List<Invoice> invoices, {
    Uint8List? regularFontBytes,
    Uint8List? boldFontBytes,
  }) async {
    final regular = regularFontBytes != null
        ? pw.Font.ttf(regularFontBytes.buffer.asByteData())
        : await PdfGoogleFonts.notoSansRegular();
    final bold = boldFontBytes != null
        ? pw.Font.ttf(boldFontBytes.buffer.asByteData())
        : await PdfGoogleFonts.notoSansBold();
    final theme = pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      fontFallback: [regular],
    );

    final pdf = pw.Document(
      title: 'Fees Collection Report',
      author: 'School Management System',
      theme: theme,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => _buildHeader(),
        build: (_) => [
          pw.SizedBox(height: 16),
          _buildTable(invoices),
          pw.SizedBox(height: 12),
          _buildSummary(invoices),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader() {
    final now = DateFormat('d MMM yyyy, hh:mm a').format(DateTime.now());
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Fees Collection Report',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: _primary,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Generated: $now',
          style: const pw.TextStyle(fontSize: 10, color: _grey),
        ),
        pw.Divider(color: _border),
      ],
    );
  }

  static pw.Widget _buildTable(List<Invoice> invoices) {
    final headers = ['Invoice #', 'Student', 'Amount (₹)', 'Due Date', 'Status'];
    final rows = invoices.map((inv) {
      final due = DateFormat('d MMM yyyy').format(inv.dueDate);
      return [
        inv.invoiceNumber,
        inv.studentName ?? '—',
        inv.totalAmount.toStringAsFixed(0),
        due,
        inv.status.toUpperCase(),
      ];
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primary),
          children: headers.map((h) => _cell(h, isHeader: true)).toList(),
        ),
        // Data rows
        ...rows.asMap().entries.map((entry) {
          final isEven = entry.key.isEven;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven
                  ? const PdfColor.fromInt(0xFFF8FAFC)
                  : PdfColors.white,
            ),
            children: entry.value.map((v) => _cell(v)).toList(),
          );
        }),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : _textColor,
        ),
      ),
    );
  }

  static pw.Widget _buildSummary(List<Invoice> invoices) {
    final total = invoices.fold<double>(0, (s, inv) => s + inv.totalAmount);
    final paid = invoices
        .where((inv) => inv.isPaid)
        .fold<double>(0, (s, inv) => s + inv.paidAmount);
    final pending = total - paid;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFEEF2FF),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
            ),
          ),
          pw.SizedBox(height: 6),
          _summaryRow('Total Invoices', '${invoices.length}'),
          _summaryRow('Total Amount', '₹${total.toStringAsFixed(0)}'),
          _summaryRow('Paid', '₹${paid.toStringAsFixed(0)}'),
          _summaryRow('Pending / Overdue', '₹${pending.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 10, color: _grey)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold, color: _textColor)),
        ],
      ),
    );
  }
}
