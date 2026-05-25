import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/models/student.dart';
import '../../../data/models/tenant.dart';
import '../../qr_scan/utils/qr_data_utils.dart';

/// Builds an A4 PDF with a grid of student ID cards for bulk printing.
///
/// Default layout: 2 columns × 5 rows per A4 page = 10 cards / page.
/// Each card preserves the existing student-ID-card aesthetic
/// (school header, photo/initials, name, admission #, class, blood
/// group, QR code) — mirroring the on-screen IdCardWidget visual.
///
/// Follows the precedent of `payment_receipt_pdf_builder.dart` —
/// static-only API with `buildBytes` / `buildAndShare` / `buildAndPrint`.
class BulkStudentIdCardPdfBuilder {
  BulkStudentIdCardPdfBuilder._();

  static const _primary = PdfColor.fromInt(0xFF6366F1);
  static const _primaryDark = PdfColor.fromInt(0xFF4F46E5);
  static const _ink = PdfColor.fromInt(0xFF0F172A);
  static const _muted = PdfColor.fromInt(0xFF64748B);
  static const _border = PdfColor.fromInt(0xFFE2E8F0);
  static const _bg = PdfColor.fromInt(0xFFF8FAFC);

  // A4 = 210 × 297 mm.
  // 2-column × 5-row grid with 14mm page margins and 6mm gutters
  // gives cards ~88mm × 50mm — close to ISO/IEC 7810 ID-1 (85.6 × 54mm).
  static const _columns = 2;
  static const _rows = 5;
  static const _pageMargin = 14.0 * PdfPageFormat.mm;
  static const _gutter = 6.0 * PdfPageFormat.mm;

  /// Produces raw PDF bytes. Use when you want to upload or cache.
  static Future<Uint8List> buildBytes({
    required List<Student> students,
    required Tenant? tenant,
    String academicYear = 'AY 2025-26',
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

    // Pre-fetch tenant logo + student photos in parallel — embedding
    // remote images synchronously inside the PDF builder is not safe.
    final logoImage = await _safeFetchImage(tenant?.logoUrl);
    final photoImages = <String, pw.MemoryImage?>{};
    await Future.wait(
      students.map((s) async {
        photoImages[s.id] = await _safeFetchImage(s.photoUrl);
      }),
    );

    final pdf = pw.Document(
      title: 'Student ID Cards — ${tenant?.name ?? 'School'}',
      author: tenant?.name ?? 'School',
      theme: theme,
    );

    const perPage = _columns * _rows;
    final pageCount =
        (students.length / perPage).ceil().clamp(1, 1 << 30).toInt();

    for (var p = 0; p < pageCount; p++) {
      final pageStudents = students
          .skip(p * perPage)
          .take(perPage)
          .toList(growable: false);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(_pageMargin),
          build: (_) => _buildGrid(
            pageStudents: pageStudents,
            tenant: tenant,
            logoImage: logoImage,
            photoImages: photoImages,
            academicYear: academicYear,
          ),
        ),
      );
    }

