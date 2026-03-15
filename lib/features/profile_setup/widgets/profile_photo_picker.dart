import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';

/// Circular avatar with an edit overlay that lets the user pick a photo
/// from the gallery or camera, uploads it to Supabase Storage, and
/// calls [onUploaded] with the public URL on success.
class ProfilePhotoPicker extends StatefulWidget {
  final String? currentUrl;
  final String storageBucket;
  final String storagePathPrefix;
  final ValueChanged<String> onUploaded;

  const ProfilePhotoPicker({
    super.key,
    this.currentUrl,
    this.storageBucket = 'avatars',
    required this.storagePathPrefix,
    required this.onUploaded,
  });

  @override
  State<ProfilePhotoPicker> createState() => _ProfilePhotoPickerState();
}

class _ProfilePhotoPickerState extends State<ProfilePhotoPicker> {
  final _picker = ImagePicker();
  File? _localFile;
  bool _uploading = false;

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked == null) return;
    setState(() {
      _localFile = File(picked.path);
      _uploading = true;
    });
    try {
      final ext = picked.path.split('.').last;
      final path =
          '${widget.storagePathPrefix}/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final client = Supabase.instance.client;
      await client.storage
          .from(widget.storageBucket)
          .upload(path, _localFile!, fileOptions: const FileOptions(upsert: true));
      final url =
          client.storage.from(widget.storageBucket).getPublicUrl(path);
      widget.onUploaded(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _uploading ? null : _showOptions,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: _localFile != null
                ? FileImage(_localFile!) as ImageProvider
                : (widget.currentUrl != null
                    ? NetworkImage(widget.currentUrl!)
                    : null),
            child: (_localFile == null && widget.currentUrl == null)
                ? const Icon(Icons.person_rounded,
                    size: 40, color: AppColors.primary)
                : null,
          ),
          if (_uploading)
            const CircularProgressIndicator()
          else
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
