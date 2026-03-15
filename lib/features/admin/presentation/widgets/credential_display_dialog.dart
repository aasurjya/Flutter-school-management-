import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Displays generated login credentials once after admin creates a user.
///
/// Shown as a non-dismissible dialog so the admin is forced to acknowledge
/// the credentials before they disappear. Provides per-field copy buttons
/// and a "Copy All" action for convenience.
class CredentialDisplayDialog extends StatelessWidget {
  final String fullName;
  final String email;
  final String password;
  final String role;

  const CredentialDisplayDialog({
    super.key,
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
  });

  /// Convenience constructor to show the dialog imperatively.
  static Future<void> show(
    BuildContext context, {
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CredentialDisplayDialog(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$fullName created',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WarningBanner(),
          const SizedBox(height: 16),
          _CredentialRow(label: 'Role', value: role.toUpperCase(), canCopy: false),
          const SizedBox(height: 8),
          _CredentialRow(label: 'Email / Username', value: email),
          const SizedBox(height: 8),
          _CredentialRow(label: 'Password', value: password),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _copyAll(context),
          child: const Text('Copy All'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  void _copyAll(BuildContext context) {
    Clipboard.setData(
      ClipboardData(text: 'Role: $role\nEmail: $email\nPassword: $password'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credentials copied to clipboard')),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Save these credentials now — the password won't be shown again.",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  final String label;
  final String value;
  final bool canCopy;

  const _CredentialRow({
    required this.label,
    required this.value,
    this.canCopy = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              theme.textTheme.labelSmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (canCopy)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$label copied')),
                    );
                  },
                  child: Icon(
                    Icons.copy,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
