import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/ai_completion_request.dart';

/// Generates a deterministic cache key from a completion request.
///
/// The key is a SHA-256 hash of the concatenated system prompt, user prompt,
/// provider ID, and temperature. This ensures identical requests produce the
/// same key regardless of when they are made.
class AICacheKey {
  /// Compute a hex-encoded SHA-256 cache key.
  static String compute(AICompletionRequest request, String providerId) {
    final buffer = StringBuffer()
      ..write(providerId)
      ..write('|')
      ..write(request.temperature.toStringAsFixed(2))
      ..write('|')
      ..write(request.maxTokens)
      ..write('|')
      ..write(request.responseFormat ?? '')
      ..write('|');

    for (final msg in request.messages) {
      buffer
        ..write(msg.role.name)
        ..write(':')
        ..write(msg.content)
        ..write('|');
      // Exclude imageBase64 from cache key — images change the request
      // semantics but are too large to hash efficiently.
    }

    final bytes = utf8.encode(buffer.toString());
    return sha256.convert(bytes).toString();
  }
}
