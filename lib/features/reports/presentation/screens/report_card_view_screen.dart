import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/report_card.dart';
import '../../providers/report_card_provider.dart';

class ReportCardViewScreen extends ConsumerWidget {
  final String reportId;

  const ReportCardViewScreen({
    super.key,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportCardByIdProvider(reportId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReport(context),
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadPdf(context),
            tooltip: 'Download PDF',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'print',
                child: ListTile(
                  leading: Icon(Icons.print),
                  title: Text('Print'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'email',
                child: ListTile(
                  leading: Icon(Icons.email),
                  title: Text('Email to Parent'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'print') {
                _printReport(context);
              } else if (value == 'email') {
                _emailReport(context);
              }
            },
          ),
        ],
      ),
      body: reportAsync.when(
        data: (report) {
          if (report == null) {
            return const Center(child: Text('Report not found'));
          }
          return _ReportCardContent(report: report);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _shareReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share report')),
    );
  }

  void _downloadPdf(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading PDF...')),
    );
  }

  void _printReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing for print...')),
    );
  }

  void _emailReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sending email...')),
    );
  }
}

class _ReportCardContent extends StatelessWidget {
  final ReportCard report;

  const _ReportCardContent({required this.report});

  @override
  Widget build(BuildContext context) {
    final data = report.data.isNotEmpty
        ? ReportCardData.fromJson(report.data)
        : null;

    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          margin: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Header
                  _ReportHeader(report: report, data: data),
                  const Divider(height: 32),

                  // Student Info
                  _StudentInfoSection(report: report, data: data),
                  const SizedBox(height: 24),

                  // Academic Performance
                  if (data != null && data.grades.isNotEmpty)
                    _GradesSection(grades: data.grades),
                  const SizedBox(height: 24),

                  // Summary
                  if (data != null) _SummarySection(data: data),
                  const SizedBox(height: 24),

                  // Attendance
                  if (data != null) _AttendanceSection(data: data),
                  const SizedBox(height: 24),

                  // Remarks
                  _RemarksSection(data: data),
                  const SizedBox(height: 32),

                  // Footer
                  _ReportFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  final ReportCard report;
  final ReportCardData? data;

  const _ReportHeader({required this.report, this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // School Logo placeholder
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.school,
            size: 40,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'School Name', // Would come from tenant data
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Academic Report Card',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${data?.academicYear ?? report.academicYearName ?? ''} - ${data?.term ?? report.termName ?? ''}',
          style: theme.textTheme.titleSmall,
        ),
      ],
    );
  }
}

class _StudentInfoSection extends StatelessWidget {
  final ReportCard report;
  final ReportCardData? data;

  const _StudentInfoSection({required this.report, this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              (data?.studentName ?? report.studentName)
                      ?.isNotEmpty ==
                  true
                  ? (data?.studentName ?? report.studentName)![0].toUpperCase()
                  : 'S',
              style: TextStyle(
                fontSize: 24,
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data?.studentName ?? report.studentName ?? 'Unknown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _InfoItem(
                      label: 'Roll No',
                      value: data?.rollNumber ??
                          report.studentRollNumber ??
                          'N/A',
                    ),
                    const SizedBox(width: 24),
                    _InfoItem(
                      label: 'Class',
                      value:
                          '${data?.className ?? report.className ?? ''} ${data?.sectionName ?? report.sectionName ?? ''}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (data?.rank != null && data!.rank > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber),
                  const SizedBox(height: 4),
                  Text(
                    'Rank #${data!.rank}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _GradesSection extends StatelessWidget {
  final List<SubjectGrade> grades;

  const _GradesSection({required this.grades});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Academic Performance',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Table(
          border: TableBorder.all(
            color: theme.dividerColor,
            borderRadius: BorderRadius.circular(8),
          ),
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(2),
            4: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              children: [
                _TableHeader('Subject'),
                _TableHeader('Marks'),
                _TableHeader('Max'),
                _TableHeader('Percentage'),
                _TableHeader('Grade'),
              ],
            ),
            ...grades.map((grade) => TableRow(
                  children: [
                    _TableCell(grade.subjectName),
                    _TableCell(grade.marksObtained?.toStringAsFixed(0) ?? '-'),
                    _TableCell(grade.maxMarks?.toStringAsFixed(0) ?? '-'),
                    _TableCell(
                        '${grade.percentage?.toStringAsFixed(1) ?? '-'}%'),
                    _TableCell(
                      grade.grade ?? '-',
                      isGrade: true,
                      gradeColor: _getGradeColor(grade.grade),
                    ),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  Color _getGradeColor(String? grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Colors.green;
      case 'B+':
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isGrade;
  final Color? gradeColor;

  const _TableCell(this.text, {this.isGrade = false, this.gradeColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: isGrade
          ? Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: gradeColor?.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: gradeColor,
                  ),
                ),
              ),
            )
          : Text(
              text,
              textAlign: TextAlign.center,
            ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final ReportCardData data;

  const _SummarySection({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            label: 'Overall Percentage',
            value: '${data.overallPercentage.toStringAsFixed(1)}%',
            icon: Icons.percent,
            color: Colors.blue,
          ),
          Container(
            width: 1,
            height: 50,
            color: theme.dividerColor,
          ),
          _SummaryItem(
            label: 'Overall Grade',
            value: data.overallGrade,
            icon: Icons.grade,
            color: _getGradeColor(data.overallGrade),
          ),
          Container(
            width: 1,
            height: 50,
            color: theme.dividerColor,
          ),
          _SummaryItem(
            label: 'Class Rank',
            value: data.rank > 0 ? '#${data.rank}' : 'N/A',
            icon: Icons.leaderboard,
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Colors.green;
      case 'B+':
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _AttendanceSection extends StatelessWidget {
  final ReportCardData data;

  const _AttendanceSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Summary',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _AttendanceCard(
                label: 'Days Present',
                value: '${data.daysPresent}',
                total: '/${data.totalDays}',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AttendanceCard(
                label: 'Days Absent',
                value: '${data.totalDays - data.daysPresent}',
                total: '/${data.totalDays}',
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AttendanceCard(
                label: 'Attendance %',
                value: '${data.attendancePercentage.toStringAsFixed(1)}%',
                total: '',
                color: data.attendancePercentage >= 75
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final String label;
  final String value;
  final String total;
  final Color color;

  const _AttendanceCard({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(100)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: total,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RemarksSection extends StatelessWidget {
  final ReportCardData? data;

  const _RemarksSection({this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Remarks',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Class Teacher's Remarks:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data?.classTeacherRemarks ??
                    'A dedicated student with consistent performance.',
                style: theme.textTheme.bodyMedium,
              ),
              const Divider(height: 24),
              Text(
                "Principal's Remarks:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data?.principalRemarks ?? 'Keep up the good work!',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SignatureBlock(label: 'Class Teacher'),
            _SignatureBlock(label: 'Principal'),
            _SignatureBlock(label: 'Parent/Guardian'),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Generated on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SignatureBlock extends StatelessWidget {
  final String label;

  const _SignatureBlock({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 1,
          color: Colors.grey,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
