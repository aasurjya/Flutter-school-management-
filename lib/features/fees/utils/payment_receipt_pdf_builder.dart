import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/models/invoice.dart';
import '../../../data/models/tenant.dart';

/// Per-payment receipt PDF.
///
/// Renders a single-page A5-ish receipt with school header, student
/// details, invoice reference, amount in words, payment method, and a
/// "Computer generated — no signature required" footer. Designed for
/// thermal-printer-friendly compact width but readable at A4 too.
class PaymentReceiptPdfBuilder {
  PaymentReceiptPdfBuilder._();

  static const _primary = PdfColor.fromInt(0xFF6366F1);
  static const _ink = PdfColor.fromInt(0xFF0F172A);
  static const _muted = PdfColor.fromInt(0xFF64748B);
  static const _border = PdfColor.fromInt(0xFFE2E8F0);
  static const _ok = PdfColor.fromInt(0xFF16A34A);

  /// Builds PDF bytes and offers the OS share sheet.
  static Future<void> buildAndShare({
    required Payment payment,
    required Invoice invoice,
    Tenant? tenant,
  }) async {
    final bytes = await buildBytes(
      payment: payment,
      invoice: invoice,
      tenant: tenant,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'receipt-${payment.paymentNumber}.pdf',
    );
  }

  /// Sends straight to the OS print dialog.
  static Future<void> buildAndPrint({
    required Payment payment,
    required Invoice invoice,
    Tenant? tenant,
  }) async {
    final bytes = await buildBytes(
      payment: payment,
      invoice: invoice,
      tenant: tenant,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  /// Raw bytes — exposed for testing and for callers that want to upload
  /// the receipt to Supabase Storage before sharing the URL.
  static Future<Uint8List> buildBytes({
    required Payment payment,
    required Invoice invoice,
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
      title: 'Receipt ${payment.paymentNumber}',
      author: tenant?.name ?? 'School',
      theme: theme,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(tenant),
            pw.SizedBox(height: 16),
            _receiptMeta(payment, invoice),
            pw.SizedBox(height: 16),
            _studentBlock(invoice),
            pw.SizedBox(height: 16),
            _amountBlock(payment, invoice),
            pw.SizedBox(height: 16),
            _itemsTable(invoice),
            pw.SizedBox(height: 20),
            _balanceBlock(invoice, payment),
            pw.Spacer(),
            _footer(),
          ],
        ),
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
                pw.Text(
                  t?.name ?? 'School',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                if (t?.fullAddress.isNotEmpty == true)
                  pw.Text(
                    t!.fullAddress,
                    style: const pw.TextStyle(fontSize: 9, color: _muted),
                  ),
                pw.SizedBox(height: 2),
                pw.Row(children: [
                  if (t?.phone != null)
                    pw.Text('Tel: ${t!.phone}',
                        style: const pw.TextStyle(fontSize: 9, color: _muted)),
                  if (t?.phone != null && t?.email != null)
                    pw.Text('   ·   ',
                        style: const pw.TextStyle(fontSize: 9, color: _muted)),
                  if (t?.email != null)
                    pw.Text(t!.email!,
                        style: const pw.TextStyle(fontSize: 9, color: _muted)),
                ]),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: _primary,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'PAYMENT RECEIPT',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: _border, thickness: 0.6),
      ],
    );
  }

  static pw.Widget _receiptMeta(Payment p, Invoice inv) {
    final paidAt = p.paidAt ?? p.createdAt ?? DateTime.now();
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _metaCol('Receipt No.', p.paymentNumber),
        _metaCol('Invoice', inv.invoiceNumber),
        _metaCol('Date', DateFormat('d MMM yyyy').format(paidAt)),
        _metaCol('Method', p.paymentMethod.toUpperCase()),
      ],
    );
  }

  static pw.Widget _metaCol(String label, String value) {
    return pw.Column(
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
    );
  }

  static pw.Widget _studentBlock(Invoice inv) {
    final classLine = [inv.className, inv.sectionName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' - ');
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Received from',
                    style: const pw.TextStyle(fontSize: 8, color: _muted)),
                pw.SizedBox(height: 2),
                pw.Text(inv.studentName ?? '—',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    )),
              ],
            ),
          ),
          if (inv.admissionNumber != null)
            _metaCol('Admission #', inv.admissionNumber!),
          if (classLine.isNotEmpty) pw.SizedBox(width: 18),
          if (classLine.isNotEmpty) _metaCol('Class', classLine),
        ],
      ),
    );
  }

  static pw.Widget _amountBlock(Payment p, Invoice inv) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFECFDF5),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _ok, width: 0.6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Amount received',
                  style: const pw.TextStyle(fontSize: 9, color: _muted)),
              pw.SizedBox(height: 4),
              pw.Text(_amountInWords(p.amount),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: _ink,
                  )),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                '₹ ${NumberFormat('#,##0.00').format(p.amount)}',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: _ok,
                ),
              ),
              if (p.transactionId != null)
                pw.Text('Txn: ${p.transactionId}',
                    style: const pw.TextStyle(fontSize: 8, color: _muted)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _itemsTable(Invoice inv) {
    final items = inv.items ?? const [];
    if (items.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Text(
          'Towards Invoice ${inv.invoiceNumber}',
          style: pw.TextStyle(
            fontSize: 10,
            color: _muted,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    }
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.4),
      columnWidths: const {
        0: pw.FlexColumnWidth(4),
        1: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF1F5F9)),
          children: [
            _cell('Fee Head', isHeader: true),
            _cell('Amount', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        ...items.map((it) => pw.TableRow(children: [
              _cell(it.feeHeadName ?? it.description ?? '—'),
              _cell('₹ ${it.amount.toStringAsFixed(0)}',
                  align: pw.TextAlign.right),
            ])),
      ],
    );
  }

  static pw.Widget _balanceBlock(Invoice inv, Payment p) {
    // paidAmount on invoice may not yet include the current payment if the
    // caller passed the pre-payment invoice. We compute both views.
    final paidBefore = (inv.paidAmount - p.amount).clamp(0, double.infinity);
    final paidNow = inv.paidAmount;
    final balance = (inv.totalAmount - inv.discountAmount - paidNow)
        .clamp(0, double.infinity);
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _border, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          _row('Invoice total', '₹ ${inv.totalAmount.toStringAsFixed(2)}'),
          if (inv.discountAmount > 0)
            _row('Discount', '- ₹ ${inv.discountAmount.toStringAsFixed(2)}'),
          _row('Paid earlier', '₹ ${paidBefore.toStringAsFixed(2)}'),
          _row('Paid this receipt', '₹ ${p.amount.toStringAsFixed(2)}',
              emphasize: true),
          pw.Divider(color: _border, thickness: 0.4, height: 14),
          _row('Outstanding balance',
              '₹ ${balance.toStringAsFixed(2)}', emphasize: true),
        ],
      ),
    );
  }

  static pw.Widget _row(String l, String v, {bool emphasize = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(l,
              style: pw.TextStyle(
                fontSize: 10,
                color: emphasize ? _ink : _muted,
                fontWeight:
                    emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
              )),
          pw.Text(v,
              style: pw.TextStyle(
                fontSize: 10,
                color: _ink,
                fontWeight:
                    emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
              )),
        ],
      ),
    );
  }

  static pw.Widget _footer() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: _border, thickness: 0.4),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Computer-generated receipt. No signature required.',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
            pw.Text(
              'Generated ${DateFormat('d MMM yyyy, h:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _cell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: _ink,
        ),
      ),
    );
  }

  /// Simple Indian-rupee amount-in-words. Handles up to crores.
  /// Used for "Amount received" caption on the receipt.
  static String _amountInWords(double amount) {
    final n = amount.round();
    if (n == 0) return 'Zero rupees only';
    final paise = ((amount - n) * 100).round();
    final rupeesPart = _indianNumberToWords(n);
    final paisePart = paise > 0 ? ' and ${_indianNumberToWords(paise)} paise' : '';
    return '$rupeesPart rupees$paisePart only';
  }

  static String _indianNumberToWords(int n) {
    if (n == 0) return 'zero';
    const ones = [
      '', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight',
      'nine', 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen',
      'sixteen', 'seventeen', 'eighteen', 'nineteen'
    ];
    const tens = [
      '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy',
      'eighty', 'ninety'
    ];
    String twoDigit(int x) {
      if (x < 20) return ones[x];
      final t = x ~/ 10, o = x % 10;
      return o == 0 ? tens[t] : '${tens[t]}-${ones[o]}';
    }
    String threeDigit(int x) {
      final h = x ~/ 100, r = x % 100;
      if (h == 0) return twoDigit(r);
      if (r == 0) return '${ones[h]} hundred';
      return '${ones[h]} hundred ${twoDigit(r)}';
    }
    final parts = <String>[];
    final crore = n ~/ 10000000;
    final lakh = (n % 10000000) ~/ 100000;
    final thousand = (n % 100000) ~/ 1000;
    final rest = n % 1000;
    if (crore > 0) parts.add('${threeDigit(crore)} crore');
    if (lakh > 0) parts.add('${twoDigit(lakh)} lakh');
    if (thousand > 0) parts.add('${twoDigit(thousand)} thousand');
    if (rest > 0) parts.add(threeDigit(rest));
    final joined = parts.join(' ');
    return joined.substring(0, 1).toUpperCase() + joined.substring(1);
  }
}
