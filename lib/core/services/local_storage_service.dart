import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local storage service
/// Note: Isar is disabled on web as it doesn't support the platform.
/// On web, this service provides stub implementations.
class LocalStorageService {
  static bool _initialized = false;

  /// Initialize local storage
  /// On web, this is a no-op since Isar doesn't support web.
  static Future<void> initialize() async {
    if (_initialized) return;
    
    if (kIsWeb) {
      // Isar doesn't support web - skip initialization
      debugPrint('LocalStorageService: Skipping Isar on web platform');
      _initialized = true;
      return;
    }
    
    // For mobile/desktop, we would initialize Isar here
    // But for now, we'll skip it to avoid the web compilation issue
    // TODO: Re-enable Isar for mobile builds with conditional imports
    _initialized = true;
  }

  /// Close database
  static Future<void> close() async {
    // No-op on web
  }

  /// Clear all data (for logout)
  static Future<void> clearAll() async {
    // No-op on web
  }

  /// Get pending sync count
  static Future<int> getPendingSyncCount() async {
    return 0; // No offline sync on web
  }
}

/// Debug print helper
void debugPrint(String message) {
  if (kIsWeb || true) {
    // ignore: avoid_print
    print(message);
  }
}
