import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../data/models/report_card.dart';
import '../../../../data/models/report_card_full.dart';

/// Professional multi-page PDF report card builder.
/// Produces output comparable to PowerSchool / ManageBac.
class ReportCardPdfBuilder {
  ReportCardPdfBuilder._();

  // Color definitions for PDF
  static const _primaryColor = PdfColor.fromInt(0xFF6366F1);
  static const _primaryLight = PdfColor.fromInt(0xFFEEF2FF);
  static const _successColor = PdfColor.fromInt(0xFF22C55E);
  static const _errorColor = PdfColor.fromInt(0xFFEF4444);
  static const _warningColor = PdfColor.fromInt(0xFFF59E0B);
  static const _infoColor = PdfColor.fromInt(0xFF3B82F6);
  static const _textColor = PdfColor.fromInt(0xFF0F172A);
  static const _textSecondary = PdfColor.fromInt(0xFF64748B);
  static const _borderColor = PdfColor.fromInt(0xFFE2E8F0);
  static const _bgLight = PdfColor.fromInt(0xFFF8FAFC);

  /// Main build entry point. Returns PDF bytes.
  static Future<Uint8List> build({
    required ReportCardData data,
    List<ReportCardComment> comments = const [],
    List<ReportCardSkill> skills = const [],
    List<ReportCardActivity> activities = const [],
    Map<String, dynamic>? headerConfig,
  }) async {
    final pdf = pw.Document(
      title: 'Report Card - ${data.studentName}',
      author: headerConfig?['school_name'] as String? ?? 'School Management System',
      subject: 'Academic Report Card - ${data.term} ${data.academicYear}',
    );

    final schoolName =
        headerConfig?['school_name'] as String? ?? 'School Management System';
    final address = headerConfig?['address'] as String? ?? '';
    final motto = headerConfig?['motto'] as String? ?? '';
    final affiliationNo = headerConfig?['affiliation_no'] as String? ?? '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPageHeader(
          schoolName: schoolName,
          address: address,
          motto: motto,
          affiliationNo: affiliationNo,
          academicYear: data.academicYear,
          term: data.term,
          pageNumber: context.pageNumber,
          totalPages: context.pagesCount,
        ),
        footer: (context) => _buildPageFooter(
          context: context,
          schoolName: schoolName,
        ),
        build: (context) => [
          // Student Information
          _buildStudentInfoSection(data),
          pw.SizedBox(height: 16),

          // Academic Performance Table
          if (data.grades.isNotEmpty) ...[
            _buildSectionTitle('ACADEMIC PERFORMANCE'),
            pw.SizedBox(height: 8),
            _buildGradesTable(data.grades),
            pw.SizedBox(height: 8),
            _buildOverallSummary(data),
            pw.SizedBox(height: 16),
          ],

          // Attendance Summary
          _buildSectionTitle('ATTENDANCE SUMMARY'),
          pw.SizedBox(height: 8),
          _buildAttendanceSection(data),
          pw.SizedBox(height: 16),

          // Co-Scholastic Skills
          if (skills.isNotEmpty) ...[
            _buildSectionTitle('CO-SCHOLASTIC AREAS'),
            pw.SizedBox(height: 8),
            _buildSkillsTable(skills),
            pw.SizedBox(height: 16),
          ],

          // Activities & Achievements
          if (activities.isNotEmpty) ...[
            _buildSectionTitle('ACTIVITIES & ACHIEVEMENTS'),
            pw.SizedBox(height: 8),
            _buildActivitiesTable(activities),
            pw.SizedBox(height: 16),
          ],

          // Comments / Remarks
          if (comments.isNotEmpty || data.classTeacherRemarks != null || data.principalRemarks != null) ...[
            _buildSectionTitle('REMARKS'),
            pw.SizedBox(height: 8),
            _buildRemarksSection(data, comments),
            pw.SizedBox(height: 16),
          ],

          // Grading Scale Legend
          _buildGradingScaleLegend(),
          pw.SizedBox(height: 24),

          // Signatures
          _buildSignatureSection(),
        ],
      ),
    );

    return pdf.save();
  }

  // =========================================================================
  // PAGE HEADER
  // =========================================================================
  static pw.Widget _buildPageHeader({
    required String schoolName,
    required String address,
    required String motto,
    required String affiliationNo,
    required String academicYear,
    required String term,
    required int pageNumber,
    required int totalPages,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // School Logo Placeholder
          pw.Container(
            width: 56,
            height: 56,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: _primaryLight,
              border: pw.Border.all(color: _primaryColor, width: 2),
            ),
            child: pw.Center(
              child: pw.Text(
                schoolName.isNotEmpty ? schoolName[0].toUpperCase() : 'S',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  schoolName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                    letterSpacing: 1.5,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                if (address.isNotEmpty)
                  pw.Text(
                    address,
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: _textSecondary,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                if (motto.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      '"$motto"',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontStyle: pw.FontStyle.italic,
                        color: _textSecondary,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                if (affiliationNo.isNotEmpty)
                  pw.Text(
                    'Affiliation No.: $affiliationNo',
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: _textSecondary,
                    ),
                  ),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: _primaryLight,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'REPORT CARD  |  $term - $academicYear',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 56), // Balance the logo width
        ],
      ),
    );
  }

  // =========================================================================
  // PAGE FOOTER
  // =========================================================================
  static pw.Widget _buildPageFooter({
    required pw.Context context,
    required String schoolName,
  }) {
    final now = DateTime.now();
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _borderColor, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated on ${now.day}/${now.month}/${now.year}',
            style: const pw.TextStyle(fontSize: 7, color: _textSecondary),
          ),
          pw.Text(
            'This is a computer-generated report card.',
            style: pw.TextStyle(
              fontSize: 7,
              fontStyle: pw.FontStyle.italic,
              color: _textSecondary,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STUDENT INFORMATION
  // =========================================================================
  static pw.Widget _buildStudentInfoSection(ReportCardData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _bgLight,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _borderColor),
      ),
      child: pw.Row(
        children: [
          // Student Avatar
          pw.Container(
            width: 48,
            height: 48,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: _primaryColor,
            ),
            child: pw.Center(
              child: pw.Text(
                data.studentName.isNotEmpty
                    ? data.studentName[0].toUpperCase()
                    : 'S',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  data.studentName,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    _infoField('Roll No.', data.rollNumber),
                    pw.SizedBox(width: 24),
                    _infoField('Class', data.className),
                    pw.SizedBox(width: 24),
                    _infoField('Section', data.sectionName),
                  ],
                ),
              ],
            ),
          ),
          // Rank Badge
          if (data.rank > 0)
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFFEF3C7),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(
                  color: const PdfColor.fromInt(0xFFF59E0B),
                  width: 0.5,
                ),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'RANK',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFFD97706),
                    ),
                  ),
                  pw.Text(
                    '#${data.rank}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFFD97706),
                    ),
                  ),
                  pw.Text(
                    'of ${data.totalStudents}',
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _infoField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 7, color: _textSecondary)),
        pw.Text(value,
            style:
                pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  // =========================================================================
  // SECTION TITLE
  // =========================================================================
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _primaryColor,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // =========================================================================
  // GRADES TABLE
  // =========================================================================
  static pw.Widget _buildGradesTable(List<SubjectGrade> grades) {
    return pw.TableHelper.fromTextArray(
      context: null,
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      cellAlignment: pw.Alignment.center,
      headerDecoration: pw.BoxDecoration(
        color: _primaryLight,
      ),
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: _primaryColor,
      ),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      headers: ['#', 'Subject', 'Marks Obtained', 'Maximum Marks', 'Percentage', 'Grade', 'Remarks'],
      data: [
        ...grades.asMap().entries.map((entry) {
          final i = entry.key;
          final g = entry.value;
          return [
            '${i + 1}',
            g.subjectName,
            g.marksObtained?.toStringAsFixed(0) ?? '-',
            g.maxMarks?.toStringAsFixed(0) ?? '-',
            '${(g.percentage ?? 0).toStringAsFixed(1)}%',
            g.grade ?? '-',
            g.remarks ?? '',
          ];
        }),
      ],
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1),
        6: const pw.FlexColumnWidth(1.5),
      },
      oddRowDecoration: const pw.BoxDecoration(color: _bgLight),
    );
  }

  // =========================================================================
  // OVERALL SUMMARY
  // =========================================================================
  static pw.Widget _buildOverallSummary(ReportCardData data) {
    double totalObtained = 0;
    double totalMax = 0;
    for (final g in data.grades) {
      totalObtained += g.marksObtained ?? 0;
      totalMax += g.maxMarks ?? 0;
    }

    final isPassed = data.overallPercentage >= 33;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _primaryColor, width: 1),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Total Marks',
              '${totalObtained.toStringAsFixed(0)} / ${totalMax.toStringAsFixed(0)}'),
          _divider(),
          _summaryItem('Overall Percentage',
              '${data.overallPercentage.toStringAsFixed(1)}%'),
          _divider(),
          _summaryItem('Grade', data.overallGrade),
          _divider(),
          _summaryItem('Class Rank',
              data.rank > 0 ? '#${data.rank} / ${data.totalStudents}' : 'N/A'),
          _divider(),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: isPassed
                  ? const PdfColor.fromInt(0xFFDCFCE7)
                  : const PdfColor.fromInt(0xFFFEE2E2),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              isPassed ? 'PASSED' : 'FAILED',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: isPassed ? _successColor : _errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 7, color: _textSecondary)),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style:
                pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _divider() {
    return pw.Container(width: 0.5, height: 30, color: _borderColor);
  }

  // =========================================================================
  // ATTENDANCE
  // =========================================================================
  static pw.Widget _buildAttendanceSection(ReportCardData data) {
    final absent = data.totalDays - data.daysPresent;
    final isGood = data.attendancePercentage >= 75;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _attendanceItem('Total Working Days', '${data.totalDays}',
              _textColor),
          _attendanceItem(
              'Days Present', '${data.daysPresent}', _successColor),
          _attendanceItem('Days Absent', '$absent', _errorColor),
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: isGood
                  ? const PdfColor.fromInt(0xFFDCFCE7)
                  : const PdfColor.fromInt(0xFFFEF3C7),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  '${data.attendancePercentage.toStringAsFixed(1)}%',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: isGood ? _successColor : _warningColor,
                  ),
                ),
                pw.Text(
                  'Attendance',
                  style: const pw.TextStyle(
                      fontSize: 7, color: _textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _attendanceItem(
      String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 7, color: _textSecondary)),
      ],
    );
  }

  // =========================================================================
  // SKILLS TABLE
  // =========================================================================
  static pw.Widget _buildSkillsTable(List<ReportCardSkill> skills) {
    return pw.TableHelper.fromTextArray(
      context: null,
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      cellAlignment: pw.Alignment.center,
      headerDecoration: pw.BoxDecoration(color: _primaryLight),
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: _primaryColor,
      ),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      headers: ['Skill Area', 'Rating (1-5)', 'Grade', 'Comments'],
      data: skills.map((s) {
        return [
          s.skillCategoryDisplay,
          _starString(s.rating),
          _ratingGrade(s.rating),
          s.comments ?? '',
        ];
      }).toList(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(3),
      },
      oddRowDecoration: const pw.BoxDecoration(color: _bgLight),
    );
  }

  static String _starString(int rating) {
    return List.generate(5, (i) => i < rating ? '\u2605' : '\u2606').join(' ');
  }

  static String _ratingGrade(int rating) {
    switch (rating) {
      case 5:
        return 'A';
      case 4:
        return 'B';
      case 3:
        return 'C';
      case 2:
        return 'D';
      case 1:
        return 'E';
      default:
        return '-';
    }
  }

  // =========================================================================
  // ACTIVITIES TABLE
  // =========================================================================
  static pw.Widget _buildActivitiesTable(
      List<ReportCardActivity> activities) {
    return pw.TableHelper.fromTextArray(
      context: null,
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      cellAlignment: pw.Alignment.center,
      headerDecoration: pw.BoxDecoration(color: _primaryLight),
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: _primaryColor,
      ),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      headers: ['#', 'Type', 'Activity', 'Achievement', 'Grade'],
      data: activities.asMap().entries.map((entry) {
        final i = entry.key;
        final a = entry.value;
        return [
          '${i + 1}',
          a.activityTypeDisplay,
          a.activityName,
          a.achievement ?? '-',
          a.grade ?? '-',
        ];
      }).toList(),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2.5),
        3: const pw.FlexColumnWidth(2.5),
        4: const pw.FlexColumnWidth(1),
      },
      oddRowDecoration: const pw.BoxDecoration(color: _bgLight),
    );
  }

  // =========================================================================
  // REMARKS
  // =========================================================================
  static pw.Widget _buildRemarksSection(
      ReportCardData data, List<ReportCardComment> comments) {
    // Merge comments from data and from the comments list
    final allComments = <String, String>{};

    // From ReportCardData
    if (data.classTeacherRemarks != null &&
        data.classTeacherRemarks!.isNotEmpty) {
      allComments['Class Teacher'] = data.classTeacherRemarks!;
    }
    if (data.principalRemarks != null &&
        data.principalRemarks!.isNotEmpty) {
      allComments['Principal'] = data.principalRemarks!;
    }

    // From ReportCardComment list (override if both exist)
    for (final c in comments) {
      allComments[c.commentTypeDisplay] = c.commentText;
    }

    if (allComments.isEmpty) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: allComments.entries.map((entry) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "${entry.key}'s Remarks:",
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  entry.value,
                  style: const pw.TextStyle(fontSize: 9, color: _textColor),
                ),
                if (entry.key != allComments.keys.last)
                  pw.Divider(color: _borderColor, thickness: 0.5),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // =========================================================================
  // GRADING SCALE LEGEND
  // =========================================================================
  static pw.Widget _buildGradingScaleLegend() {
    final grades = [
      ('A1', '91-100', 'Outstanding'),
      ('A2', '81-90', 'Excellent'),
      ('B1', '71-80', 'Very Good'),
      ('B2', '61-70', 'Good'),
      ('C1', '51-60', 'Above Average'),
      ('C2', '41-50', 'Average'),
      ('D', '33-40', 'Below Average'),
      ('E', '0-32', 'Needs Improvement'),
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _bgLight,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _borderColor, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Grading Scale',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _textSecondary,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: grades.map((g) {
              return pw.Column(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: _primaryLight,
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Text(
                      g.$1,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                  pw.Text(g.$2,
                      style:
                          const pw.TextStyle(fontSize: 6, color: _textSecondary)),
                  pw.Text(g.$3,
                      style:
                          const pw.TextStyle(fontSize: 5, color: _textSecondary)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SIGNATURES
  // =========================================================================
  static pw.Widget _buildSignatureSection() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _signatureBlock('Class Teacher'),
        _signatureBlock('Exam Coordinator'),
        _signatureBlock('Principal'),
        _signatureBlock('Parent / Guardian'),
      ],
    );
  }

  static pw.Widget _signatureBlock(String label) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 30), // Space for actual signature
        pw.Container(
          width: 100,
          height: 0.5,
          color: _textColor,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: _textSecondary),
        ),
      ],
    );
  }
}
