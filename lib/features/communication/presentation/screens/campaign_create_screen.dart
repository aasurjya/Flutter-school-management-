import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/models/communication.dart';
import '../../providers/communication_provider.dart';
import '../widgets/channel_selector.dart';
import '../widgets/audience_picker.dart';
import '../widgets/template_preview.dart';

class CampaignCreateScreen extends ConsumerStatefulWidget {
  const CampaignCreateScreen({super.key});

  @override
  ConsumerState<CampaignCreateScreen> createState() =>
      _CampaignCreateScreenState();
}

class _CampaignCreateScreenState extends ConsumerState<CampaignCreateScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Template / Content
  CommunicationTemplate? _selectedTemplate;
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  // Step 2: Audience
  CampaignTargetType _targetType = CampaignTargetType.all;
  Map<String, dynamic> _targetFilter = {};

  // Step 3: Channels
  List<CommunicationChannel> _channels = [CommunicationChannel.inApp];

  // Step 4: Schedule
  bool _sendNow = true;
  DateTime? _scheduledAt;

  bool _isSending = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Campaign'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildStepIndicator(theme),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentStep = index),
        children: [
          _buildContentStep(theme),
          _buildAudienceStep(theme),
          _buildChannelStep(theme),
          _buildReviewStep(theme),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    const steps = ['Content', 'Audience', 'Channels', 'Review'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success
                        : isActive
                            ? AppColors.primary
                            : AppColors.borderLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.white : Colors.grey,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 4),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted
                          ? AppColors.success
                          : AppColors.borderLight,
                    ),
                  ),
                if (index == steps.length - 1) const Spacer(),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // Step 1: Content
  // ============================================================
  Widget _buildContentStep(ThemeData theme) {
    final templatesAsync = ref.watch(activeTemplatesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Campaign Content',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // Campaign name
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Campaign Name',
            hintText: 'e.g., Fee Reminder - March 2026',
          ),
        ),
        const SizedBox(height: 16),

        // Template selector
        Text('Use Template (Optional)',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        templatesAsync.when(
          data: (templates) {
            if (templates.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                    'No active templates found. You can type a custom message below.'),
              );
            }
            return DropdownButtonFormField<String>(
              value: _selectedTemplate?.id,
              decoration: const InputDecoration(
                hintText: 'Select a template...',
              ),
              items: templates.map((t) {
                return DropdownMenuItem(
                  value: t.id,
                  child: Text(
                    '${t.name} (${t.category.label})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (id) {
                final template = templates.firstWhere((t) => t.id == id);
                setState(() {
                  _selectedTemplate = template;
                  _subjectController.text = template.subject ?? '';
                  _bodyController.text = template.bodyTemplate;
                  if (_nameController.text.isEmpty) {
                    _nameController.text = template.name;
                  }
                });
              },
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('Failed to load templates'),
        ),
        const SizedBox(height: 16),

        // Subject
        TextFormField(
          controller: _subjectController,
          decoration: const InputDecoration(
            labelText: 'Subject',
            hintText: 'Enter message subject...',
          ),
        ),
        const SizedBox(height: 16),

        // Body
        TextFormField(
          controller: _bodyController,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Message Body',
            hintText: 'Type your message here...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  // ============================================================
  // Step 2: Audience
  // ============================================================
  Widget _buildAudienceStep(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AudiencePicker(
          selectedTargetType: _targetType,
          targetFilter: _targetFilter,
          onTargetTypeChanged: (type) {
            setState(() => _targetType = type);
          },
          onFilterChanged: (filter) {
            setState(() => _targetFilter = filter);
          },
        ),
      ],
    );
  }

  // ============================================================
  // Step 3: Channels & Schedule
  // ============================================================
  Widget _buildChannelStep(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Delivery Channels',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select one or more channels to deliver this campaign.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        ChannelSelector(
          selectedChannels: _channels,
          onChanged: (channels) {
            setState(() => _channels = channels);
          },
        ),
        const SizedBox(height: 24),

        // Schedule
        Text(
          'Delivery Schedule',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              RadioListTile<bool>(
                title: const Text('Send Now'),
                subtitle: const Text('Campaign will be sent immediately'),
                value: true,
                groupValue: _sendNow,
                onChanged: (v) => setState(() => _sendNow = v!),
                activeColor: AppColors.primary,
              ),
              const Divider(),
              RadioListTile<bool>(
                title: const Text('Schedule for Later'),
                subtitle: Text(
                  _scheduledAt != null
                      ? DateFormat('MMM d, yyyy - h:mm a')
                          .format(_scheduledAt!)
                      : 'Choose a date and time',
                ),
                value: false,
                groupValue: _sendNow,
                onChanged: (v) async {
                  setState(() => _sendNow = v!);
                  if (v == false) {
                    await _pickScheduleDateTime();
                  }
                },
                activeColor: AppColors.primary,
              ),
              if (!_sendNow) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickScheduleDateTime,
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text(
                      _scheduledAt != null
                          ? DateFormat('MMM d, yyyy - h:mm a')
                              .format(_scheduledAt!)
                          : 'Pick Date & Time',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Step 4: Review
  // ============================================================
  Widget _buildReviewStep(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Review Campaign',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // Summary card
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewRow(theme, 'Campaign Name',
                  _nameController.text.isNotEmpty ? _nameController.text : 'Untitled'),
              const Divider(height: 16),
              _buildReviewRow(theme, 'Target', _targetType.label),
              const Divider(height: 16),
              _buildReviewRow(
                theme,
                'Channels',
                _channels.map((c) => c.label).join(', '),
              ),
              const Divider(height: 16),
              _buildReviewRow(
                theme,
                'Schedule',
                _sendNow
                    ? 'Send Immediately'
                    : _scheduledAt != null
                        ? DateFormat('MMM d, yyyy - h:mm a')
                            .format(_scheduledAt!)
                        : 'Not set',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Message preview
        if (_bodyController.text.isNotEmpty && _selectedTemplate != null)
          TemplatePreview(template: _selectedTemplate!)
        else if (_bodyController.text.isNotEmpty)
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message Preview',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (_subjectController.text.isNotEmpty) ...[
                  Text(
                    'Subject: ${_subjectController.text}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    _bodyController.text,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildReviewRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSending ? null : _nextOrSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentStep == 3
                      ? (_sendNow ? AppColors.primary : AppColors.info)
                      : AppColors.primary,
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _currentStep == 3
                            ? (_sendNow
                                ? 'Send Campaign'
                                : 'Schedule Campaign')
                            : 'Next',
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _previousStep() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextOrSubmit() {
    if (_currentStep < 3) {
      // Validate current step
      if (_currentStep == 0 && _bodyController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a message body'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitCampaign();
    }
  }

  Future<void> _pickScheduleDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          _scheduledAt ?? now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submitCampaign() async {
    if (_bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message body is required'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_sendNow && _scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a schedule date and time'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final notifier = ref.read(campaignsNotifierProvider.notifier);

      final data = {
        'name': _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : 'Campaign ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
        'template_id': _selectedTemplate?.id,
        'subject': _subjectController.text.trim().isNotEmpty
            ? _subjectController.text.trim()
            : null,
        'body': _bodyController.text,
        'target_type': _targetType.value,
        'target_filter': _targetFilter,
        'channels': _channels.map((c) => c.value).toList(),
        'status': CampaignStatus.draft.value,
      };

      final campaign = await notifier.create(data);

      if (_sendNow) {
        await notifier.send(campaign.id);
      } else {
        await notifier.schedule(campaign.id, _scheduledAt!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _sendNow
                  ? 'Campaign sent successfully!'
                  : 'Campaign scheduled for ${DateFormat('MMM d, h:mm a').format(_scheduledAt!)}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
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
      if (mounted) setState(() => _isSending = false);
    }
  }
}
