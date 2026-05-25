import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/models/admission.dart';
import '../../../data/models/tenant.dart';

/// Short A5-style inquiry receipt the front-office can hand to walk-ins.
///
/// Confirms that the inquiry has been recorded — inquiry #, date, parent name,
/// child name, contact, and a "we will contact you within 2 business days"
/// reassurance line. Mirrors the visual conventions of
/// `payment_receipt_pdf_builder.dart` (NotoSans, tenant header, computer-
/// generated footer) but stays single-page and compact.
class InquiryReceiptPdfBuilder {
  InquiryReceiptPdfBuilder._();

  static const _primary = PdfColor.fromInt(0xFF6366F1);
  static const _ink = PdfColor.fromInt(0xFF0F172A);
  static const _muted = PdfColor.fromInt(0xFF64748B);
  static const _border = PdfColor.fromInt(0xFFE2E8F0);

  /// Builds bytes and opens the OS share sheet.
  static Future<void> buildAndShare({
    required AdmissionInquiry inquiry,
    Tenant? tenant,
  }) async {
    final bytes = await buildBytes(inquiry: inquiry, tenant: tenant);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'inquiry-receipt-${_referenceNumber(inquiry)}.pdf',
    );
  }

  /// Sends straight to the OS print dialog.
  static Future<void> buildAndPrint({
    required AdmissionInquiry inquiry,
    Tenant? tenant,
  }) async {
    final bytes = await buildBytes(inquiry: inquiry, tenant: tenant);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  /// Raw PDF bytes — exposed for testing and upload-then-share flows.
  static Future<Uint8List> buildBytes({
    required AdmissionInquiry inquiry,
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
      title: 'Inquiry Receipt — ${inquiry.studentName}',
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
            pw.SizedBox(height: 14),
            _refStrip(inquiry),
            pw.SizedBox(height: 16),
            _detailsCard(inquiry),
            pw.SizedBox(height: 16),
            _reassurance(),
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

  // -- sections --------------------------------------------------------------

  static pw.Widget _header(Tenant? t) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
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
                          style: const pw.TextStyle(
                              fontSize: 9, color: _muted)),
                    if (t?.phone != null && t?.email != null)
                      pw.Text('   ·   ',
                          style: const pw.TextStyle(
                              fontSize: 9, color: _muted)),
                    if (t?.email != null)
                      pw.Text(t!.email!,
                          style: const pw.TextStyle(
                              fontSize: 9, color: _muted)),
                  ]),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: _primary,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'INQUIRY RECEIPT',
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

  static pw.Widget _refStrip(AdmissionInquiry inq) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _metaCol('Inquiry No.', _referenceNumber(inq)),
        _metaCol('Date', DateFormat('d MMM yyyy').format(inq.createdAt)),
        _metaCol('Source', inq.source.label),
      ],
    );
  }

  static pw.Widget _detailsCard(AdmissionInquiry inq) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Received from',
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            inq.parentName,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 10),
          _row('Child', inq.studentName),
          if (inq.className != null && inq.className!.isNotEmpty)
            _row('Applying for', inq.className!),
          _row('Contact', inq.phone),
          if (inq.email != null && inq.email!.isNotEmpty)
            _row('Email', inq.email!),
        ],
      ),
    );
  }

  static pw.Widget _reassurance() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFEEF2FF),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _primary, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Thank you for your interest.',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Your inquiry has been recorded. Our admissions team will contact you within 2 business days to guide you through the next steps — campus visit, application form, and document submission. Please retain this slip for reference.',
            style: const pw.TextStyle(
              fontSize: 10,
              color: _ink,
              lineSpacing: 1.5,
            ),
            textAlign: pw.TextAlign.justify,
          ),
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
              'Computer-generated acknowledgement. No signature required.',
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

  // -- bits ------------------------------------------------------------------

  static pw.Widget _row(String l, String v) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(l,
                style: const pw.TextStyle(fontSize: 10, color: _muted)),
          ),
          pw.Expanded(
            child: pw.Text(v,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                )),
          ),
        ],
      ),
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

  static String _referenceNumber(AdmissionInquiry inq) {
    final shortId = inq.id.length > 8 ? inq.id.substring(0, 8) : inq.id;
    return 'INQ-${shortId.toUpperCase()}';
  }
}
