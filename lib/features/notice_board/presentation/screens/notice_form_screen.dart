import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/notice_board.dart';
import '../../providers/notice_board_provider.dart';

class NoticeFormScreen extends ConsumerStatefulWidget {
  final Notice? existingNotice;

  const NoticeFormScreen({super.key, this.existingNotice});

  @override
  ConsumerState<NoticeFormScreen> createState() => _NoticeFormScreenState();
}

class _NoticeFormScreenState extends ConsumerState<NoticeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late NoticeCategory _category;
  late NoticeAudience _audience;
  late bool _isPinned;
  bool _isSaving = false;

  bool get _isEditing => widget.existingNotice != null;

  @override
  void initState() {
    super.initState();
    final n = widget.existingNotice;
    _titleCtrl = TextEditingController(text: n?.title ?? '');
    _bodyCtrl = TextEditingController(text: n?.body ?? '');
    _category = n?.category ?? NoticeCategory.general;
    _audience = n?.audience ?? NoticeAudience.all;
    _isPinned = n?.isPinned ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(noticeBoardRepositoryProvider);
      final data = {
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'category': _category.value,
        'audience': _audience.value,
        'is_pinned': _isPinned,
        'is_published': true,
      };

      if (_isEditing) {
        await repo.updateNotice(widget.existingNotice!.id, data);
      } else {
        await repo.createNotice(data);
      }
      ref.invalidate(noticesProvider);
      ref.invalidate(pinnedNoticesProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Notice' : 'Post Notice'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isEditing ? 'Save' : 'Post',
                    style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Title *', border: OutlineInputBorder()),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                  labelText: 'Content *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true),
              maxLines: 6,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<NoticeCategory>(
              value: _category,
              decoration: const InputDecoration(
                  labelText: 'Category', border: OutlineInputBorder()),
              items: NoticeCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<NoticeAudience>(
              value: _audience,
              decoration: const InputDecoration(
                  labelText: 'Audience', border: OutlineInputBorder()),
              items: NoticeAudience.values
                  .map((a) => DropdownMenuItem(value: a, child: Text(a.label)))
                  .toList(),
              onChanged: (v) => setState(() => _audience = v!),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Pin to top'),
              value: _isPinned,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _isPinned = v),
            ),
          ],
        ),
      ),
    );
  }
}
