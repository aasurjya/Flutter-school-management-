import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/models/admission.dart';
import '../../../data/models/tenant.dart';

/// Formal enrollment / admission confirmation letter PDF.
///
/// Stylistically mirrors [PaymentReceiptPdfBuilder]: NotoSans font loaded from
/// bundled assets (falling back to PdfGoogleFonts), A4 page size, tenant
/// letterhead at the top, and a "computer-generated" footer. The body is a
/// formal acceptance letter — letterhead, date, reference number, salutation,
/// acceptance paragraph with student name + class + start date + fee summary,
/// documents block, parent instructions, and a signatory line.
class EnrollmentLetterPdfBuilder {
  EnrollmentLetterPdfBuilder._();

  static const _primary = PdfColor.fromInt(0xFF6366F1);
  static const _ink = PdfColor.fromInt(0xFF0F172A);
  static const _muted = PdfColor.fromInt(0xFF64748B);
  static const _border = PdfColor.fromInt(0xFFE2E8F0);
  static const _accent = PdfColor.fromInt(0xFF16A34A);

  /// Builds the letter PDF and offers the OS share sheet.
  static Future<void> buildAndShare({
    required AdmissionApplication app,
    Tenant? tenant,
    AdmissionSettings? settings,
    DateTime? reportingDate,
  }) async {
    final bytes = await buildBytes(
      app: app,
      tenant: tenant,
      settings: settings,
      reportingDate: reportingDate,
    );
    final ref = _referenceNumber(app);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'enrollment-letter-$ref.pdf',
    );
  }

  /// Sends directly to the OS print dialog.
  static Future<void> buildAndPrint({
    required AdmissionApplication app,
    Tenant? tenant,
    AdmissionSettings? settings,
    DateTime? reportingDate,
  }) async {
    final bytes = await buildBytes(
      app: app,
      tenant: tenant,
      settings: settings,
      reportingDate: reportingDate,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  /// Raw bytes — exposed for testing and upload-then-share flows.
  static Future<Uint8List> buildBytes({
    required AdmissionApplication app,
    Tenant? tenant,
    AdmissionSettings? settings,
    DateTime? reportingDate,
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
      title: 'Enrollment Letter — ${app.studentName}',
      author: tenant?.name ?? 'School',
      theme: theme,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
        header: (_) => _header(tenant),
        footer: (_) => _footer(),
        build: (_) => [
          pw.SizedBox(height: 18),
          _refAndDate(app),
          pw.SizedBox(height: 18),
          _subject(app),
          pw.SizedBox(height: 14),
          _salutation(app),
          pw.SizedBox(height: 10),
          _bodyParagraph(app, settings, tenant, reportingDate),
          pw.SizedBox(height: 16),
          _feeSummary(app, settings),
          pw.SizedBox(height: 16),
          _documentsBlock(app, settings),
          pw.SizedBox(height: 16),
          _instructionsBlock(reportingDate),
          pw.SizedBox(height: 28),
          _signatureBlock(tenant),
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
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  if (t?.fullAddress.isNotEmpty == true)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(
                        t!.fullAddress,
                        style: const pw.TextStyle(fontSize: 9, color: _muted),
                      ),
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
                  horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: _primary,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'ENROLLMENT LETTER',
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

  static pw.Widget _refAndDate(AdmissionApplication app) {
    final date = DateFormat('d MMMM yyyy').format(DateTime.now());
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _metaCol('Ref. No.', _referenceNumber(app)),
        _metaCol('Date', date),
      ],
    );
  }

  static pw.Widget _subject(AdmissionApplication app) {
    final yearLabel = app.academicYearName ?? _yearLabelFromDate(DateTime.now());
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Subject: Confirmation of Admission — Academic Year $yearLabel',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Container(
          width: 360,
          height: 0.6,
          color: _border,
        ),
      ],
    );
  }

  static pw.Widget _salutation(AdmissionApplication app) {
    final parent = _primaryParent(app);
    return pw.Text(
      parent != null && parent.isNotEmpty
          ? 'Dear $parent,'
          : 'Dear Parent / Guardian,',
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
      ),
    );
  }

  static pw.Widget _bodyParagraph(
    AdmissionApplication app,
    AdmissionSettings? settings,
    Tenant? tenant,
    DateTime? reportingDate,
  ) {
    final school = tenant?.name ?? 'our school';
    final className = app.className ?? 'the applied class';
    final yearLabel =
        app.academicYearName ?? _yearLabelFromDate(DateTime.now());
    final start = reportingDate ?? settings?.openDate;
    final startStr = start != null
        ? DateFormat('d MMMM yyyy').format(start)
        : 'the date communicated separately';

    final body =
        'We are delighted to inform you that ${app.studentName} has been '
        'formally accepted for admission to $className at $school for the '
        'academic year $yearLabel. The session is scheduled to commence on '
        '$startStr. This letter serves as official confirmation of admission '
        'against application reference ${_referenceNumber(app)}.';

    return pw.Text(
      body,
      style: const pw.TextStyle(
        fontSize: 10.5,
        color: _ink,
        lineSpacing: 2.0,
      ),
      textAlign: pw.TextAlign.justify,
    );
  }

  static pw.Widget _feeSummary(
    AdmissionApplication app,
    AdmissionSettings? settings,
  ) {
    final fee = settings?.applicationFee;
    final line = fee != null && fee > 0
        ? 'Annual fee: ₹ ${NumberFormat('#,##0').format(fee)} · payable as per the fee schedule shared separately by the accounts office.'
        : 'Annual fee: payable as per the fee schedule shared separately by the accounts office.';

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFECFDF5),
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _accent, width: 0.6),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 18,
            color: _accent,
            margin: const pw.EdgeInsets.only(right: 10, top: 1),
          ),
          pw.Expanded(
            child: pw.Text(
              line,
              style: pw.TextStyle(
                fontSize: 10,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _documentsBlock(
    AdmissionApplication app,
    AdmissionSettings? settings,
  ) {
    final required = (settings?.documentsRequired.isNotEmpty == true)
        ? settings!.documentsRequired
            .map(_humaniseDocKey)
            .toList()
        : <String>[
            'Birth Certificate',
            'Transfer Certificate (if applicable)',
            'Latest Report Card',
            'Address Proof',
            'Passport-size Photographs',
          ];

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8FAFC),
        border: pw.Border.all(color: _border, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Documents required at the time of reporting',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 6),
          ...required.map((d) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('•  ',
                        style: const pw.TextStyle(fontSize: 10, color: _ink)),
                    pw.Expanded(
                      child: pw.Text(
                        d,
                        style:
                            const pw.TextStyle(fontSize: 10, color: _ink),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static pw.Widget _instructionsBlock(DateTime? reportingDate) {
    final reportLine = reportingDate != null
        ? 'Please report to the school office on ${DateFormat('EEEE, d MMMM yyyy').format(reportingDate)} between 9:00 AM and 11:00 AM for document verification and uniform issue.'
        : 'Please report to the school office on the reporting date communicated by the admissions team for document verification and uniform issue.';

    final lines = <String>[
      reportLine,
      'Carry one set of original documents along with two sets of photocopies.',
      'Uniform, textbooks, and stationery can be purchased from the school store or the recommended vendors.',
      'For any clarification, please contact the admissions office at the numbers printed on the letterhead.',
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _border, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Instructions for parent / guardian',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 6),
          ...lines.map((l) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('•  ',
                        style: const pw.TextStyle(fontSize: 10, color: _ink)),
                    pw.Expanded(
                      child: pw.Text(
                        l,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: _ink,
                          lineSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static pw.Widget _signatureBlock(Tenant? t) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Warm regards,',
              style: pw.TextStyle(
                fontSize: 10,
                color: _ink,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
            pw.SizedBox(height: 28),
            pw.Container(
              width: 180,
              height: 0.6,
              color: _ink,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Principal / Authorised Signatory',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
            if (t?.name != null)
              pw.Text(
                t!.name,
                style: const pw.TextStyle(fontSize: 9, color: _muted),
              ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border, width: 0.6),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('School seal',
                  style:
                      const pw.TextStyle(fontSize: 8, color: _muted)),
              pw.SizedBox(height: 24),
              pw.Container(width: 100),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _footer() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: _border, thickness: 0.4),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Computer-generated. Original copy on letterhead may be requested from the office.',
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

  // -- helpers ---------------------------------------------------------------

  static String _referenceNumber(AdmissionApplication app) {
    if (app.applicationNumber != null && app.applicationNumber!.isNotEmpty) {
      return app.applicationNumber!;
    }
    final shortId = app.id.length > 8 ? app.id.substring(0, 8) : app.id;
    return 'ADM-${shortId.toUpperCase()}';
  }

  static String? _primaryParent(AdmissionApplication app) {
    final p = app.parentInfo;
    return p.guardianName ?? p.fatherName ?? p.motherName;
  }

  /// Returns "2025-26"-style label from a date.
  static String _yearLabelFromDate(DateTime d) {
    // Indian academic year typically Apr → Mar. Before April → previous year.
    final startYear = d.month >= 4 ? d.year : d.year - 1;
    final endShort = (startYear + 1) % 100;
    return '$startYear-${endShort.toString().padLeft(2, '0')}';
  }

  static String _humaniseDocKey(String key) {
    final lower = key.replaceAll('_', ' ').toLowerCase().trim();
    if (lower.isEmpty) return key;
    return lower
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
