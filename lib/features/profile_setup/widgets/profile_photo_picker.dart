import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';

/// Returns the MIME type inferred from the file's magic bytes, or null if the
/// bytes do not match a supported image format (JPEG, PNG, WebP).
String? _detectImageMime(Uint8List bytes) {
  if (bytes.length < 12) return null;
  // JPEG: FF D8 FF
  if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  // PNG: 89 50 4E 47 0D 0A 1A 0A
  if (bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  // WebP: 52 49 46 46 ?? ?? ?? ?? 57 45 42 50
  if (bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  return null;
}

/// Validates that [prefix] contains only safe path characters.
/// Throws [ArgumentError] if the prefix contains `..` or any character
/// outside `[a-zA-Z0-9_\-/]` to prevent path traversal attacks.
void _validateStoragePathPrefix(String prefix) {
  if (prefix.contains('..')) {
    throw ArgumentError('storagePathPrefix must not contain ".."');
  }
  final safe = RegExp(r'^[a-zA-Z0-9_\-/]+$');
  if (!safe.hasMatch(prefix)) {
    throw ArgumentError(
      'storagePathPrefix contains illegal characters. '
      'Only [a-zA-Z0-9_\\-/] are permitted.',
    );
  }
}

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

    // --- Path traversal guard (Step 3.5) ---
    try {
      _validateStoragePathPrefix(widget.storagePathPrefix);
    } on ArgumentError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid upload path: ${e.message}')),
        );
      }
      return;
    }

    // --- Magic-byte MIME check (Step 3) ---
    // Read only the first 12 bytes to detect the true format regardless of
    // the file extension supplied by the client (prevents extension spoofing).
    final fileRef = File(picked.path);
    final Uint8List header;
    try {
      final raf = await fileRef.open();
      header = await raf.read(12);
      await raf.close();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read the selected file.')),
        );
      }
      return;
    }

    final detectedMime = _detectImageMime(header);
    if (detectedMime == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only JPEG, PNG, or WebP images are supported.'),
          ),
        );
      }
      return;
    }

    setState(() {
      _localFile = fileRef;
      _uploading = true;
    });

    try {
      // Derive extension from the validated MIME type — never from the
      // client-supplied file path — so the stored filename matches reality.
      final ext = switch (detectedMime) {
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
        _ => 'bin',
      };
      final path =
          '${widget.storagePathPrefix}/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final client = Supabase.instance.client;
      await client.storage.from(widget.storageBucket).upload(
            path,
            fileRef,
            fileOptions: FileOptions(
              upsert: true,
              contentType: detectedMime,
            ),
          );
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
