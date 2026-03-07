import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';

// ============================================================
// Digital Student ID Card Screen
// ============================================================

class DigitalIdScreen extends ConsumerWidget {
  final String studentId;

  const DigitalIdScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: AppBar(
        title: const Text('Student ID Card'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              _IdCard(studentId: studentId, user: user),
              const SizedBox(height: 32),
              _InfoSection(studentId: studentId),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onShare(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.share),
        label: const Text('Share ID Card'),
      ),
    );
  }

  void _onShare(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Preparing ID card for sharing…'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─── ID Card widget ────────────────────────────────────────────────────────────
class _IdCard extends StatelessWidget {
  final String studentId;
  final dynamic user;

  const _IdCard({required this.studentId, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            _CardHeader(user: user),
            _CardBody(studentId: studentId, user: user),
          ],
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final dynamic user;

  const _CardHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CASCADE SCHOOL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Student Identity Card',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'AY 2025-26',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  final String studentId;
  final dynamic user;

  const _CardBody({required this.studentId, required this.user});

  @override
  Widget build(BuildContext context) {
    final displayName = user?.fullName ?? 'Student Name';
    final initials = user?.initials ?? 'S';

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              _Avatar(initials: initials),
              const SizedBox(width: 20),
              // Student details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D0D0D),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(label: 'CLASS', value: '10-A'),
                    const SizedBox(height: 5),
                    _InfoRow(label: 'SECTION', value: 'A'),
                    const SizedBox(height: 5),
                    _InfoRow(label: 'ROLL NO', value: '15'),
                    const SizedBox(height: 5),
                    _InfoRow(
                      label: 'ID',
                      value: studentId.length > 8
                          ? '${studentId.substring(0, 8).toUpperCase()}...'
                          : studentId.toUpperCase(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFEEF0F3), height: 1),
          const SizedBox(height: 24),
          // QR Code
          _QrSection(studentId: studentId),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;

  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 100,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 28,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7A8490),
              letterSpacing: 1.0,
            ),
          ),
        ),
        const Text(
          ':  ',
          style: TextStyle(color: Color(0xFF7A8490), fontSize: 11),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D0D0D),
            ),
          ),
        ),
      ],
    );
  }
}

class _QrSection extends StatelessWidget {
  final String studentId;

  const _QrSection({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // QR code
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: QrImageView(
            data: 'student:$studentId',
            version: QrVersions.auto,
            size: 100,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF0D0D0D),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF0D0D0D),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SCAN TO VERIFY',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7A8490),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'This QR code contains the student\'s unique ID for verification purposes.',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF7A8490),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified,
                        size: 12, color: AppColors.success),
                    const SizedBox(width: 5),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Info section below the card ──────────────────────────────────────────────
class _InfoSection extends StatelessWidget {
  final String studentId;

  const _InfoSection({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CARD INFORMATION',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF7A8490),
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        _InfoTile(
          icon: Icons.info_outline,
          title: 'Valid For',
          subtitle: 'Academic Year 2025–2026',
        ),
        const SizedBox(height: 8),
        _InfoTile(
          icon: Icons.security,
          title: 'Security Note',
          subtitle: 'This ID card is the property of the school. '
              'If found, please return to the school office.',
        ),
        const SizedBox(height: 8),
        _InfoTile(
          icon: Icons.phone_outlined,
          title: 'School Contact',
          subtitle: '+91 98765 43210  •  admin@cascadeschool.edu',
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EEF2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D0D0D),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7A8490),
                    height: 1.5,
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
