import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';

/// Data model for rendering an ID card.
/// Works for students, teachers, and all staff roles.
class IdCardData {
  final String personName;
  final String personInitials;
  final String? personPhotoUrl;
  final String personId;
  final String cardType; // e.g. "Student Identity Card", "Teacher Identity Card"
  final String qrData;

  // School info (from tenant)
  final String schoolName;
  final String? schoolLogoUrl;
  final String? schoolPhone;
  final String? schoolEmail;
  final String academicYear;

  // Role-specific fields (key-value pairs)
  final List<IdCardField> fields;

  const IdCardData({
    required this.personName,
    required this.personInitials,
    this.personPhotoUrl,
    required this.personId,
    required this.cardType,
    required this.qrData,
    required this.schoolName,
    this.schoolLogoUrl,
    this.schoolPhone,
    this.schoolEmail,
    this.academicYear = 'AY 2025-26',
    this.fields = const [],
  });
}

class IdCardField {
  final String label;
  final String value;

  const IdCardField({required this.label, required this.value});
}

// ============================================================
// Universal ID Card Widget
// ============================================================

class IdCardWidget extends StatelessWidget {
  final IdCardData data;

  const IdCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _CardHeader(data: data),
            _CardBody(data: data),
          ],
        ),
      ),
    );
  }
}

// ─── Header with school name & logo ──────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final IdCardData data;

  const _CardHeader({required this.data});

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
          // School logo or fallback icon
          _SchoolLogo(
            logoUrl: data.schoolLogoUrl,
            schoolName: data.schoolName,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.schoolName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  data.cardType,
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
            data.academicYear,
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

// ─── School logo widget ──────────────────────────────────────────────────────

class _SchoolLogo extends StatelessWidget {
  final String? logoUrl;
  final String schoolName;

  const _SchoolLogo({required this.logoUrl, required this.schoolName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl != null && logoUrl!.isNotEmpty
          ? Image.network(
              logoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _LogoFallback(name: schoolName),
            )
          : _LogoFallback(name: schoolName),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  final String name;

  const _LogoFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'S',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 22,
        ),
      ),
    );
  }
}

// ─── Card body with person info + QR ─────────────────────────────────────────

class _CardBody extends StatelessWidget {
  final IdCardData data;

  const _CardBody({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PersonAvatar(
                initials: data.personInitials,
                photoUrl: data.personPhotoUrl,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.personName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D0D0D),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...data.fields.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: _InfoRow(label: f.label, value: f.value),
                      ),
                    ),
                    _InfoRow(
                      label: 'ID',
                      value: data.personId.length > 8
                          ? '${data.personId.substring(0, 8).toUpperCase()}...'
                          : data.personId.toUpperCase(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFEEF0F3), height: 1),
          const SizedBox(height: 24),
          _QrSection(qrData: data.qrData),
        ],
      ),
    );
  }
}

// ─── Person avatar with photo support ────────────────────────────────────────

class _PersonAvatar extends StatelessWidget {
  final String initials;
  final String? photoUrl;

  const _PersonAvatar({required this.initials, this.photoUrl});

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
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _InitialsAvatar(initials: initials),
            )
          : _InitialsAvatar(initials: initials),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;

  const _InitialsAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 28,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ─── Info row ────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
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

// ─── QR section ──────────────────────────────────────────────────────────────

class _QrSection extends StatelessWidget {
  final String qrData;

  const _QrSection({required this.qrData});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: QrImageView(
            data: qrData,
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
                'This QR code contains the unique ID for verification purposes.',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF7A8490),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 12, color: AppColors.success),
                    SizedBox(width: 5),
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

// ─── Info section below the card ─────────────────────────────────────────────

class IdCardInfoSection extends StatelessWidget {
  final String? schoolPhone;
  final String? schoolEmail;
  final String academicYear;

  const IdCardInfoSection({
    super.key,
    this.schoolPhone,
    this.schoolEmail,
    this.academicYear = 'Academic Year 2025-2026',
  });

  @override
  Widget build(BuildContext context) {
    final contactParts = <String>[
      if (schoolPhone != null) schoolPhone!,
      if (schoolEmail != null) schoolEmail!,
    ];
    final contactStr =
        contactParts.isNotEmpty ? contactParts.join('  •  ') : 'Contact school office';

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
          subtitle: academicYear,
        ),
        const SizedBox(height: 8),
        const _InfoTile(
          icon: Icons.security,
          title: 'Security Note',
          subtitle: 'This ID card is the property of the school. '
              'If found, please return to the school office.',
        ),
        const SizedBox(height: 8),
        _InfoTile(
          icon: Icons.phone_outlined,
          title: 'School Contact',
          subtitle: contactStr,
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
