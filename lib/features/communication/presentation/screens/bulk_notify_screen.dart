import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/whatsapp_provider.dart';
import '../../providers/communication_provider.dart';

enum _SendTarget { allStudents, allParents, specificClass, specificSection }

enum _SendChannel { whatsapp, sms, both }

class BulkNotifyScreen extends ConsumerStatefulWidget {
  const BulkNotifyScreen({super.key});

  @override
  ConsumerState<BulkNotifyScreen> createState() => _BulkNotifyScreenState();
}

class _BulkNotifyScreenState extends ConsumerState<BulkNotifyScreen> {
  _SendTarget _target = _SendTarget.allParents;
  _SendChannel _channel = _SendChannel.sms;

  final _messageCtrl = TextEditingController();
  String? _selectedTemplateId;
  bool _useTemplate = false;
  bool _sending = false;

  // Simple class/section pickers (demo values)
  final List<String> _classes = [
    'Class 1', 'Class 2', 'Class 3', 'Class 4',
    'Class 5', 'Class 6', 'Class 7', 'Class 8',
    'Class 9', 'Class 10', 'Class 11', 'Class 12',
  ];
  String? _selectedClass;
  String? _selectedSection;
  final List<String> _sections = ['A', 'B', 'C', 'D'];

  static const int _smsCharLimit = 160;

