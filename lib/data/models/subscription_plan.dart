/// Subscription plan catalog model (mirrors `subscription_plans` table).
class SubscriptionPlan {
  final String id;
  final String displayName;
  final int priceInrPaise;
  final String billingPeriod;
  final int maxStudents;
  final double aiCreditsUsd;
  final Map<String, bool> featureFlags;
  final bool isActive;
  final int sortOrder;

  const SubscriptionPlan({
    required this.id,
    required this.displayName,
    required this.priceInrPaise,
    required this.billingPeriod,
    required this.maxStudents,
    required this.aiCreditsUsd,
    required this.featureFlags,
    this.isActive = true,
    this.sortOrder = 0,
  });

  /// Price in whole rupees (for display).
  int get priceInr => priceInrPaise ~/ 100;

  /// True if this plan grants the given feature flag.
  bool hasFeature(String key) => featureFlags[key] == true;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final flagsRaw = json['feature_flags'] as Map<String, dynamic>? ?? {};
    return SubscriptionPlan(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      priceInrPaise: (json['price_inr_paise'] as num).toInt(),
      billingPeriod: json['billing_period'] as String? ?? 'yearly',
      maxStudents: (json['max_students'] as num).toInt(),
      aiCreditsUsd: (json['ai_credits_usd'] as num).toDouble(),
      featureFlags:
          flagsRaw.map((k, v) => MapEntry(k, v == true)),
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'price_inr_paise': priceInrPaise,
        'billing_period': billingPeriod,
        'max_students': maxStudents,
        'ai_credits_usd': aiCreditsUsd,
        'feature_flags':
            featureFlags.map((k, v) => MapEntry(k, v)),
        'is_active': isActive,
        'sort_order': sortOrder,
      };
}

/// Verdict returned by the `enforce-subscription` edge function.
class SubscriptionVerdict {
  final bool allowed;
  final String reason;
  final String? planId;
  final String? displayName;
  final bool? isPaid;
  final int? maxStudents;
  final double? aiCreditsUsd;
  final Map<String, bool>? featureFlags;
  final int? current;
  final int? usedToday;
  final double? budget;

  const SubscriptionVerdict({
    required this.allowed,
    required this.reason,
    this.planId,
    this.displayName,
    this.isPaid,
    this.maxStudents,
    this.aiCreditsUsd,
    this.featureFlags,
    this.current,
    this.usedToday,
    this.budget,
  });

  factory SubscriptionVerdict.fromJson(Map<String, dynamic> json) {
    return SubscriptionVerdict(
      allowed: json['allowed'] as bool? ?? false,
      reason: json['reason'] as String? ?? 'unknown',
      planId: json['plan'] as String?,
      displayName: json['display_name'] as String?,
      isPaid: json['is_paid'] as bool?,
      maxStudents: (json['max_students'] as num?)?.toInt(),
      aiCreditsUsd: (json['ai_credits_usd'] as num?)?.toDouble(),
      featureFlags: (json['feature_flags'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v == true),
      ),
      current: (json['current'] as num?)?.toInt(),
      usedToday: (json['used_today'] as num?)?.toInt(),
      budget: (json['budget'] as num?)?.toDouble(),
    );
  }
}
