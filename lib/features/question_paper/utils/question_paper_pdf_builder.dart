import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/models/question_paper.dart';
import '../../../data/models/tenant.dart';

/// Builds and shares a print-ready PDF of a [QuestionPaper].
///
/// Style mirrors `fees_pdf_builder.dart` so the entire app reads as one
/// document: NotoSans (bundled, fallback to PdfGoogleFonts), A4, the same
/// indigo accent and slate body. Header carries the school name and exam
/// metadata; the body lists sections (A, B, C…) with numbered questions
/// and per-question marks on the right; a footer prints "Page N of M".
class QuestionPaperPdfBuilder {
  QuestionPaperPdfBuilder._();

  static const _primary = PdfColor.fromInt(0xFF6366F1);
  static const _textColor = PdfColor.fromInt(0xFF0F172A);
  static const _grey = PdfColor.fromInt(0xFF64748B);
  static const _border = PdfColor.fromInt(0xFFE2E8F0);
  static const _sectionBg = PdfColor.fromInt(0xFFEEF2FF);

  /// Share via OS share sheet (iOS share / Android intent / web download).
  static Future<void> buildAndShare(
    QuestionPaper paper, {
    Tenant? tenant,
  }) async {
    final bytes = await _buildBytes(paper, tenant: tenant);
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final slug = paper.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'question-paper-$slug-$date.pdf',
    );
  }

  /// Open the system print dialog (laid out for the user's chosen paper size).
  static Future<void> buildAndPrint(
    QuestionPaper paper, {
    Tenant? tenant,
  }) async {
    final bytes = await _buildBytes(paper, tenant: tenant);
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

  static Future<Uint8List> _buildBytes(
    QuestionPaper paper, {
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
      title: paper.title,
      author: tenant?.name ?? 'School Management System',
      theme: theme,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 40),
        header: (_) => _buildHeader(paper, tenant),
        footer: (ctx) => _buildFooter(ctx),
        build: (_) {
          final out = <pw.Widget>[];
          out.add(pw.SizedBox(height: 8));
          if (paper.instructions != null && paper.instructions!.trim().isNotEmpty) {
            out.add(_buildInstructions(paper.instructions!));
            out.add(pw.SizedBox(height: 12));
          }
          for (var i = 0; i < paper.sections.length; i++) {
            final section = paper.sections[i];
            if (paper.sections.length > 1) {
              out.add(_sectionDivider(i, section));
              out.add(pw.SizedBox(height: 6));
            }
            out.add(_questionList(section.items));
            out.add(pw.SizedBox(height: 14));
          }
          if (paper.sections.isEmpty) {
            out.add(_emptyState());
          }
          return out;
        },
      ),
    );

    return pdf.save();
  }

  // ===== Header / Footer =====

  static pw.Widget _buildHeader(QuestionPaper paper, Tenant? tenant) {
    final dateStr = DateFormat('d MMM yyyy').format(DateTime.now());
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          (tenant?.name ?? 'School').toUpperCase(),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: _primary,
            letterSpacing: 1.2,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          paper.title,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: _textColor,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _metaText('Class: ${paper.className ?? '—'}'),
            _metaText('Date: $dateStr'),
            _metaText('Duration: ${paper.durationMinutes} min'),
            _metaText('Max Marks: ${paper.totalMarks}'),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: _border, height: 1),
      ],
    );
  }

  static pw.Widget _metaText(String text) {
    return pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 9, color: _grey),
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated ${DateFormat('d MMM yyyy, h:mm a').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: _grey),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _grey),
          ),
        ],
      ),
    );
  }

  // ===== Body pieces =====

  static pw.Widget _buildInstructions(String instructions) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _sectionBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'General Instructions',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            instructions,
            style: const pw.TextStyle(fontSize: 10, color: _textColor),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionDivider(int index, QuestionPaperSection section) {
    final letter = String.fromCharCode(65 + index);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const pw.BoxDecoration(color: _sectionBg),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Section $letter — ${section.title}',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
            ),
          ),
          pw.Text(
            '${section.questionCount} questions · ${section.totalMarks} marks',
            style: const pw.TextStyle(fontSize: 9, color: _grey),
          ),
        ],
      ),
    );
  }

  static pw.Widget _questionList(List<QuestionPaperItem> items) {
    if (items.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 12),
        child: pw.Text(
          'No questions in this section.',
          style: const pw.TextStyle(fontSize: 10, color: _grey),
        ),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items.asMap().entries.map((entry) {
        final idx = entry.key + 1;
        return _questionRow(idx, entry.value);
      }).toList(),
    );
  }

  static pw.Widget _questionRow(int number, QuestionPaperItem item) {
    final marks = item.marks;
    final marksLabel = marks == marks.roundToDouble()
        ? '[${marks.toStringAsFixed(0)}]'
        : '[${marks.toStringAsFixed(1)}]';

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 22,
                child: pw.Text(
                  '$number.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  item.questionText,
                  style: const pw.TextStyle(fontSize: 10, color: _textColor),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                marksLabel,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _primary,
                ),
              ),
            ],
          ),
          if (item.hasOptions && item.options.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 22, top: 3),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: item.options.asMap().entries.map((opt) {
                  final letter = String.fromCharCode(65 + opt.key);
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                    child: pw.Text(
                      '($letter)  ${opt.value}',
                      style:
                          const pw.TextStyle(fontSize: 9.5, color: _textColor),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _emptyState() {
    return pw.Center(
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 60),
        child: pw.Text(
          'This question paper has no sections or questions yet.',
          style: const pw.TextStyle(fontSize: 11, color: _grey),
        ),
      ),
    );
  }
}
