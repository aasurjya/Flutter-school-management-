import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_completion_request.dart';
import '../models/ai_completion_response.dart';
import 'ai_cache_entry.dart';
import 'ai_cache_key.dart';

/// In-memory LRU cache for AI responses, with optional SharedPreferences
/// persistence for surviving app restarts.
///
/// Usage:
/// ```dart
/// final cache = AICache(maxEntries: 200);
/// await cache.loadFromDisk();  // optional — restores persisted entries
/// ```
class AICache {
  /// Default TTL when none is specified (1 hour).
  static const defaultTtl = Duration(hours: 1);

  /// SharedPreferences key prefix.
  static const _spPrefix = 'ai_cache_';

  final int maxEntries;
  final Map<String, AICacheEntry> _entries = {};

  /// Tracks access order for LRU eviction. Most-recently-used is last.
  final List<String> _accessOrder = [];

  AICache({this.maxEntries = 200});

  /// Look up a cached response. Returns null on miss or expired entry.
  AICompletionResponse? get(AICompletionRequest request, String providerId) {
    final key = AICacheKey.compute(request, providerId);
    final entry = _entries[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _entries.remove(key);
      _accessOrder.remove(key);
      return null;
    }

    // Move to most-recently-used position.
    _accessOrder.remove(key);
    _accessOrder.add(key);

    return entry.hit();
  }

  /// Store a response in the cache.
  void put(
    AICompletionRequest request,
    String providerId,
    AICompletionResponse response, {
    Duration? ttl,
  }) {
    final key = AICacheKey.compute(request, providerId);

    _entries[key] = AICacheEntry(
      response: response,
      ttl: ttl ?? defaultTtl,
    );

    _accessOrder.remove(key);
    _accessOrder.add(key);

    _evictIfNeeded();
  }

  /// Invalidate all entries whose cache key contains [substring].
  ///
  /// Used for smart invalidation — e.g. when attendance data changes,
  /// call `invalidateMatching('attendance')`.
  int invalidateMatching(String substring) {
    final keysToRemove = _entries.keys
        .where((k) {
          final entry = _entries[k];
          // Check if the response text or model contains the substring,
          // but more practically we match on the cache key itself which
          // embeds the prompt text.
          return k.contains(substring) ||
              (entry?.response.text.toLowerCase().contains(substring.toLowerCase()) ?? false);
        })
        .toList();

    for (final key in keysToRemove) {
      _entries.remove(key);
      _accessOrder.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      developer.log(
        'Invalidated ${keysToRemove.length} cache entries matching "$substring"',
        name: 'AICache',
      );
    }

    return keysToRemove.length;
  }

  /// Remove all entries.
  void clear() {
    _entries.clear();
    _accessOrder.clear();
  }

  /// Number of entries currently in cache.
  int get length => _entries.length;

  /// Total cache hit count across all entries.
  int get totalHits =>
      _entries.values.fold(0, (sum, e) => sum + e.hitCount);

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Load persisted cache entries from SharedPreferences.
  Future<void> loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_spPrefix));

      for (final spKey in keys) {
        final jsonStr = prefs.getString(spKey);
        if (jsonStr == null) continue;

        try {
          final entry = AICacheEntry.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>,
          );
          if (!entry.isExpired) {
            final cacheKey = spKey.substring(_spPrefix.length);
            _entries[cacheKey] = entry;
            _accessOrder.add(cacheKey);
          } else {
            // Clean up expired persisted entries.
            await prefs.remove(spKey);
          }
        } catch (_) {
          // Corrupted entry — remove it.
          await prefs.remove(spKey);
        }
      }

      _evictIfNeeded();

      developer.log(
        'Loaded ${_entries.length} cached AI responses from disk',
        name: 'AICache',
      );
    } catch (e) {
      developer.log(
        'Failed to load AI cache from disk',
        name: 'AICache',
        error: e,
      );
    }
  }

  /// Persist current cache to SharedPreferences.
  Future<void> saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove old entries first.
      final oldKeys = prefs.getKeys().where((k) => k.startsWith(_spPrefix));
      for (final key in oldKeys) {
        await prefs.remove(key);
      }

      // Write current entries.
      for (final entry in _entries.entries) {
        if (!entry.value.isExpired) {
          await prefs.setString(
            '$_spPrefix${entry.key}',
            jsonEncode(entry.value.toJson()),
          );
        }
      }
    } catch (e) {
      developer.log(
        'Failed to save AI cache to disk',
        name: 'AICache',
        error: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // LRU eviction
  // ---------------------------------------------------------------------------

  void _evictIfNeeded() {
    while (_entries.length > maxEntries && _accessOrder.isNotEmpty) {
      final lruKey = _accessOrder.removeAt(0);
      _entries.remove(lruKey);
    }
  }
}
