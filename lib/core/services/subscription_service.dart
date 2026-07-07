import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/supabase_provider.dart';
import '../../data/models/subscription_plan.dart';

/// Talks to the `enforce-subscription` edge function + reads the
/// `subscription_plans` catalog. Used by `SubscriptionGuard` and the
/// super-admin billing screens.
class SubscriptionService {
  final SupabaseClient _client;

  SubscriptionService(this._client);

  /// Fetch the full plan catalog (for the upgrade screen).
  Future<List<SubscriptionPlan>> listPlans() async {
    final res = await _client
        .from('subscription_plans')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return (res as List)
        .map((j) => SubscriptionPlan.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Pre-flight: is this feature flag allowed for the current tenant?
  Future<SubscriptionVerdict> checkFeature(String featureKey) async {
    return _callEnforce(
      method: 'GET',
      query: {'feature': featureKey},
    );
  }

  /// Pre-flight: can the tenant add another student?
  Future<SubscriptionVerdict> checkStudentCapacity() async {
    return _callEnforce(
      method: 'POST',
      body: {'check': 'student_count'},
    );
  }

  /// Pre-flight: how much AI budget remains today?
  Future<SubscriptionVerdict> checkAiBudget() async {
    return _callEnforce(
      method: 'POST',
      body: {'check': 'ai_budget'},
    );
  }

  /// Full plan summary for the current tenant (no feature filter).
  Future<SubscriptionVerdict> currentPlan() async {
    return _callEnforce(method: 'GET');
  }

  Future<SubscriptionVerdict> _callEnforce({
    required String method,
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final res = await _client.functions.invoke(
      'enforce-subscription',
      method: method == 'GET' ? HttpMethod.get : HttpMethod.post,
      headers: {'Content-Type': 'application/json'},
      body: body,
      queryParameters: query,
    );
    final data = res.data is String
        ? jsonDecode(res.data as String) as Map<String, dynamic>
        : res.data is Map
            ? Map<String, dynamic>.from(res.data as Map)
            : <String, dynamic>{};
    return SubscriptionVerdict.fromJson(data);
  }
}

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(ref.watch(supabaseProvider));
});
