import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/certificate.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/certificate_provider.dart';

class VerifyCertificateScreen extends ConsumerStatefulWidget {
  const VerifyCertificateScreen({super.key});

  @override
  ConsumerState<VerifyCertificateScreen> createState() =>
      _VerifyCertificateScreenState();
}

class _VerifyCertificateScreenState
    extends ConsumerState<VerifyCertificateScreen> {
  final _numberController = TextEditingController();
  IssuedCertificate? _result;
  bool _isSearching = false;
  bool _searched = false;

  Future<void> _verify() async {
    final number = _numberController.text.trim();
    if (number.isEmpty) return;

    setState(() {
      _isSearching = true;
      _result = null;
      _searched = false;
    });

    try {
      final repo = ref.read(certificateRepositoryProvider);
      final cert = await repo.verifyCertificate(number);
      if (mounted) {
        setState(() {
          _result = cert;
          _searched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _searched = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Certificate'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Verification header
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Certificate Verification',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the certificate number or scan the QR code to verify authenticity.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter Certificate Number',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _numberController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., TRANSFER-2026-00001',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onFieldSubmitted: (_) => _verify(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSearching ? null : _verify,
                      child: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Text('Verify'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Result
          if (_searched) ...[
            if (_result != null) ...[
              // Valid certificate
              GlassCard(
                padding: const EdgeInsets.all(20),
                borderColor: _result!.status == CertificateStatus.issued
                    ? AppColors.success
                    : _result!.status == CertificateStatus.revoked
                        ? AppColors.error
                        : AppColors.warning,
                borderWidth: 2,
                child: Column(
                  children: [
                    Icon(
                      _result!.status == CertificateStatus.issued
                          ? Icons.verified
                          : _result!.status == CertificateStatus.revoked
                              ? Icons.dangerous
                              : Icons.pending,
                      color: _result!.status == CertificateStatus.issued
                          ? AppColors.success
                          : _result!.status == CertificateStatus.revoked
                              ? AppColors.error
                              : AppColors.warning,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _result!.status == CertificateStatus.issued
                          ? 'VALID CERTIFICATE'
                          : _result!.status == CertificateStatus.revoked
                              ? 'REVOKED CERTIFICATE'
                              : 'DRAFT CERTIFICATE',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            _result!.status == CertificateStatus.issued
                                ? AppColors.success
                                : _result!.status ==
                                        CertificateStatus.revoked
                                    ? AppColors.error
                                    : AppColors.warning,
                      ),
                    ),
                    if (_result!.status == CertificateStatus.revoked &&
                        _result!.revokedReason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Reason: ${_result!.revokedReason}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _verifyRow('Certificate No',
                        _result!.certificateNumber),
                    _verifyRow(
                        'Type',
                        _result!.template?.type.label ??
                            'Certificate'),
                    _verifyRow('Student',
                        _result!.studentName ?? 'Unknown'),
                    if (_result!.studentAdmissionNumber != null)
                      _verifyRow('Admission No',
                          _result!.studentAdmissionNumber!),
                    if (_result!.className != null)
                      _verifyRow('Class', _result!.className!),
                    _verifyRow('Issued Date',
                        dateFormat.format(_result!.issuedDate)),
                    if (_result!.issuedByName != null)
                      _verifyRow('Issued By', _result!.issuedByName!),
                    if (_result!.purpose != null)
                      _verifyRow('Purpose', _result!.purpose!),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(
                          AppRoutes.certificatePreview.replaceFirst(
                              ':certId', _result!.id),
                        ),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('View PDF'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Not found
              GlassCard(
                padding: const EdgeInsets.all(24),
                borderColor: AppColors.error,
                borderWidth: 2,
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'CERTIFICATE NOT FOUND',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The certificate number "${_numberController.text}" could not be verified. '
                      'Please check the number and try again.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _verifyRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
