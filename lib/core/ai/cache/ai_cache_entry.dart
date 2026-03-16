import '../models/ai_completion_response.dart';

/// A cached AI completion response with metadata.
class AICacheEntry {
  /// The cached response.
  final AICompletionResponse response;

  /// When this entry was created.
  final DateTime createdAt;

  /// Time-to-live for this entry.
  final Duration ttl;

  /// Number of times this entry has been served from cache.
  int hitCount;

  AICacheEntry({
    required this.response,
    required this.ttl,
    DateTime? createdAt,
    this.hitCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  /// True if this entry has expired.
  bool get isExpired =>
      DateTime.now().isAfter(createdAt.add(ttl));

  /// Increment hit count and return the response marked as cached.
  AICompletionResponse hit() {
    hitCount++;
    return response.asFromCache();
  }

  /// Serialize for SharedPreferences persistence.
  Map<String, dynamic> toJson() => {
        'text': response.text,
        'model': response.model,
        'tokensUsed': response.tokensUsed,
        'createdAt': createdAt.toIso8601String(),
        'ttlMs': ttl.inMilliseconds,
        'hitCount': hitCount,
      };

  /// Deserialize from SharedPreferences.
  factory AICacheEntry.fromJson(Map<String, dynamic> json) => AICacheEntry(
        response: AICompletionResponse(
          text: json['text'] as String,
          model: json['model'] as String,
          tokensUsed: json['tokensUsed'] as int? ?? 0,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        ttl: Duration(milliseconds: json['ttlMs'] as int),
        hitCount: json['hitCount'] as int? ?? 0,
      );
}
