import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/copy/warm_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/report_card.dart';
import '../../../id_card/providers/id_card_provider.dart';
import '../../providers/report_card_provider.dart';
import '../widgets/report_card_pdf_builder.dart';

/// PDF preview screen for a single report card.
///
/// Hosts the printing package's PdfPreview widget so admins can scroll,
/// zoom, print, share, or save the PDF without leaving the app.
class ReportCardPreviewScreen extends ConsumerWidget {
  final String reportId;
  const ReportCardPreviewScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(rcByIdProvider(reportId));
    return Scaffold(
      appBar: AppBar(title: const Text('Report Card Preview')),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text(
            WarmCopy.genericError,
            style: TextStyle(color: AppColors.error),
          ),
        ),
        data: (report) {
          if (report == null) {
            return const Center(child: Text('Report not found.'));
          }
          final data = report.data.isNotEmpty
              ? ReportCardData.fromJson(report.data)
              : null;
          if (data == null) {
            return const Center(
              child: Text('Report data missing — regenerate the card.'),
            );
          }

          return PdfPreview(
            useActions: true,
            canDebug: false,
            build: (_) async {
              final tenant = await ref.read(currentTenantProvider.future);
              return ReportCardPdfBuilder.build(
                data: data,
                comments: report.comments,
                skills: report.skills,
                activities: report.activities,
                headerConfig: {
                  if (tenant?.name != null) 'school_name': tenant!.name,
                },
              );
            },
          );
        },
      ),
    );
  }
}
