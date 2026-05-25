import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/models/invoice.dart';
import '../../../data/models/tenant.dart';

/// Per-student fee statement — every invoice + every payment in one
/// document, with running balance. Used by admin on a single student row
/// and by the parent/student in their own fee history.
class FeeStatementPdfBuilder {
  FeeStatementPdfBuilder._();

  static const _primary = PdfColor.fromInt(0xFF6366F1);
  static const _ink = PdfColor.fromInt(0xFF0F172A);
  static const _muted = PdfColor.fromInt(0xFF64748B);
  static const _border = PdfColor.fromInt(0xFFE2E8F0);
  static const _danger = PdfColor.fromInt(0xFFDC2626);
  static const _ok = PdfColor.fromInt(0xFF16A34A);

  static Future<void> buildAndShare({
    required FeeSummary summary,
    required List<Invoice> invoices,
    required List<Payment> payments,
    Tenant? tenant,
  }) async {
    final bytes = await buildBytes(
      summary: summary,
      invoices: invoices,
      payments: payments,
      tenant: tenant,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'statement-${summary.admissionNumber}.pdf',
    );
  }

  static Future<void> buildAndPrint({
    required FeeSummary summary,
    required List<Invoice> invoices,
    required List<Payment> payments,
    Tenant? tenant,
  }) async {
    final bytes = await buildBytes(
      summary: summary,
      invoices: invoices,
      payments: payments,
      tenant: tenant,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<Uint8List> buildBytes({
    required FeeSummary summary,
    required List<Invoice> invoices,
    required List<Payment> payments,
    Tenant? tenant,
  }) async {
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
      title: 'Fee Statement — ${summary.studentName}',
      author: tenant?.name ?? 'School',
      theme: theme,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => _header(tenant),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ),
        build: (_) => [
          pw.SizedBox(height: 6),
          _title(summary),
          pw.SizedBox(height: 16),
          _studentCard(summary),
          pw.SizedBox(height: 16),
          _summaryStrip(summary),
          pw.SizedBox(height: 18),
          _sectionTitle('Invoices'),
          pw.SizedBox(height: 6),
          if (invoices.isEmpty)
            _emptyLine('No invoices for this academic year.')
          else
            _invoicesTable(invoices),
          pw.SizedBox(height: 18),
          _sectionTitle('Payments'),
          pw.SizedBox(height: 6),
          if (payments.isEmpty)
            _emptyLine('No payments recorded.')
          else
            _paymentsTable(payments),
        ],
      ),
    );

