import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/supabase_provider.dart';
import 'quota_state.dart';

/// Thin typed wrapper around the `ai-gateway` Supabase edge function.
///
/// The gateway is the single entry point for every LLM call in production —
/// API keys live in Supabase function secrets, never in the Flutter APK.
/// See `supabase/functions/ai-gateway/index.ts` for the server-side pipeline
/// and `supabase/migrations/00055_ai_governance.sql` for the backing tables.
class AiGatewayClient {
  final SupabaseClient _client;
  final QuotaController _quota;

  AiGatewayClient(this._client, this._quota);

  /// Send a single-turn completion request through the gateway.
  ///
  /// On 429 quota-reached the gateway returns structured data; this method
  /// throws [AiGatewayQuotaException] so callers can surface a "quota reached"
  /// banner instead of treating it as a generic error.
  Future<AiGatewayResult> complete({
    required String featureType,
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 1024,
    String responseFormat = 'text',
    String? cacheKeyHint,
    bool skipCache = false,
  }) async {
    final invokeResponse = await _client.functions.invoke(
      'ai-gateway',
      body: <String, dynamic>{
        'feature_type': featureType,
        'system_prompt': systemPrompt,
        'user_prompt': userPrompt,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'response_format': responseFormat,
        if (cacheKeyHint != null) 'cache_key_hint': cacheKeyHint,
        if (skipCache) 'skip_cache': true,
      },
    );

    final status = invokeResponse.status;
    final raw = invokeResponse.data;

    final body = _coerceJsonMap(raw);

    if (status == 200 && body['text'] is String) {
      final quota = _parseQuota(body['quota']);
      if (quota != null) _quota.updateFromServer(quota);
      return AiGatewayResult.fromJson(body);
    }

    if (status == 429 || status == 413) {
      final quota = _parseQuota(body['quota']);
      if (quota != null) _quota.updateFromServer(quota);
      final reason = (body['reason'] as String?) ?? 'blocked';
      _quota.notifyBlocked(featureType: featureType, reason: reason);
      throw AiGatewayQuotaException(
        reason: reason,
        featureType: featureType,
        quota: quota,
      );
    }

    final errorMsg = (body['error'] as String?) ?? 'unknown';
    developer.log(
      'ai-gateway failed: status=$status error=$errorMsg',
      name: 'AiGatewayClient',
    );
    throw AiGatewayException(
      status: status,
      reason: errorMsg,
      featureType: featureType,
    );
  }

  Map<String, dynamic> _coerceJsonMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } catch (_) {/* fall through */}
    }
    return const {};
  }

  QuotaSnapshot? _parseQuota(dynamic raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();
    return QuotaSnapshot(
      usedUsd: (map['used_usd'] as num?)?.toDouble() ?? 0,
      budgetUsd: (map['budget_usd'] as num?)?.toDouble() ?? 0,
      callsUsed: (map['calls_used'] as int?) ?? 0,
      callsLimit: (map['calls_limit'] as int?) ?? 0,
    );
  }
}

/// Successful gateway response.
class AiGatewayResult {
  final String text;
  final int tokensIn;
  final int tokensOut;
  final double costUsd;
  final bool cached;
  final String provider;
  final bool fallbackUsed;

  const AiGatewayResult({
    required this.text,
    required this.tokensIn,
    required this.tokensOut,
    required this.costUsd,
    required this.cached,
    required this.provider,
    required this.fallbackUsed,
  });

  factory AiGatewayResult.fromJson(Map<String, dynamic> json) {
    return AiGatewayResult(
      text: json['text'] as String,
      tokensIn: (json['tokens_in'] as int?) ?? 0,
      tokensOut: (json['tokens_out'] as int?) ?? 0,
      costUsd: (json['cost_usd'] as num?)?.toDouble() ?? 0,
      cached: (json['cached'] as bool?) ?? false,
      provider: (json['provider'] as String?) ?? 'unknown',
      fallbackUsed: (json['fallback_used'] as bool?) ?? false,
    );
  }
}

/// Thrown when the gateway blocks a call for any quota reason
/// (feature disabled, hard cap reached, burst limit, estimated cost over cap).
class AiGatewayQuotaException implements Exception {
  final String reason;
  final String featureType;
  final QuotaSnapshot? quota;

  const AiGatewayQuotaException({
    required this.reason,
    required this.featureType,
    this.quota,
  });

  @override
  String toString() =>
      'AiGatewayQuotaException(reason=$reason, feature=$featureType)';
}

/// Thrown for any other non-200, non-429 gateway failure.
class AiGatewayException implements Exception {
  final int status;
  final String reason;
  final String featureType;

  const AiGatewayException({
    required this.status,
    required this.reason,
    required this.featureType,
  });

  @override
  String toString() =>
      'AiGatewayException(status=$status, reason=$reason, feature=$featureType)';
}

/// Riverpod provider for the gateway client.
final aiGatewayClientProvider = Provider<AiGatewayClient>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final quota = ref.watch(quotaControllerProvider.notifier);
  return AiGatewayClient(supabase, quota);
});
