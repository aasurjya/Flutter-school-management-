import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../data/models/report_card.dart';
import '../../providers/report_card_provider.dart';
import '../widgets/report_card_pdf_builder.dart';

class ReportCardPreviewScreen extends ConsumerWidget {
  final String reportId;

  const ReportCardPreviewScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(rcByIdProvider(reportId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Preview'),
        actions: [
          reportAsync.whenOrNull(
                data: (report) {
                  if (report == null) return const SizedBox.shrink();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share),
                        tooltip: 'Share PDF',
                        onPressed: () async {
                          final data = report.data.isNotEmpty
                              ? ReportCardData.fromJson(report.data)
                              : null;
                          if (data == null) return;
                          final bytes = await ReportCardPdfBuilder.build(
                            data: data,
                            comments: report.comments,
                            skills: report.skills,
                            activities: report.activities,
                          );
                          await Printing.sharePdf(
                            bytes: bytes,
                            filename:
                                'report_card_${report.studentName ?? "student"}.pdf',
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.print),
                        tooltip: 'Print',
                        onPressed: () async {
                          final data = report.data.isNotEmpty
                              ? ReportCardData.fromJson(report.data)
                              : null;
                          if (data == null) return;
                          final bytes = await ReportCardPdfBuilder.build(
                            data: data,
                            comments: report.comments,
                            skills: report.skills,
                            activities: report.activities,
                          );
                          await Printing.layoutPdf(
                              onLayout: (_) => bytes);
                        },
                      ),
                    ],
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: reportAsync.when(
        data: (report) {
          if (report == null) {
            return const Center(child: Text('Report not found'));
          }

          final data = report.data.isNotEmpty
              ? ReportCardData.fromJson(report.data)
              : null;

          if (data == null) {
            return const Center(
                child: Text('No report data available'));
          }

          return PdfPreview(
            build: (format) => ReportCardPdfBuilder.build(
              data: data,
              comments: report.comments,
              skills: report.skills,
              activities: report.activities,
              headerConfig: null, // Would come from template
            ),
            canChangeOrientation: false,
            canChangePageFormat: false,
            allowPrinting: true,
            allowSharing: true,
            pdfFileName:
                'report_card_${report.studentName ?? "student"}.pdf',
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