    return pdf.save();
  }

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

  static pw.Widget _header(Tenant? t) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(t?.name ?? 'School',
                    style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink)),
                if (t?.fullAddress.isNotEmpty == true)
                  pw.Text(t!.fullAddress,
                      style: const pw.TextStyle(fontSize: 8, color: _muted)),
              ],
            ),
            pw.Text(
              DateFormat('d MMM yyyy').format(DateTime.now()),
              style: const pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: _border, thickness: 0.4),
      ],
    );
  }

  static pw.Widget _title(FeeSummary s) {
    return pw.Container(
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        'FEE STATEMENT — ${s.academicYearName}',
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  static pw.Widget _studentCard(FeeSummary s) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8FAFC),
        border: pw.Border.all(color: _border, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          _kv('Student', s.studentName),
          _kv('Admission #', s.admissionNumber),
          _kv('Class', '${s.className} - ${s.sectionName}'),
        ],
      ),
    );
  }

  static pw.Widget _kv(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 8, color: _muted)),
          pw.SizedBox(height: 2),
          pw.Text(value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              )),
        ],
      ),
    );
  }

  static pw.Widget _summaryStrip(FeeSummary s) {
    pw.Widget chip(String label, String amount, PdfColor accent, PdfColor bg) {
      return pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 3),
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: pw.BoxDecoration(
            color: bg,
            border: pw.Border.all(color: accent, width: 0.4),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(fontSize: 8, color: accent)),
              pw.SizedBox(height: 4),
              pw.Text(amount,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  )),
            ],
          ),
        ),
      );
    }

    final outstandingAccent = s.totalPending > 0 ? _danger : _ok;
    final outstandingBg = s.totalPending > 0
        ? const PdfColor.fromInt(0xFFFEF2F2)
        : const PdfColor.fromInt(0xFFECFDF5);
    return pw.Row(children: [
      chip('Total billed', '₹ ${s.totalFee.toStringAsFixed(0)}', _primary,
          const PdfColor.fromInt(0xFFEEF2FF)),
      chip('Discount', '₹ ${s.totalDiscount.toStringAsFixed(0)}',
          const PdfColor.fromInt(0xFFCA8A04),
          const PdfColor.fromInt(0xFFFFFBEB)),
      chip('Paid', '₹ ${s.totalPaid.toStringAsFixed(0)}', _ok,
          const PdfColor.fromInt(0xFFECFDF5)),
      chip('Outstanding', '₹ ${s.totalPending.toStringAsFixed(0)}',
          outstandingAccent, outstandingBg),
    ]);
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Text(text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: _primary,
          letterSpacing: 0.3,
        ));
  }

  static pw.Widget _emptyLine(String msg) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Text(msg,
          style: pw.TextStyle(
              fontSize: 9,
              color: _muted,
              fontStyle: pw.FontStyle.italic)),
    );
  }

  static pw.Widget _invoicesTable(List<Invoice> invoices) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.4),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.5),
        4: pw.FlexColumnWidth(1.5),
        5: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF1F5F9)),
          children: [
            _cell('Invoice #', isHeader: true),
            _cell('Term', isHeader: true),
            _cell('Total', isHeader: true, align: pw.TextAlign.right),
            _cell('Paid', isHeader: true, align: pw.TextAlign.right),
            _cell('Balance', isHeader: true, align: pw.TextAlign.right),
            _cell('Status', isHeader: true),
          ],
        ),
        ...invoices.map((inv) {
          final balance = inv.totalAmount - inv.discountAmount - inv.paidAmount;
          return pw.TableRow(children: [
            _cell(inv.invoiceNumber),
            _cell(inv.termName ?? '—'),
            _cell('₹ ${inv.totalAmount.toStringAsFixed(0)}',
                align: pw.TextAlign.right),
            _cell('₹ ${inv.paidAmount.toStringAsFixed(0)}',
                align: pw.TextAlign.right),
            _cell('₹ ${balance.toStringAsFixed(0)}',
                align: pw.TextAlign.right,
                color: balance > 0 ? _danger : _ok),
            _cell(inv.status.toUpperCase(),
                color: inv.status == 'paid' ? _ok : _danger),
          ]);
        }),
      ],
    );
  }

  static pw.Widget _paymentsTable(List<Payment> payments) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.4),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1.6),
        2: pw.FlexColumnWidth(1.4),
        3: pw.FlexColumnWidth(1.6),
        4: pw.FlexColumnWidth(1.6),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF1F5F9)),
          children: [
            _cell('Receipt #', isHeader: true),
            _cell('Date', isHeader: true),
            _cell('Method', isHeader: true),
            _cell('Amount', isHeader: true, align: pw.TextAlign.right),
            _cell('Status', isHeader: true),
          ],
        ),
        ...payments.map((p) {
          final date = p.paidAt ?? p.createdAt;
          return pw.TableRow(children: [
            _cell(p.paymentNumber),
            _cell(date != null
                ? DateFormat('d MMM yyyy').format(date)
                : '—'),
            _cell(p.paymentMethod.toUpperCase()),
            _cell('₹ ${p.amount.toStringAsFixed(0)}',
                align: pw.TextAlign.right, color: _ok),
            _cell(p.status.toUpperCase(),
                color: p.status == 'completed' ? _ok : _muted),
          ]);
        }),
      ],
    );
  }

  static pw.Widget _cell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? _ink,
        ),
      ),
    );
  }
}
