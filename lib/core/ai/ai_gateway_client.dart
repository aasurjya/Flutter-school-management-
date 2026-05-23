import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../net/idempotency.dart';
import '../net/retry.dart';

/// Result returned by the gateway. The Stage 1 `AITextResult` shape is kept
/// elsewhere; this is the lower-level wire model.
class AiGatewayResult {
  final String text;
  final String model;
  final String status;
  final bool isLLMGenerated;
  final bool isFromCache;
  final int? tokensIn;
  final int? tokensOut;
  final int? latencyMs;

  const AiGatewayResult({
    required this.text,
    required this.model,
    required this.status,
    required this.isLLMGenerated,
    required this.isFromCache,
    this.tokensIn,
    this.tokensOut,
    this.latencyMs,
  });
}

/// Thrown when the gateway refuses a call because the tenant's daily budget
/// is exhausted. The UI can show the existing near-budget banner on the
/// admin AI usage card.
class AiGatewayQuotaException implements Exception {
  final String message;
  const AiGatewayQuotaException(this.message);
  @override
  String toString() => 'AiGatewayQuotaException: $message';
}

/// Thrown when the gateway walked the full model chain and every model
/// failed. The caller's fallback string is the right thing to show.
class AiGatewayExhaustedException implements Exception {
  final String lastModel;
  const AiGatewayExhaustedException(this.lastModel);
  @override
  String toString() =>
      'AiGatewayExhaustedException: all models in chain failed (last: $lastModel)';
}

/// Thrown for other gateway transport errors (5xx, network, malformed
/// response). [retryNetwork] handles transient retries; this surfaces only
/// when retries exhaust.
class AiGatewayTransportException implements Exception {
  final int? statusCode;
  final String message;
  const AiGatewayTransportException(this.message, {this.statusCode});
  @override
  String toString() =>
      'AiGatewayTransportException(${statusCode ?? '?'}): $message';
}

/// HTTP client for the `ai-gateway` Supabase edge function.
///
/// Adds:
/// • Auto idempotency key generation (one UUID per logical call; retries
///   reuse it so the gateway dedupes on (tenant_id, idempotency_key)).
/// • [retryNetwork] wrapping for transient 5xx / timeout failures.
/// • Typed exceptions for quota / exhausted / transport — UI can branch.
///
/// Construction model: one client per app session. Use [AiGatewayClient.fromSupabase]
/// to derive the gateway URL automatically from the Supabase client config.
class AiGatewayClient {
  final Uri _endpoint;
  final http.Client _http;
  final String Function() _bearerToken;

  AiGatewayClient({
    required Uri endpoint,
    required String Function() bearerToken,
    http.Client? httpClient,
  })  : _endpoint = endpoint,
        _http = httpClient ?? http.Client(),
        _bearerToken = bearerToken;

  /// Convenience: read the Supabase URL + current session token from the
  /// active client. The gateway lives at `<supabase_url>/functions/v1/ai-gateway`.
  factory AiGatewayClient.fromSupabase({
    required SupabaseClient supabase,
    http.Client? httpClient,
  }) {
    final base = Uri.parse(supabase.rest.url).origin;
    return AiGatewayClient(
      endpoint: Uri.parse('$base/functions/v1/ai-gateway'),
      bearerToken: () =>
          supabase.auth.currentSession?.accessToken ?? '',
      httpClient: httpClient,
    );
  }

  /// Send a completion request.
  ///
  /// [idempotencyKey] is optional; one will be generated if omitted. Passing
  /// the same key on a retry of the same logical action makes the gateway
  /// return the prior call's status instead of double-billing.
  ///
  /// Throws:
  ///   • [AiGatewayQuotaException] when status='blocked_quota'.
  ///   • [AiGatewayExhaustedException] when status='blocked_all_exhausted'.
  ///   • [AiGatewayTransportException] for any other non-200 outcome after
  ///     retries are exhausted.
  Future<AiGatewayResult> complete({
    required String featureType,
    required String systemPrompt,
    required String userPrompt,
    String? responseFormat,
    int? maxTokens,
    double? temperature,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? IdempotencyKey.generate();
    final body = <String, dynamic>{
      'feature_type': featureType,
      'system_prompt': systemPrompt,
      'user_prompt': userPrompt,
      'idempotency_key': key,
      if (responseFormat != null) 'response_format': responseFormat,
      if (maxTokens != null) 'max_tokens': maxTokens,
      if (temperature != null) 'temperature': temperature,
    };

    return retryNetwork(
      () => _send(body, key),
      label: 'ai-gateway',
    );
  }

  Future<AiGatewayResult> _send(
    Map<String, dynamic> body,
    String idempotencyKey,
  ) async {
    final token = _bearerToken();
    if (token.isEmpty) {
      throw const AiGatewayTransportException(
        'no_auth_token; user must be signed in',
        statusCode: 401,
      );
    }

    final http.Response res;
    try {
      res = await _http
          .post(
            _endpoint,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'X-Idempotency-Key': idempotencyKey,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 35));
    } on TimeoutException catch (e) {
      throw AiGatewayTransportException('timeout: $e');
    } on http.ClientException catch (e) {
      throw AiGatewayTransportException('network: ${e.message}');
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw AiGatewayTransportException(
        'malformed response body (status ${res.statusCode})',
        statusCode: res.statusCode,
      );
    }

    // Server taxonomy is the source of truth for status. Don't rely on
    // HTTP status code alone — 429 = quota; 503 = exhausted; 200 = success
    // OR fallback OR cache_hit; 4xx = invalid request.
    final status = (json['status'] as String?) ?? 'error_invalid_request';

    if (status == 'blocked_quota') {
      developer.log('gateway quota blocked', name: 'AiGateway');
      throw const AiGatewayQuotaException('daily budget exhausted');
    }
    if (status == 'blocked_all_exhausted') {
      developer.log('gateway exhausted all models', name: 'AiGateway');
      throw AiGatewayExhaustedException((json['model'] as String?) ?? 'unknown');
    }
    if (res.statusCode >= 400) {
      throw AiGatewayTransportException(
        '${json['message'] ?? 'unknown_error'}',
        statusCode: res.statusCode,
      );
    }

    final isCache = status == 'cache_hit';
    return AiGatewayResult(
      text: (json['text'] as String?) ?? '',
      model: (json['model'] as String?) ?? 'unknown',
      status: status,
      isLLMGenerated: !isCache && status != 'blocked_quota',
      isFromCache: isCache,
      tokensIn: (json['tokens_in'] as num?)?.toInt(),
      tokensOut: (json['tokens_out'] as num?)?.toInt(),
      latencyMs: (json['latency_ms'] as num?)?.toInt(),
    );
  }

  void dispose() {
    _http.close();
  }
}