    return pdf.save();
  }

  /// Shows the OS share sheet with the generated PDF.
  static Future<void> buildAndShare({
    required List<Student> students,
    required Tenant? tenant,
    String academicYear = 'AY 2025-26',
  }) async {
    final bytes = await buildBytes(
      students: students,
      tenant: tenant,
      academicYear: academicYear,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'student-id-cards-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Pushes the PDF straight to the OS print dialog.
  static Future<void> buildAndPrint({
    required List<Student> students,
    required Tenant? tenant,
    String academicYear = 'AY 2025-26',
  }) async {
    final bytes = await buildBytes(
      students: students,
      tenant: tenant,
      academicYear: academicYear,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Student ID Cards',
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Internal layout
  // ────────────────────────────────────────────────────────────────────

  static pw.Widget _buildGrid({
    required List<Student> pageStudents,
    required Tenant? tenant,
    required pw.MemoryImage? logoImage,
    required Map<String, pw.MemoryImage?> photoImages,
    required String academicYear,
  }) {
    // Build the matrix row-by-row, padding the trailing row with empty
    // placeholders so column widths stay aligned.
    final rows = <pw.Widget>[];
    for (var r = 0; r < _rows; r++) {
      final rowChildren = <pw.Widget>[];
      for (var c = 0; c < _columns; c++) {
        final idx = r * _columns + c;
        final student =
            idx < pageStudents.length ? pageStudents[idx] : null;
        rowChildren.add(
          pw.Expanded(
            child: student == null
                ? pw.SizedBox.shrink()
                : _idCard(
                    student: student,
                    tenant: tenant,
                    logoImage: logoImage,
                    photoImage: photoImages[student.id],
                    academicYear: academicYear,
                  ),
          ),
        );
        if (c < _columns - 1) {
          rowChildren.add(pw.SizedBox(width: _gutter));
        }
      }
      rows.add(pw.Expanded(child: pw.Row(children: rowChildren)));
      if (r < _rows - 1) {
        rows.add(pw.SizedBox(height: _gutter));
      }
    }

    return pw.Column(children: rows);
  }

  static pw.Widget _idCard({
    required Student student,
    required Tenant? tenant,
    required pw.MemoryImage? logoImage,
    required pw.MemoryImage? photoImage,
    required String academicYear,
  }) {
    final qrData = QrDataUtils.encode(
      tenantId: student.tenantId,
      admissionNumber: student.admissionNumber,
    );
    final className = student.currentEnrollment?.className;
    final sectionName = student.currentEnrollment?.sectionName;
    final classLine = [className, sectionName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' - ');

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _cardHeader(tenant: tenant, logoImage: logoImage),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _photoBox(student: student, photoImage: photoImage),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: _studentDetails(
                      student: student,
                      classLine: classLine,
                      academicYear: academicYear,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  _qrBox(qrData),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cardHeader({
    required Tenant? tenant,
    required pw.MemoryImage? logoImage,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: const pw.BoxDecoration(
        gradient: pw.LinearGradient(
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
          colors: [_primary, _primaryDark],
        ),
        borderRadius: pw.BorderRadius.only(
          topLeft: pw.Radius.circular(8),
          topRight: pw.Radius.circular(8),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 18,
            height: 18,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            alignment: pw.Alignment.center,
            child: logoImage != null
                ? pw.ClipRRect(
                    horizontalRadius: 3,
                    verticalRadius: 3,
                    child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                  )
                : pw.Text(
                    _initials(tenant?.name ?? 'School'),
                    style: pw.TextStyle(
                      color: _primary,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  (tenant?.name ?? 'School').toUpperCase(),
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                pw.Text(
                  'STUDENT IDENTITY CARD',
                  style: const pw.TextStyle(
                    color: PdfColor.fromInt(0xCCFFFFFF),
                    fontSize: 5.5,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _photoBox({
    required Student student,
    required pw.MemoryImage? photoImage,
  }) {
    return pw.Container(
      width: 44,
      height: 54,
      decoration: pw.BoxDecoration(
        color: _bg,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      alignment: pw.Alignment.center,
      child: photoImage != null
          ? pw.ClipRRect(
              horizontalRadius: 3,
              verticalRadius: 3,
              child: pw.Image(photoImage, fit: pw.BoxFit.cover),
            )
          : pw.Text(
              student.initials,
              style: pw.TextStyle(
                color: _primary,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
    );
  }

  static pw.Widget _studentDetails({
    required Student student,
    required String classLine,
    required String academicYear,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          student.fullName,
          maxLines: 2,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        pw.SizedBox(height: 2),
        _kvRow('ADM', student.admissionNumber),
        if (classLine.isNotEmpty) _kvRow('CLASS', classLine),
        if (student.currentEnrollment?.rollNumber != null &&
            student.currentEnrollment!.rollNumber!.isNotEmpty)
          _kvRow('ROLL', student.currentEnrollment!.rollNumber!),
        if (student.bloodGroup != null && student.bloodGroup!.isNotEmpty)
          _kvRow('BLOOD', student.bloodGroup!),
        pw.SizedBox(height: 1),
        pw.Text(
          academicYear,
          style: const pw.TextStyle(fontSize: 6, color: _muted),
        ),
      ],
    );
  }

  static pw.Widget _kvRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 1),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 26,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 6,
                color: _muted,
                letterSpacing: 0.4,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                fontSize: 7,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _qrBox(String qrData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(2),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(3),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.BarcodeWidget(
        data: qrData,
        barcode: pw.Barcode.qrCode(),
        width: 44,
        height: 44,
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────────

  static String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) {
      return parts.first.isNotEmpty
          ? parts.first[0].toUpperCase()
          : 'S';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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

  /// Fetches a remote image into a `pw.MemoryImage`. Returns null on
  /// any failure — bulk PDF generation should never crash because one
  /// avatar is missing.
  static Future<pw.MemoryImage?> _safeFetchImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (_) {
      // Swallow — fallback to initials rendering.
    }
    return null;
  }
}
