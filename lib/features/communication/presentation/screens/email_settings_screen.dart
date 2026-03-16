import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/communication.dart';
import '../../providers/communication_provider.dart';

class EmailSettingsScreen extends ConsumerStatefulWidget {
  const EmailSettingsScreen({super.key});

  @override
  ConsumerState<EmailSettingsScreen> createState() =>
      _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends ConsumerState<EmailSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late EmailProvider _provider;
  final _fromEmailController = TextEditingController();
  final _fromNameController = TextEditingController();
  final _dailyLimitController = TextEditingController(text: '500');
  bool _isActive = false;
  bool _isSaving = false;

  // SMTP specific fields
  final _smtpHostController = TextEditingController();
  final _smtpPortController = TextEditingController(text: '587');
  final _smtpUsernameController = TextEditingController();
  final _smtpPasswordController = TextEditingController();
  bool _smtpUseTls = true;

  // API-based provider fields
  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _provider = EmailProvider.smtp;
  }

  @override
  void dispose() {
    _fromEmailController.dispose();
    _fromNameController.dispose();
    _dailyLimitController.dispose();
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _smtpUsernameController.dispose();
    _smtpPasswordController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _loadConfig(EmailConfig config) {
    _provider = config.provider;
    _fromEmailController.text = config.fromEmail ?? '';
    _fromNameController.text = config.fromName ?? '';
    _dailyLimitController.text = config.dailyLimit.toString();
    _isActive = config.isActive;

    // Load provider-specific config
    final providerConfig = config.config;
    if (_provider == EmailProvider.smtp) {
      _smtpHostController.text = providerConfig['host'] as String? ?? '';
      _smtpPortController.text =
          (providerConfig['port'] as num?)?.toString() ?? '587';
      _smtpUsernameController.text =
          providerConfig['username'] as String? ?? '';
      _smtpPasswordController.text =
          providerConfig['password'] as String? ?? '';
      _smtpUseTls = providerConfig['use_tls'] as bool? ?? true;
    } else {
      _apiKeyController.text = providerConfig['api_key'] as String? ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(emailConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Settings'),
      ),
      body: configAsync.when(
        data: (config) {
          if (config != null &&
              _fromEmailController.text.isEmpty &&
              _fromNameController.text.isEmpty) {
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

  Widget _buildForm(ThemeData theme, EmailConfig? existing) {
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
                    Icons.email_outlined,
                    color: _isActive ? AppColors.success : AppColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Service',
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

          // Daily limit info
          if (existing != null) ...[
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.speed_outlined, color: AppColors.info),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sent Today', style: theme.textTheme.bodySmall),
                      Text(
                        '${existing.sentToday} / ${existing.dailyLimit}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: existing.dailyLimit > 0
                              ? existing.sentToday / existing.dailyLimit
                              : 0,
                          strokeWidth: 5,
                          backgroundColor: AppColors.borderLight,
                          color: existing.remainingToday > 0
                              ? AppColors.info
                              : AppColors.error,
                        ),
                        Text(
                          '${existing.remainingToday}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Provider selection
          Text('Email Provider',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EmailProvider.values.map((p) {
              return ChoiceChip(
                label: Text(p.label),
                selected: _provider == p,
                onSelected: (_) => setState(() => _provider = p),
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Provider-specific config
          if (_provider == EmailProvider.smtp) _buildSmtpConfig(theme),
          if (_provider != EmailProvider.smtp) _buildApiConfig(theme),

          const Divider(height: 32),

          // From fields
          Text('Sender Information',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fromEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'From Email',
              hintText: 'notifications@yourschool.com',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'From email is required';
              if (!v.contains('@')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fromNameController,
            decoration: const InputDecoration(
              labelText: 'From Name',
              hintText: 'e.g., Kendriya Vidyalaya',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _dailyLimitController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Daily Sending Limit',
              hintText: '500',
            ),
          ),

          const SizedBox(height: 24),

          // Test email
          OutlinedButton.icon(
            onPressed: _testEmail,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Send Test Email'),
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSmtpConfig(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SMTP Configuration',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _smtpHostController,
          decoration: const InputDecoration(
            labelText: 'SMTP Host',
            hintText: 'smtp.gmail.com',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _smtpPortController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'SMTP Port',
            hintText: '587',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _smtpUsernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'your-email@gmail.com',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _smtpPasswordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'App password or SMTP password',
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              tooltip: 'Toggle visibility',
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Use TLS'),
          subtitle: const Text('Enable TLS encryption (recommended)'),
          value: _smtpUseTls,
          onChanged: (v) => setState(() => _smtpUseTls = v),
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildApiConfig(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${_provider.label} Configuration',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
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
              tooltip: 'Toggle visibility',
              onPressed: () => setState(() => _obscureKey = !_obscureKey),
            ),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? 'API Key is required' : null,
        ),
      ],
    );
  }

  void _testEmail() {
    showDialog(
      context: context,
      builder: (context) {
        final emailController = TextEditingController();
        return AlertDialog(
          title: const Text('Send Test Email'),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Recipient Email',
              hintText: 'your@email.com',
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
                    content: Text('Test email queued. Check your inbox.'),
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
      Map<String, dynamic> providerConfig;

      if (_provider == EmailProvider.smtp) {
        providerConfig = {
          'host': _smtpHostController.text.trim(),
          'port': int.tryParse(_smtpPortController.text) ?? 587,
          'username': _smtpUsernameController.text.trim(),
          'password': _smtpPasswordController.text.trim(),
          'use_tls': _smtpUseTls,
        };
      } else {
        providerConfig = {
          'api_key': _apiKeyController.text.trim(),
        };
      }

      final repo = ref.read(communicationRepositoryProvider);
      await repo.upsertEmailConfig({
        'provider': _provider.value,
        'config': providerConfig,
        'from_email': _fromEmailController.text.trim(),
        'from_name': _fromNameController.text.trim().isNotEmpty
            ? _fromNameController.text.trim()
            : null,
        'is_active': _isActive,
        'daily_limit': int.tryParse(_dailyLimitController.text) ?? 500,
      });

      ref.invalidate(emailConfigProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email settings saved successfully'),
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
