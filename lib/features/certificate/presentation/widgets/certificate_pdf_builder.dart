import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../data/models/certificate.dart';

/// Builds professional PDF certificates
class CertificatePdfBuilder {
  CertificatePdfBuilder._();

  /// Generate a certificate PDF
  static Future<Uint8List> buildCertificatePdf({
    required IssuedCertificate certificate,
    required CertificateTemplate template,
    String? schoolName,
    String? schoolAddress,
    String? schoolLogo,
  }) async {
    final pdf = pw.Document();

    final margins = template.margins;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.only(
          top: margins['top']!,
          bottom: margins['bottom']!,
          left: margins['left']!,
          right: margins['right']!,
        ),
        build: (pw.Context context) {
          switch (template.type) {
            case CertificateType.transfer:
              return _buildTransferCertificate(
                context,
                certificate: certificate,
                template: template,
                schoolName: schoolName,
                schoolAddress: schoolAddress,
              );
            case CertificateType.bonafide:
              return _buildBonafideCertificate(
                context,
                certificate: certificate,
                template: template,
                schoolName: schoolName,
                schoolAddress: schoolAddress,
              );
            case CertificateType.character:
              return _buildCharacterCertificate(
                context,
                certificate: certificate,
                template: template,
                schoolName: schoolName,
                schoolAddress: schoolAddress,
              );
            case CertificateType.achievement:
            case CertificateType.participation:
            case CertificateType.merit:
              return _buildAchievementCertificate(
                context,
                certificate: certificate,
                template: template,
                schoolName: schoolName,
                schoolAddress: schoolAddress,
              );
            default:
              return _buildGenericCertificate(
                context,
                certificate: certificate,
                template: template,
                schoolName: schoolName,
                schoolAddress: schoolAddress,
              );
          }
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader({
    String? schoolName,
    String? schoolAddress,
    String certTitle = 'CERTIFICATE',
  }) {
    return pw.Column(
      children: [
        pw.Text(
          schoolName ?? 'School Name',
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1e3a5f'),
          ),
          textAlign: pw.TextAlign.center,
        ),
        if (schoolAddress != null)
          pw.Text(
            schoolAddress,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
            textAlign: pw.TextAlign.center,
          ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColor.fromHex('#1e3a5f'), thickness: 2),
        pw.SizedBox(height: 12),
        pw.Text(
          certTitle,
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#2c5282'),
            letterSpacing: 4,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  static pw.Widget _buildFooter({
    required IssuedCertificate certificate,
  }) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 40),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(width: 120, child: pw.Divider()),
                pw.SizedBox(height: 4),
                pw.Text('Principal',
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.Column(
              children: [
                pw.Text(
                  'Certificate No: ${certificate.certificateNumber}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'Date: ${_formatDate(certificate.issuedDate)}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(width: 120, child: pw.Divider()),
                pw.SizedBox(height: 4),
                pw.Text('Authorized Signatory',
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTransferCertificate(
    pw.Context context, {
    required IssuedCertificate certificate,
    required CertificateTemplate template,
    String? schoolName,
    String? schoolAddress,
  }) {
    final data = certificate.data;
    final studentName = certificate.studentName ?? 'Student';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _buildHeader(
          schoolName: schoolName,
          schoolAddress: schoolAddress,
          certTitle: 'TRANSFER CERTIFICATE',
        ),
        _buildBodyText(
          'This is to certify that $studentName, '
          '${data['son_daughter'] ?? 'son/daughter'} of ${data['parent_name'] ?? 'Parent'}, '
          'bearing Admission No. ${certificate.studentAdmissionNumber ?? data['admission_number'] ?? 'N/A'}, '
          'was a bonafide student of this institution from '
          '${data['from_date'] ?? 'N/A'} to ${data['to_date'] ?? 'N/A'}.\n\n'
          'Class at the time of leaving: ${certificate.className ?? data['class'] ?? 'N/A'}.\n'
          'Conduct and character: ${data['conduct'] ?? 'Good'}.\n'
          'Reason for leaving: ${data['reason'] ?? certificate.purpose ?? 'N/A'}.\n\n'
          'This Transfer Certificate is issued on request for the purpose of '
          '${certificate.purpose ?? 'further studies'}.',
        ),
        _buildFooter(certificate: certificate),
      ],
    );
  }

  static pw.Widget _buildBonafideCertificate(
    pw.Context context, {
    required IssuedCertificate certificate,
    required CertificateTemplate template,
    String? schoolName,
    String? schoolAddress,
  }) {
    final data = certificate.data;
    final studentName = certificate.studentName ?? 'Student';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _buildHeader(
          schoolName: schoolName,
          schoolAddress: schoolAddress,
          certTitle: 'BONAFIDE CERTIFICATE',
        ),
        _buildBodyText(
          'This is to certify that $studentName, '
          '${data['son_daughter'] ?? 'son/daughter'} of ${data['parent_name'] ?? 'Parent'}, '
          'bearing Admission No. ${certificate.studentAdmissionNumber ?? data['admission_number'] ?? 'N/A'}, '
          'is a bonafide student of this institution.\n\n'
          'Class: ${certificate.className ?? data['class'] ?? 'N/A'}.\n'
          'Date of Birth: ${data['dob'] ?? 'N/A'}.\n'
          'Academic Year: ${data['academic_year'] ?? 'N/A'}.\n\n'
          'This certificate is issued upon request for the purpose of '
          '${certificate.purpose ?? 'official records'}.',
        ),
        _buildFooter(certificate: certificate),
      ],
    );
  }

  static pw.Widget _buildCharacterCertificate(
    pw.Context context, {
    required IssuedCertificate certificate,
    required CertificateTemplate template,
    String? schoolName,
    String? schoolAddress,
  }) {
    final data = certificate.data;
    final studentName = certificate.studentName ?? 'Student';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _buildHeader(
          schoolName: schoolName,
          schoolAddress: schoolAddress,
          certTitle: 'CHARACTER CERTIFICATE',
        ),
        _buildBodyText(
          'This is to certify that $studentName, '
          '${data['son_daughter'] ?? 'son/daughter'} of ${data['parent_name'] ?? 'Parent'}, '
          'was a student of this institution '
          'from ${data['from_date'] ?? 'N/A'} to ${data['to_date'] ?? 'N/A'}.\n\n'
          'During the period of study, ${data['pronoun'] ?? 'the student'} '
          'has maintained ${data['conduct'] ?? 'good'} conduct and character. '
          '${data['additional_remarks'] ?? ''}\n\n'
          'I wish ${data['pronoun'] ?? 'the student'} success in all future endeavors.',
        ),
        _buildFooter(certificate: certificate),
      ],
    );
  }

  static pw.Widget _buildAchievementCertificate(
    pw.Context context, {
    required IssuedCertificate certificate,
    required CertificateTemplate template,
    String? schoolName,
    String? schoolAddress,
  }) {
    final data = certificate.data;
    final studentName = certificate.studentName ?? 'Student';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _buildHeader(
          schoolName: schoolName,
          schoolAddress: schoolAddress,
          certTitle: 'CERTIFICATE OF ${template.type.label.toUpperCase()}',
        ),
        pw.Center(
          child: pw.Text(
            'This certificate is proudly awarded to',
            style: const pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Center(
          child: pw.Text(
            studentName,
            style: pw.TextStyle(
              fontSize: 26,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#2c5282'),
            ),
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Center(
          child: pw.Text(
            data['achievement_description'] ??
                certificate.purpose ??
                'for outstanding performance',
            style: const pw.TextStyle(fontSize: 14),
            textAlign: pw.TextAlign.center,
          ),
        ),
        if (data['event_name'] != null) ...[
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Event: ${data['event_name']}',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
        if (data['date'] != null) ...[
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Date: ${data['date']}',
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ],
        _buildFooter(certificate: certificate),
      ],
    );
  }

  static pw.Widget _buildGenericCertificate(
    pw.Context context, {
    required IssuedCertificate certificate,
    required CertificateTemplate template,
    String? schoolName,
    String? schoolAddress,
  }) {
    final data = certificate.data;
    final studentName = certificate.studentName ?? 'Student';
    final body = data['body'] as String? ??
        'This is to certify that $studentName '
            'is associated with this institution.\n\n'
            '${certificate.purpose ?? ''}';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _buildHeader(
          schoolName: schoolName,
          schoolAddress: schoolAddress,
          certTitle: template.name.toUpperCase(),
        ),
        _buildBodyText(body),
        _buildFooter(certificate: certificate),
      ],
    );
  }

  static pw.Widget _buildBodyText(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 13,
          lineSpacing: 6,
        ),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
