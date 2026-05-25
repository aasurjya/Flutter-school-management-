import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/models/invoice.dart';

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
  static Future<void> buildAndShare(List<Invoice> invoices) async {
    final bytes = await _buildBytes(invoices);
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await Printing.sharePdf(bytes: bytes, filename: 'fees-report-$date.pdf');
  }

  /// Defaulter list — overdue invoices grouped by class, with days
  /// overdue and pending amount. Shares via OS share sheet.
  static Future<void> buildAndShareDefaulters(List<Invoice> overdue) async {
    final bytes = await _buildDefaulterBytes(overdue);
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'defaulters-$date.pdf',
    );
  }

  static Future<void> buildAndPrintDefaulters(List<Invoice> overdue) async {
    final bytes = await _buildDefaulterBytes(overdue);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  /// Loads Noto Sans fonts: bundled asset first, Google Fonts CDN as fallback.
  static Future<pw.Font> _loadFont(
    String assetPath,
    Future<pw.Font> Function() cdnLoader,
  ) async {
    try {
      final data = await rootBundle.load(assetPath);
      return pw.Font.ttf(data);
    } catch (_) {
      return cdnLoader();
    }
  }

  /// Returns raw PDF bytes. Exposed for testing.
  static Future<Uint8List> _buildBytes(List<Invoice> invoices) async {
    final regular = await _loadFont(
      'assets/fonts/NotoSans-Regular.ttf',
      PdfGoogleFonts.notoSansRegular,
    );
    final bold = await _loadFont(
      'assets/fonts/NotoSans-Bold.ttf',
      PdfGoogleFonts.notoSansBold,
    );
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

  static pw.Widget _cell(String text,
      {bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.white : _textColor),
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

  /// Defaulter PDF: group overdue invoices by class, show days overdue
  /// and pending amount per row. Tail summary aggregates dues.
  static Future<Uint8List> _buildDefaulterBytes(List<Invoice> overdue) async {
    final regular = await _loadFont(
      'assets/fonts/NotoSans-Regular.ttf',
      PdfGoogleFonts.notoSansRegular,
    );
    final bold = await _loadFont(
      'assets/fonts/NotoSans-Bold.ttf',
      PdfGoogleFonts.notoSansBold,
    );
    final theme = pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      fontFallback: [regular],
    );
    final pdf = pw.Document(
      title: 'Fee Defaulter Report',
      theme: theme,
    );

    // group by className (or 'Unassigned')
    final groups = <String, List<Invoice>>{};
    for (final inv in overdue) {
      final key = inv.className ?? 'Unassigned';
      groups.putIfAbsent(key, () => []).add(inv);
    }
    final sortedKeys = groups.keys.toList()..sort();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => _defaulterHeader(overdue.length),
        build: (_) {
          final widgets = <pw.Widget>[];
          widgets.add(pw.SizedBox(height: 12));
          for (final cls in sortedKeys) {
            widgets.add(_classSectionTitle(cls, groups[cls]!.length));
            widgets.add(pw.SizedBox(height: 4));
            widgets.add(_defaulterTable(groups[cls]!));
            widgets.add(pw.SizedBox(height: 14));
          }
          widgets.add(_buildSummary(overdue));
          return widgets;
        },
      ),
    );
    return pdf.save();
  }

  static pw.Widget _defaulterHeader(int count) {
    final now = DateFormat('d MMM yyyy, hh:mm a').format(DateTime.now());
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Fee Defaulter Report',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: _primary,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '$count overdue invoices · Generated $now',
          style: const pw.TextStyle(fontSize: 10, color: _grey),
        ),
        pw.Divider(color: _border),
      ],
    );
  }

  static pw.Widget _classSectionTitle(String cls, int rows) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: const PdfColor.fromInt(0xFFEEF2FF),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(cls,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _primary,
              )),
          pw.Text('$rows defaulters',
              style: const pw.TextStyle(fontSize: 9, color: _grey)),
        ],
      ),
    );
  }

  static pw.Widget _defaulterTable(List<Invoice> invoices) {
    final today = DateTime.now();
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.4),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.5),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.2),
        4: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF1F5F9)),
          children: [
            _cell('Student', isHeader: true, color: _textColor),
            _cell('Invoice #', isHeader: true, color: _textColor),
            _cell('Due Date', isHeader: true, color: _textColor),
            _cell('Days', isHeader: true, color: _textColor),
            _cell('Pending', isHeader: true, color: _textColor),
          ],
        ),
        ...invoices.map((inv) {
          final days = today.difference(inv.dueDate).inDays;
          final pending = inv.totalAmount - inv.discountAmount - inv.paidAmount;
          return pw.TableRow(children: [
            _cell(inv.studentName ?? '—'),
            _cell(inv.invoiceNumber),
            _cell(DateFormat('d MMM').format(inv.dueDate)),
            _cell('$days',
                color: days > 30
                    ? const PdfColor.fromInt(0xFFDC2626)
                    : _textColor),
            _cell('₹ ${pending.toStringAsFixed(0)}'),
          ]);
        }),
      ],
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
