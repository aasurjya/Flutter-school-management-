import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/id_card_provider.dart';
import '../widgets/id_card_widget.dart';

// ============================================================
// Staff / Teacher ID Card Screen
// ============================================================

class StaffIdCardScreen extends ConsumerWidget {
  const StaffIdCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tenantAsync = ref.watch(currentTenantProvider);
    final staffAsync = ref.watch(currentStaffRecordProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: AppBar(
        title: const Text('My ID Card'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _Body(
          user: user,
          tenantAsync: tenantAsync,
          staffAsync: staffAsync,
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
        content: const Text('Preparing ID card for sharing...'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final dynamic user;
  final AsyncValue tenantAsync;
  final AsyncValue staffAsync;

  const _Body({
    required this.user,
    required this.tenantAsync,
    required this.staffAsync,
  });

  @override
  Widget build(BuildContext context) {
    // Wait for both tenant and staff data
    final isLoading =
        tenantAsync is AsyncLoading || staffAsync is AsyncLoading;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final tenant = tenantAsync.valueOrNull;
    final staffRecord = staffAsync.valueOrNull as Map<String, dynamic>?;

    final displayName = user?.fullName ?? 'Staff Member';
    final initials = user?.initials ?? 'S';
    final role = user?.primaryRole ?? 'staff';
    final userId = user?.id ?? '';

    final employeeId = staffRecord?['employee_id'] as String? ?? userId;
    final designation = staffRecord?['designation'] as String?;
    final department = staffRecord?['department'] as String?;

    final cardType = _cardTypeForRole(role);
    final fields = <IdCardField>[
      if (designation != null && designation.isNotEmpty)
        IdCardField(label: 'DESGN', value: designation),
      if (department != null && department.isNotEmpty)
        IdCardField(label: 'DEPT', value: department),
      IdCardField(label: 'ROLE', value: _displayRole(role)),
    ];

    final cardData = IdCardData(
      personName: displayName,
      personInitials: initials,
      personPhotoUrl: user?.avatarUrl,
      personId: employeeId,
      cardType: cardType,
      qrData: 'staff:$userId',
      schoolName: tenant?.name ?? 'School',
      schoolLogoUrl: tenant?.logoUrl,
      schoolPhone: tenant?.phone,
      schoolEmail: tenant?.email,
      fields: fields,
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

  String _cardTypeForRole(String role) {
    switch (role) {
      case 'teacher':
        return 'Teacher Identity Card';
      case 'tenant_admin':
        return 'Administrator Identity Card';
      case 'principal':
        return 'Principal Identity Card';
      case 'accountant':
        return 'Accountant Identity Card';
      case 'librarian':
        return 'Librarian Identity Card';
      case 'transport_manager':
        return 'Transport Manager Identity Card';
      case 'hostel_warden':
        return 'Hostel Warden Identity Card';
      case 'canteen_staff':
        return 'Canteen Staff Identity Card';
      case 'receptionist':
        return 'Receptionist Identity Card';
      default:
        return 'Staff Identity Card';
    }
  }

  String _displayRole(String role) {
    return role
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}
