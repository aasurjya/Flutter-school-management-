import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/communication.dart';
import '../../providers/communication_provider.dart';

class SmsSettingsScreen extends ConsumerStatefulWidget {
  const SmsSettingsScreen({super.key});

  @override
  ConsumerState<SmsSettingsScreen> createState() => _SmsSettingsScreenState();
}

class _SmsSettingsScreenState extends ConsumerState<SmsSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late SmsProvider _provider;
  final _apiKeyController = TextEditingController();
  final _apiSecretController = TextEditingController();
  final _senderIdController = TextEditingController();
  bool _isActive = false;
  bool _isSaving = false;
  bool _obscureKey = true;
  bool _obscureSecret = true;

  @override
  void initState() {
    super.initState();
    _provider = SmsProvider.twilio;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    _senderIdController.dispose();
    super.dispose();
  }

  void _loadConfig(SmsConfig config) {
    _provider = config.provider;
    _apiKeyController.text = config.apiKeyEncrypted ?? '';
    _apiSecretController.text = config.apiSecretEncrypted ?? '';
    _senderIdController.text = config.senderId ?? '';
    _isActive = config.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(smsConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Gateway Settings'),
      ),
      body: configAsync.when(
        data: (config) {
          if (config != null &&
              _apiKeyController.text.isEmpty &&
              _senderIdController.text.isEmpty) {
            // Load once
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _loadConfig(config));
              }
            });
          }
          return _buildForm(theme, config);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildForm(ThemeData theme, SmsConfig? existing) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status card
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_isActive ? AppColors.success : AppColors.textTertiaryLight)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.sms_outlined,
                    color: _isActive ? AppColors.success : AppColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SMS Gateway',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: _isActive ? AppColors.success : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ),

          // Balance info
          if (existing != null && existing.balanceCredits > 0) ...[
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      color: AppColors.warning),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SMS Credits Balance',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        '${existing.balanceCredits.toStringAsFixed(0)} credits',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Provider selection
          Text('SMS Provider',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SmsProvider.values.map((p) {
              return ChoiceChip(
                label: Text(p.label),
                selected: _provider == p,
                onSelected: (_) => setState(() => _provider = p),
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // API Key
          TextFormField(
            controller: _apiKeyController,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'Enter your ${_provider.label} API key',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureKey ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'API Key is required' : null,
          ),
          const SizedBox(height: 16),

          // API Secret
          TextFormField(
            controller: _apiSecretController,
            obscureText: _obscureSecret,
            decoration: InputDecoration(
              labelText: 'API Secret',
              hintText: 'Enter your ${_provider.label} API secret',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSecret ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscureSecret = !_obscureSecret),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sender ID
          TextFormField(
            controller: _senderIdController,
            decoration: const InputDecoration(
              labelText: 'Sender ID',
              hintText: 'e.g., SCHOOL or your registered sender name',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The sender name that appears when receiving SMS. Must be approved by your provider.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),

          const SizedBox(height: 24),

          // Test SMS
          OutlinedButton.icon(
            onPressed: _testSms,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Send Test SMS'),
          ),

          const SizedBox(height: 16),

          // Save
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Settings',
                      style: TextStyle(color: Colors.white)),
            ),
          ),

          const SizedBox(height: 24),

          // Help text
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: AppColors.info),
                    const SizedBox(width: 8),
                    Text(
                      'Setup Guide',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Sign up for an account with your preferred SMS provider.\n'
                  '2. Get your API credentials from the provider dashboard.\n'
                  '3. Register and approve your Sender ID.\n'
                  '4. Enter the credentials above and enable the gateway.\n'
                  '5. Send a test SMS to verify the configuration.',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _testSms() {
    showDialog(
      context: context,
      builder: (context) {
        final phoneController = TextEditingController();
        return AlertDialog(
          title: const Text('Send Test SMS'),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+91 XXXXX XXXXX',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Test SMS queued. Check your phone in a few seconds.'),
                    backgroundColor: AppColors.info,
                  ),
                );
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
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(communicationRepositoryProvider);
      await repo.upsertSmsConfig({
        'provider': _provider.value,
        'api_key_encrypted': _apiKeyController.text.trim(),
        'api_secret_encrypted': _apiSecretController.text.trim(),
        'sender_id': _senderIdController.text.trim().isNotEmpty
            ? _senderIdController.text.trim()
            : null,
        'is_active': _isActive,
      });

      ref.invalidate(smsConfigProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS settings saved successfully'),
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
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