  int get _charCount => _messageCtrl.text.length;
  int get _recipientCount {
    switch (_target) {
      case _SendTarget.allStudents:
        return 480;
      case _SendTarget.allParents:
        return 512;
      case _SendTarget.specificClass:
        return _selectedClass != null ? 40 : 0;
      case _SendTarget.specificSection:
        return (_selectedClass != null && _selectedSection != null) ? 10 : 0;
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templatesAsync = ref.watch(activeTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Notification'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Send To ───────────────────────────────────────────
          const _SectionLabel(label: 'Send To'),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: _SendTarget.values.map((t) {
                return ListTile(
                  dense: true,
                  leading: _RadioDot<_SendTarget>(
                    value: t,
                    groupValue: _target,
                    activeColor: AppColors.primary,
                  ),
                  title: Text(_targetLabel(t)),
                  onTap: () => setState(() {
                    _target = t;
                    _selectedClass = null;
                    _selectedSection = null;
                  }),
                );
              }).toList(),
            ),
          ),

          // Class / Section pickers
          if (_target == _SendTarget.specificClass ||
              _target == _SendTarget.specificSection) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedClass,
              decoration: const InputDecoration(labelText: 'Select Class'),
              items: _classes
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedClass = v;
                _selectedSection = null;
              }),
            ),
          ],
          if (_target == _SendTarget.specificSection &&
              _selectedClass != null) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedSection,
              decoration: const InputDecoration(labelText: 'Select Section'),
              items: _sections
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSection = v),
            ),
          ],

          const SizedBox(height: 20),

          // ── Channel ───────────────────────────────────────────
          const _SectionLabel(label: 'Channel'),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: _SendChannel.values.map((ch) {
                return ListTile(
                  dense: true,
                  leading: _RadioDot<_SendChannel>(
                    value: ch,
                    groupValue: _channel,
                    activeColor: AppColors.primary,
                  ),
                  title: Row(
                    children: [
                      Icon(
                        _channelIcon(ch),
                        size: 18,
                        color: _channelColor(ch),
                      ),
                      const SizedBox(width: 8),
                      Text(_channelLabel(ch)),
                    ],
                  ),
                  onTap: () => setState(() => _channel = ch),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // ── Message ───────────────────────────────────────────
          Row(
            children: [
              const _SectionLabel(label: 'Message'),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    setState(() => _useTemplate = !_useTemplate),
                child: Text(_useTemplate ? 'Custom Text' : 'Use Template'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_useTemplate) ...[
            templatesAsync.when(
              data: (templates) {
                if (templates.isEmpty) {
                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No active templates found.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  );
                }
                return GlassCard(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: templates.map((t) {
                      return ListTile(
                        dense: true,
                        leading: _RadioDot<String>(
                          value: t.id,
                          groupValue: _selectedTemplateId ?? '',
                          activeColor: AppColors.primary,
                        ),
                        title: Text(t.name),
                        subtitle: Text(
                          t.bodyTemplate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                        onTap: () => setState(() {
                          _selectedTemplateId = t.id;
                          _messageCtrl.text = t.bodyTemplate;
                        }),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ] else ...[
            TextFormField(
              controller: _messageCtrl,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Type your message here...',
                alignLabelWithHint: true,
                suffixIcon: _channel != _SendChannel.whatsapp
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 4),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            '$_charCount / $_smsCharLimit',
                            style: TextStyle(
                              fontSize: 11,
                              color: _charCount > _smsCharLimit
                                  ? AppColors.error
                                  : AppColors.textTertiaryLight,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Preview panel ─────────────────────────────────────
          const _SectionLabel(label: 'Preview'),
          const SizedBox(height: 10),
          _PreviewPanel(
            channel: _channel,
            message: _messageCtrl.text,
            recipientCount: _recipientCount,
          ),

          const SizedBox(height: 24),

          // ── Recipient count badge ─────────────────────────────
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '$_recipientCount recipients',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Action buttons ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _schedule,
                  icon: const Icon(Icons.schedule_outlined),
                  label: const Text('Schedule'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _sendNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  label: const Text(
                    'Send Now',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _sendNow() async {
    final msg = _messageCtrl.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_recipientCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a target audience first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      // In production this would call an Edge Function or RPC.
      // Here we log a representative entry.
      final repo = ref.read(whatsappRepositoryProvider);
      await repo.sendTestMessage(
        channel: _channel == _SendChannel.whatsapp
            ? 'whatsapp'
            : _channel == _SendChannel.sms
                ? 'sms'
                : 'sms',
        phone: 'bulk',
        message: msg,
      );

      ref.invalidate(notificationLogsProvider);
      ref.invalidate(deliveryStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification queued for $_recipientCount recipients',
            ),
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
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _schedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Scheduled for ${date.day}/${date.month}/${date.year} at ${time.format(context)}',
        ),
        backgroundColor: AppColors.info,
      ),
    );
  }

  static String _targetLabel(_SendTarget t) {
    switch (t) {
      case _SendTarget.allStudents:
        return 'All Students';
      case _SendTarget.allParents:
        return 'All Parents';
      case _SendTarget.specificClass:
        return 'Specific Class';
      case _SendTarget.specificSection:
        return 'Specific Section';
    }
  }

  static String _channelLabel(_SendChannel ch) {
    switch (ch) {
      case _SendChannel.whatsapp:
        return 'WhatsApp';
      case _SendChannel.sms:
        return 'SMS';
      case _SendChannel.both:
        return 'WhatsApp + SMS';
    }
  }

  static IconData _channelIcon(_SendChannel ch) {
    switch (ch) {
      case _SendChannel.whatsapp:
        return Icons.chat_outlined;
      case _SendChannel.sms:
        return Icons.sms_outlined;
      case _SendChannel.both:
        return Icons.forum_outlined;
    }
  }

  static Color _channelColor(_SendChannel ch) {
    switch (ch) {
      case _SendChannel.whatsapp:
        return const Color(0xFF25D366);
      case _SendChannel.sms:
        return AppColors.info;
      case _SendChannel.both:
        return AppColors.primary;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _RadioDot<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final Color activeColor;

  const _RadioDot({
    super.key,
    required this.value,
    required this.groupValue,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? activeColor : const Color(0xFF9CA3AF),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor,
                ),
              ),
            )
          : null,
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  final _SendChannel channel;
  final String message;
  final int recipientCount;

  const _PreviewPanel({
    required this.channel,
    required this.message,
    required this.recipientCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = message.trim().isEmpty;

    Color borderColor;
    Color iconColor;
    IconData icon;
    String channelLabel;

    switch (channel) {
      case _SendChannel.whatsapp:
        borderColor = const Color(0xFF25D366);
        iconColor = const Color(0xFF25D366);
        icon = Icons.chat_outlined;
        channelLabel = 'WhatsApp';
        break;
      case _SendChannel.sms:
        borderColor = AppColors.info;
        iconColor = AppColors.info;
        icon = Icons.sms_outlined;
        channelLabel = 'SMS';
        break;
      case _SendChannel.both:
        borderColor = AppColors.primary;
        iconColor = AppColors.primary;
        icon = Icons.forum_outlined;
        channelLabel = 'WhatsApp + SMS';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                channelLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$recipientCount recipients',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              isEmpty ? 'Message preview will appear here...' : message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isEmpty
                    ? AppColors.textTertiaryLight
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
