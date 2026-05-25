import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/models/report_card.dart';
import '../../../data/models/report_card_full.dart';
import '../../../data/models/tenant.dart';
import '../presentation/widgets/report_card_pdf_builder.dart';

/// Helpers that fan ReportCardPdfBuilder out across multiple cards and
/// then merge the resulting page streams into a single PDF document.
///
/// Used by:
///   • generate_report_cards_screen — "Download merged PDF"
///   • report_card_list_screen      — "Bulk Download"
class ReportCardBulkPdf {
  ReportCardBulkPdf._();

  /// Build one merged PDF containing every report in [reports].
  ///
  /// Strategy: each card is rendered via the existing ReportCardPdfBuilder,
  /// then its rasterized pages are imported page-by-page into a single
  /// pw.Document. This is the cleanest cross-platform approach because the
  /// pdf package does not expose a public "concatenate documents" API.
  static Future<Uint8List> buildMerged({
    required List<ReportCardFull> reports,
    Tenant? tenant,
    void Function(int current, int total)? onProgress,
  }) async {
    if (reports.isEmpty) {
      // Empty placeholder PDF so callers don't crash.
      final empty = pw.Document();
      empty.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(
            child: pw.Text('No report cards to print.'),
          ),
        ),
      );
      return empty.save();
    }

    final headerConfig = <String, dynamic>{
      if (tenant?.name != null) 'school_name': tenant!.name,
    };

    final merged = pw.Document(
      title: 'Report Cards (${reports.length})',
      author: tenant?.name ?? 'School',
    );

    for (var i = 0; i < reports.length; i++) {
      onProgress?.call(i + 1, reports.length);
      final r = reports[i];
      final data = r.data.isNotEmpty ? ReportCardData.fromJson(r.data) : null;
      if (data == null) continue;

      final bytes = await ReportCardPdfBuilder.build(
        data: data,
        comments: r.comments,
        skills: r.skills,
        activities: r.activities,
        headerConfig: headerConfig,
      );

      // Rasterize each page from the per-student PDF and re-insert into
      // the merged doc. Quality is set to 1.5x for crisper text without
      // bloating the file size.
      await for (final page
          in Printing.raster(bytes, dpi: 150)) {
        final img = pw.MemoryImage(await page.toPng());
        merged.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(
              page.width.toDouble(),
              page.height.toDouble(),
            ),
            build: (_) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(img, fit: pw.BoxFit.contain),
            ),
          ),
        );
      }
    }

    return merged.save();
  }

  /// Build the merged PDF for the OS print/preview dialog.
  static Future<void> previewMerged({
    required List<ReportCardFull> reports,
    Tenant? tenant,
    void Function(int current, int total)? onProgress,
  }) async {
    final bytes = await buildMerged(
      reports: reports,
      tenant: tenant,
      onProgress: onProgress,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  /// Build the merged PDF and open the OS share sheet.
  static Future<void> shareMerged({
    required List<ReportCardFull> reports,
    Tenant? tenant,
    void Function(int current, int total)? onProgress,
    String filename = 'report-cards.pdf',
  }) async {
    final bytes = await buildMerged(
      reports: reports,
      tenant: tenant,
      onProgress: onProgress,
    );
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
