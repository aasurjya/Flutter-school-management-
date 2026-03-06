import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Holds the global RepaintBoundary key used to capture the current screen.
///
/// Usage:
///   Wrap the main content area with:
///     RepaintBoundary(key: ScreenCaptureService.repaintKey, child: ...)
///
///   Then call:
///     final base64 = await ScreenCaptureService.captureBase64();
class ScreenCaptureService {
  ScreenCaptureService._();

  /// The global key to attach to the RepaintBoundary.
  static final GlobalKey repaintKey = GlobalKey();

  /// Captures the current screen content and returns it as a base64 PNG string.
  /// Returns null if capture fails (boundary not attached, etc.).
  static Future<String?> captureBase64({double pixelRatio = 1.5}) async {
    try {
      final context = repaintKey.currentContext;
      if (context == null) return null;

      final boundary =
          context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      return base64Encode(byteData.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }
}
