import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/whatsapp_config.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/whatsapp_provider.dart';

class WhatsAppSettingsScreen extends ConsumerStatefulWidget {
  const WhatsAppSettingsScreen({super.key});

  @override
  ConsumerState<WhatsAppSettingsScreen> createState() =>
      _WhatsAppSettingsScreenState();
}

class _WhatsAppSettingsScreenState
    extends ConsumerState<WhatsAppSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // WhatsApp fields
  bool _whatsappEnabled = false;
  final _waApiKeyCtrl = TextEditingController();
  final _waPhoneNumberIdCtrl = TextEditingController();
  final _waBusinessAccountIdCtrl = TextEditingController();
  bool _obscureWaKey = true;

  // SMS fields
  bool _smsEnabled = false;
  SmsProvider _smsProvider = SmsProvider.twilio;
  final _smsApiKeyCtrl = TextEditingController();
  final _smsSenderIdCtrl = TextEditingController();
  bool _obscureSmsKey = true;

  // Auto-notification toggles
  bool _autoAttendance = true;
  bool _autoFee = true;
  bool _autoResult = true;
  bool _autoAbsence = true;

  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _waApiKeyCtrl.dispose();
    _waPhoneNumberIdCtrl.dispose();
    _waBusinessAccountIdCtrl.dispose();
    _smsApiKeyCtrl.dispose();
    _smsSenderIdCtrl.dispose();
    super.dispose();
  }

  void _populateFrom(WhatsAppConfig config) {
    _whatsappEnabled = config.whatsappEnabled;
    _waApiKeyCtrl.text = config.whatsappApiKey ?? '';
    _waPhoneNumberIdCtrl.text = config.whatsappPhoneNumberId ?? '';
    _waBusinessAccountIdCtrl.text = config.whatsappBusinessAccountId ?? '';
    _smsEnabled = config.smsEnabled;
    _smsProvider = config.smsProvider ?? SmsProvider.twilio;
    _smsApiKeyCtrl.text = config.smsApiKey ?? '';
    _smsSenderIdCtrl.text = config.smsSenderId ?? '';
    _autoAttendance = config.autoAttendanceNotify;
    _autoFee = config.autoFeeNotify;
    _autoResult = config.autoResultNotify;
    _autoAbsence = config.autoAbsenceNotify;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(whatsappConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp & SMS Settings'),
      ),
      body: configAsync.when(
        data: (config) {
          if (config != null && !_loaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _populateFrom(config);
                  _loaded = true;
                });
              }
            });
          }
          return _buildBody(theme, config);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Error loading settings: $e'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(whatsappConfigProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, WhatsAppConfig? existing) {
    final isConfigured = existing?.isConfigured ?? false;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status badge ──────────────────────────────────────
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isConfigured ? AppColors.success : AppColors.warning)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isConfigured ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                    color: isConfigured ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConfigured
                            ? 'Integration Active'
                            : 'Not Configured',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isConfigured
                            ? 'WhatsApp/SMS ready to send notifications'
                            : 'Complete setup below to enable messaging',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── WhatsApp Business ─────────────────────────────────
          const _SectionHeader(
            icon: Icons.chat_outlined,
            iconColor: Color(0xFF25D366),
            title: 'WhatsApp Business',
          ),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Enable WhatsApp Notifications',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Switch(
                      value: _whatsappEnabled,
                      onChanged: (v) =>
                          setState(() => _whatsappEnabled = v),
                      activeThumbColor: const Color(0xFF25D366),
                    ),
                  ],
                ),
                if (_whatsappEnabled) ...[
                  const Divider(height: 24),
                  _SecretField(
                    controller: _waApiKeyCtrl,
                    label: 'API Key',
                    hint: 'WhatsApp Business API key',
                    obscure: _obscureWaKey,
                    onToggle: () =>
                        setState(() => _obscureWaKey = !_obscureWaKey),
                    validator: _whatsappEnabled
                        ? (v) => (v == null || v.isEmpty)
                            ? 'API Key is required'
                            : null
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _waPhoneNumberIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number ID',
                      hintText: 'e.g., 123456789012345',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _waBusinessAccountIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Business Account ID',
                      hintText: 'WhatsApp Business Account ID',
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── SMS Gateway ───────────────────────────────────────
          const _SectionHeader(
            icon: Icons.sms_outlined,
            iconColor: AppColors.info,
            title: 'SMS Gateway',
          ),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Enable SMS Notifications',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Switch(
                      value: _smsEnabled,
                      onChanged: (v) => setState(() => _smsEnabled = v),
                      activeThumbColor: AppColors.info,
                    ),
                  ],
                ),
                if (_smsEnabled) ...[
                  const Divider(height: 24),
                  Text(
                    'Provider',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SmsProvider.values.map((p) {
                      return ChoiceChip(
                        label: Text(p.label),
                        selected: _smsProvider == p,
                        onSelected: (_) =>
                            setState(() => _smsProvider = p),
                        selectedColor:
                            AppColors.info.withValues(alpha: 0.15),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _SecretField(
                    controller: _smsApiKeyCtrl,
                    label: '${_smsProvider.label} API Key',
                    hint: 'Enter your API key',
                    obscure: _obscureSmsKey,
                    onToggle: () =>
                        setState(() => _obscureSmsKey = !_obscureSmsKey),
                    validator: _smsEnabled
                        ? (v) => (v == null || v.isEmpty)
                            ? 'API Key is required'
                            : null
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _smsSenderIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Sender ID',
                      hintText: 'e.g., SCHOOL',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sender name shown on recipient handset. Must be pre-approved by your provider.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Auto-Notifications ────────────────────────────────
          const _SectionHeader(
            icon: Icons.notifications_active_outlined,
            iconColor: AppColors.accent,
            title: 'Auto-Notifications',
          ),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _AutoToggle(
                  title: 'Attendance Alerts',
                  subtitle: 'Notify parents when student is absent',
                  value: _autoAttendance,
                  onChanged: (v) =>
                      setState(() => _autoAttendance = v),
                ),
                _AutoToggle(
                  title: 'Fee Reminders',
                  subtitle: 'Send fee due / overdue notifications',
                  value: _autoFee,
                  onChanged: (v) => setState(() => _autoFee = v),
                ),
                _AutoToggle(
                  title: 'Exam Results',
                  subtitle: 'Notify when results are published',
                  value: _autoResult,
                  onChanged: (v) => setState(() => _autoResult = v),
                ),
                _AutoToggle(
                  title: 'Absence Reports',
                  subtitle: 'Daily absence summary to class teacher',
                  value: _autoAbsence,
                  onChanged: (v) =>
                      setState(() => _autoAbsence = v),
                  showDivider: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Test Message Button ───────────────────────────────
          OutlinedButton.icon(
            onPressed: _showTestDialog,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Send Test Message'),
          ),

          const SizedBox(height: 12),

          // ── Save Button ───────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Configuration',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showTestDialog() {
    final phoneCtrl = TextEditingController();
    final msgCtrl =
        TextEditingController(text: 'Test message from School Management App');
    String selectedChannel = 'sms';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Send Test Message'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'whatsapp', label: Text('WhatsApp')),
                      ButtonSegment(value: 'sms', label: Text('SMS')),
                    ],
                    selected: {selectedChannel},
                    onSelectionChanged: (s) =>
                        setDialogState(() => selectedChannel = s.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+91 9876543210',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final repo = ref.read(whatsappRepositoryProvider);
                    final ok = await repo.sendTestMessage(
                      channel: selectedChannel,
                      phone: phoneCtrl.text.trim(),
                      message: msgCtrl.text.trim(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'Test message queued successfully'
                              : 'Failed to send test message'),
                          backgroundColor:
                              ok ? AppColors.success : AppColors.error,
                        ),
                      );
                      if (ok) ref.invalidate(notificationLogsProvider);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Send',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final existingConfig = ref.read(whatsappConfigProvider).valueOrNull;
      final tenantId = existingConfig?.tenantId ??
          // Fallback: pull from supabase JWT
          (ref.read(whatsappRepositoryProvider).tenantId ?? '');

      if (tenantId.isEmpty) {
        throw StateError('Unable to determine tenant ID');
      }

      final updated = WhatsAppConfig(
        id: existingConfig?.id,
        tenantId: tenantId,
        whatsappEnabled: _whatsappEnabled,
        whatsappApiKey: _waApiKeyCtrl.text.trim().isEmpty
            ? null
            : _waApiKeyCtrl.text.trim(),
        whatsappPhoneNumberId: _waPhoneNumberIdCtrl.text.trim().isEmpty
            ? null
            : _waPhoneNumberIdCtrl.text.trim(),
        whatsappBusinessAccountId:
            _waBusinessAccountIdCtrl.text.trim().isEmpty
                ? null
                : _waBusinessAccountIdCtrl.text.trim(),
        smsEnabled: _smsEnabled,
        smsProvider: _smsProvider,
        smsApiKey: _smsApiKeyCtrl.text.trim().isEmpty
            ? null
            : _smsApiKeyCtrl.text.trim(),
        smsSenderId: _smsSenderIdCtrl.text.trim().isEmpty
            ? null
            : _smsSenderIdCtrl.text.trim(),
        autoAttendanceNotify: _autoAttendance,
        autoFeeNotify: _autoFee,
        autoResultNotify: _autoResult,
        autoAbsenceNotify: _autoAbsence,
      );

      await ref.read(whatsappConfigProvider.notifier).save(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _SecretField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _SecretField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          tooltip: 'Toggle visibility',
          onPressed: onToggle,
        ),
      ),
    );
  }
}

class _AutoToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _AutoToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          title: Text(title),
          subtitle: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
        if (showDivider)
          const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
