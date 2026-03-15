import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/id_card_provider.dart';

// ============================================================
// School Branding Screen — Logo Upload for Admin
// ============================================================

class SchoolBrandingScreen extends ConsumerStatefulWidget {
  const SchoolBrandingScreen({super.key});

  @override
  ConsumerState<SchoolBrandingScreen> createState() =>
      _SchoolBrandingScreenState();
}

class _SchoolBrandingScreenState extends ConsumerState<SchoolBrandingScreen> {
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final tenantAsync = ref.watch(currentTenantProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: AppBar(
        title: const Text('School Branding'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: tenantAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (tenant) {
            if (tenant == null) {
              return const Center(child: Text('No school data found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // School info header
                  const Text(
                    'SCHOOL IDENTITY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7A8490),
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Current logo section
                  _LogoSection(
                    logoUrl: tenant.logoUrl,
                    schoolName: tenant.name,
                    uploading: _uploading,
                    onUpload: () => _pickAndUploadLogo(tenant.id),
                    onRemove: tenant.logoUrl != null
                        ? () => _removeLogo(tenant.id)
                        : null,
                  ),

                  const SizedBox(height: 32),

                  // School name display
                  _InfoCard(
                    icon: Icons.school_rounded,
                    label: 'School Name',
                    value: tenant.name,
                  ),
                  const SizedBox(height: 12),
                  if (tenant.email != null)
                    _InfoCard(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: tenant.email!,
                    ),
                  if (tenant.email != null) const SizedBox(height: 12),
                  if (tenant.phone != null)
                    _InfoCard(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: tenant.phone!,
                    ),
                  if (tenant.phone != null) const SizedBox(height: 12),
                  if (tenant.address != null)
                    _InfoCard(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: tenant.fullAddress,
                    ),

                  const SizedBox(height: 32),

                  // Info about logo usage
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 18,
                            color: AppColors.info.withValues(alpha: 0.8)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Your school logo will appear on all ID cards generated '
                            'for students, teachers, and staff. Recommended size: '
                            '512x512px, PNG or JPG format.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7A8490),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickAndUploadLogo(String tenantId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() => _uploading = true);

    try {
      final client = ref.read(supabaseProvider);
      final bytes = await picked.readAsBytes();
      final ext = picked.path.split('.').last;
      final path = 'logos/$tenantId/logo.$ext';

      // Upload to Supabase Storage
      await client.storage.from('school-assets').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final publicUrl =
          client.storage.from('school-assets').getPublicUrl(path);

      // Update tenant record
      await client.from('tenants').update({
        'logo_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', tenantId);

      // Refresh tenant provider
      ref.invalidate(currentTenantProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logo uploaded successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.message}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removeLogo(String tenantId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Logo'),
        content: const Text(
            'Are you sure? ID cards will show a text placeholder instead.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _uploading = true);
    try {
      final client = ref.read(supabaseProvider);

      await client.from('tenants').update({
        'logo_url': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', tenantId);

      ref.invalidate(currentTenantProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logo removed'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}

// ─── Logo section widget ─────────────────────────────────────────────────────

class _LogoSection extends StatelessWidget {
  final String? logoUrl;
  final String schoolName;
  final bool uploading;
  final VoidCallback onUpload;
  final VoidCallback? onRemove;

  const _LogoSection({
    required this.logoUrl,
    required this.schoolName,
    required this.uploading,
    required this.onUpload,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF2)),
      ),
      child: Column(
        children: [
          // Logo preview
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: uploading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : logoUrl != null && logoUrl!.isNotEmpty
                    ? Image.network(
                        logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _LogoPlaceholder(name: schoolName),
                      )
                    : _LogoPlaceholder(name: schoolName),
          ),
          const SizedBox(height: 20),

          // Upload/Change button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: uploading ? null : onUpload,
              icon: Icon(
                logoUrl != null ? Icons.edit : Icons.upload_rounded,
                size: 18,
              ),
              label: Text(logoUrl != null ? 'Change Logo' : 'Upload Logo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          if (onRemove != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: uploading ? null : onRemove,
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Remove Logo'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  final String name;

  const _LogoPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_photo_alternate_outlined,
              size: 32, color: Color(0xFFB0B8C4)),
          const SizedBox(height: 8),
          Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'S',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFFB0B8C4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info card widget ────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EEF2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A8490),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D0D0D),
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
