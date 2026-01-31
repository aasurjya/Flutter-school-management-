import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/announcement.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../announcements/providers/announcement_provider.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(announcementsNotifierProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Announcements'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(announcementsNotifierProvider.notifier).loadAnnouncements(),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Published'),
              Tab(text: 'Drafts'),
            ],
          ),
        ),
        body: announcementsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(announcementsNotifierProvider.notifier).loadAnnouncements(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (announcements) {
            final published = announcements.where((a) => a.isPublished).toList();
            final drafts = announcements.where((a) => !a.isPublished).toList();

            return TabBarView(
              children: [
                _buildAnnouncementsListReal(published),
                _buildAnnouncementsListReal(drafts, isDraft: true),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createAnnouncement,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add),
          label: const Text('New'),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsListReal(List<Announcement> announcements, {bool isDraft = false}) {
    if (announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDraft ? Icons.drafts : Icons.campaign,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isDraft ? 'No drafts' : 'No published announcements',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.read(announcementsNotifierProvider.notifier).loadAnnouncements(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final announcement = announcements[index];
          return _AnnouncementCardReal(
            announcement: announcement,
            isDraft: isDraft,
            onPublish: () => _publishAnnouncement(announcement),
            onUnpublish: () => _unpublishAnnouncement(announcement),
            onPin: () => _pinAnnouncement(announcement),
            onUnpin: () => _unpinAnnouncement(announcement),
            onEdit: () => _editAnnouncement(announcement),
            onDelete: () => _deleteAnnouncement(announcement),
          );
        },
      ),
    );
  }

  Future<void> _publishAnnouncement(Announcement announcement) async {
    try {
      await ref.read(announcementsNotifierProvider.notifier).publishAnnouncement(announcement.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement published')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _unpublishAnnouncement(Announcement announcement) async {
    try {
      await ref.read(announcementsNotifierProvider.notifier).unpublishAnnouncement(announcement.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement unpublished')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _pinAnnouncement(Announcement announcement) async {
    try {
      await ref.read(announcementsNotifierProvider.notifier).pinAnnouncement(announcement.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement pinned')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _unpinAnnouncement(Announcement announcement) async {
    try {
      await ref.read(announcementsNotifierProvider.notifier).unpinAnnouncement(announcement.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement unpinned')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _editAnnouncement(Announcement announcement) {
    // TODO: Navigate to edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit coming soon')),
    );
  }

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Are you sure you want to delete "${announcement.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(announcementsNotifierProvider.notifier).deleteAnnouncement(announcement.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _createAnnouncement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateAnnouncementSheet(),
    );
  }
}

class _AnnouncementCardReal extends StatelessWidget {
  final Announcement announcement;
  final bool isDraft;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;
  final VoidCallback onPin;
  final VoidCallback onUnpin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AnnouncementCardReal({
    required this.announcement,
    required this.isDraft,
    required this.onPublish,
    required this.onUnpublish,
    required this.onPin,
    required this.onUnpin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (announcement.isHighPriority || announcement.isUrgent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.priority_high, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text(announcement.priorityDisplay, style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(announcement.priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        announcement.targetRoles.join(', ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getPriorityColor(announcement.priority),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit': onEdit(); break;
                          case 'delete': onDelete(); break;
                          case 'publish': onPublish(); break;
                          case 'unpublish': onUnpublish(); break;
                          case 'pin': onPin(); break;
                          case 'unpin': onUnpin(); break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                        if (isDraft)
                          const PopupMenuItem(value: 'publish', child: Row(children: [Icon(Icons.publish, size: 18), SizedBox(width: 8), Text('Publish')])),
                        if (!isDraft)
                          const PopupMenuItem(value: 'unpublish', child: Row(children: [Icon(Icons.unpublished, size: 18), SizedBox(width: 8), Text('Unpublish')])),
                        if (!announcement.isHighPriority)
                          const PopupMenuItem(value: 'pin', child: Row(children: [Icon(Icons.priority_high, size: 18), SizedBox(width: 8), Text('High Priority')])),
                        if (announcement.isHighPriority)
                          const PopupMenuItem(value: 'unpin', child: Row(children: [Icon(Icons.low_priority, size: 18), SizedBox(width: 8), Text('Normal Priority')])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  announcement.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  announcement.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(announcement.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    if (announcement.createdByName != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.person, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        announcement.createdByName!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return AppColors.error;
      case 'urgent': return AppColors.error;
      case 'normal': return AppColors.info;
      case 'low': return AppColors.success;
      default: return AppColors.primary;
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> announcement;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPublish;

  const _AnnouncementCard({
    required this.announcement,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final category = announcement['category'] as String;
    final isPinned = announcement['isPinned'] as bool;
    final createdAt = announcement['createdAt'] as DateTime;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPinned)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.push_pin, size: 14, color: AppColors.warning),
                    SizedBox(width: 6),
                    Text('Pinned', style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getCategoryLabel(category),
                          style: TextStyle(
                            fontSize: 11,
                            color: _getCategoryColor(category),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit': onEdit(); break;
                            case 'delete': onDelete(); break;
                            case 'publish': onPublish?.call(); break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                          if (onPublish != null)
                            const PopupMenuItem(value: 'publish', child: Row(children: [Icon(Icons.publish, size: 18), SizedBox(width: 8), Text('Publish')])),
                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    announcement['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    announcement['content'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.person, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        announcement['createdBy'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'holiday': return AppColors.success;
      case 'event': return AppColors.info;
      case 'fee': return AppColors.warning;
      case 'meeting': return AppColors.secondary;
      case 'exam': return AppColors.error;
      default: return AppColors.primary;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'holiday': return 'Holiday';
      case 'event': return 'Event';
      case 'fee': return 'Fee';
      case 'meeting': return 'Meeting';
      case 'exam': return 'Exam';
      default: return category;
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _AnnouncementDetailSheet extends StatelessWidget {
  final Map<String, dynamic> announcement;

  const _AnnouncementDetailSheet({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final targetAudience = announcement['targetAudience'] as List;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    announcement['title'],
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement['content'],
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM d, yyyy h:mm a').format(announcement['createdAt'] as DateTime),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text('Posted by ${announcement['createdBy']}', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          children: targetAudience.map((a) => Chip(
                            label: Text(a.toString().toUpperCase(), style: const TextStyle(fontSize: 10)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateAnnouncementSheet extends StatefulWidget {
  final Map<String, dynamic>? announcement;

  const _CreateAnnouncementSheet({this.announcement});

  @override
  State<_CreateAnnouncementSheet> createState() => _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState extends State<_CreateAnnouncementSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String _category = 'general';
  Set<String> _targetAudience = {'all'};
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement?['title']);
    _contentController = TextEditingController(text: widget.announcement?['content']);
    if (widget.announcement != null) {
      _category = widget.announcement!['category'];
      _targetAudience = Set<String>.from(widget.announcement!['targetAudience']);
      _isPinned = widget.announcement!['isPinned'];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.announcement != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(
                  isEditing ? 'Edit Announcement' : 'New Announcement',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(labelText: 'Content *', border: OutlineInputBorder(), alignLabelWithHint: true),
                      maxLines: 5,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'general', child: Text('General')),
                        DropdownMenuItem(value: 'holiday', child: Text('Holiday')),
                        DropdownMenuItem(value: 'event', child: Text('Event')),
                        DropdownMenuItem(value: 'fee', child: Text('Fee')),
                        DropdownMenuItem(value: 'meeting', child: Text('Meeting')),
                        DropdownMenuItem(value: 'exam', child: Text('Exam')),
                      ],
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                    const SizedBox(height: 16),
                    const Text('Target Audience', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildAudienceChip('all', 'All'),
                        _buildAudienceChip('students', 'Students'),
                        _buildAudienceChip('parents', 'Parents'),
                        _buildAudienceChip('teachers', 'Teachers'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Pin Announcement'),
                      subtitle: const Text('Pinned announcements appear at the top'),
                      value: _isPinned,
                      onChanged: (v) => setState(() => _isPinned = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _save(false),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            child: const Text('Save as Draft'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _save(true),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
                            child: const Text('Publish'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceChip(String value, String label) {
    final isSelected = _targetAudience.contains(value);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (value == 'all') {
            _targetAudience = selected ? {'all'} : {};
          } else {
            _targetAudience.remove('all');
            if (selected) {
              _targetAudience.add(value);
            } else {
              _targetAudience.remove(value);
            }
          }
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  void _save(bool publish) {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(publish ? 'Announcement published' : 'Draft saved'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
