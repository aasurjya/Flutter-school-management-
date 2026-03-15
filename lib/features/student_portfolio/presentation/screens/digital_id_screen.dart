import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../id_card/presentation/widgets/id_card_widget.dart';
import '../../../id_card/providers/id_card_provider.dart';

// ============================================================
// Digital Student ID Card Screen
// ============================================================

class DigitalIdScreen extends ConsumerWidget {
  final String studentId;

  const DigitalIdScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tenantAsync = ref.watch(currentTenantProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: AppBar(
        title: const Text('Student ID Card'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: tenantAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildCard(context, user, null),
          data: (tenant) => _buildCard(context, user, tenant),
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

  Widget _buildCard(BuildContext context, dynamic user, dynamic tenant) {
    final displayName = user?.fullName ?? 'Student Name';
    final initials = user?.initials ?? 'S';

    final cardData = IdCardData(
      personName: displayName,
      personInitials: initials,
      personPhotoUrl: user?.avatarUrl,
      personId: studentId,
      cardType: 'Student Identity Card',
      qrData: 'student:$studentId',
      schoolName: tenant?.name ?? 'School',
      schoolLogoUrl: tenant?.logoUrl,
      schoolPhone: tenant?.phone,
      schoolEmail: tenant?.email,
      fields: const [
        IdCardField(label: 'CLASS', value: '10-A'),
        IdCardField(label: 'SECTION', value: 'A'),
        IdCardField(label: 'ROLL NO', value: '15'),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          IdCardWidget(data: cardData),
          const SizedBox(height: 32),
          IdCardInfoSection(
            schoolPhone: tenant?.phone,
            schoolEmail: tenant?.email,
          ),
        ],
      ),
    );
  }

  void _onShare(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Preparing ID card for sharing...'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
