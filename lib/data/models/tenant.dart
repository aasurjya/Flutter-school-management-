/// Tenant (School) model
class Tenant {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String country;
  final String timezone;
  final String currency;
  final Map<String, dynamic> settings;
  final String subscriptionPlan;
  final DateTime? subscriptionExpiresAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tenant({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.country = 'India',
    this.timezone = 'Asia/Kolkata',
    this.currency = 'INR',
    this.settings = const {},
    this.subscriptionPlan = 'free',
    this.subscriptionExpiresAt,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      logoUrl: json['logo_url'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'] ?? 'India',
      timezone: json['timezone'] ?? 'Asia/Kolkata',
      currency: json['currency'] ?? 'INR',
      settings: json['settings'] ?? {},
      subscriptionPlan: json['subscription_plan'] ?? 'free',
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.parse(json['subscription_expires_at'])
          : null,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'logo_url': logoUrl,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'timezone': timezone,
      'currency': currency,
      'settings': settings,
      'subscription_plan': subscriptionPlan,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  Tenant copyWith({
    String? id,
    String? name,
    String? slug,
    String? logoUrl,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? country,
    String? timezone,
    String? currency,
    Map<String, dynamic>? settings,
    String? subscriptionPlan,
    DateTime? subscriptionExpiresAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      logoUrl: logoUrl ?? this.logoUrl,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      timezone: timezone ?? this.timezone,
      currency: currency ?? this.currency,
      settings: settings ?? this.settings,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Full address string
  String get fullAddress {
    final parts = [address, city, state, country]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  /// Check if subscription is active
  bool get isSubscriptionActive {
    if (subscriptionExpiresAt == null) return true; // Free plan
    return subscriptionExpiresAt!.isAfter(DateTime.now());
  }
}
