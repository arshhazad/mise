enum SubscriptionStatus { active, paused, expired, cancelled }

class UserAddress {
  final String tag;
  final String address;

  UserAddress({required this.tag, required this.address});

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      tag: json['tag'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'address': address,
  };
}

class MiseUser {
  final String id;
  final String? fullName;
  final String? phoneNumber;
  final List<UserAddress> addresses;
  final String selectedAddressTag;
  final String defaultPreference;
  final bool onboardingCompleted;

  MiseUser({
    required this.id,
    this.fullName,
    this.phoneNumber,
    this.addresses = const [],
    this.selectedAddressTag = 'Office',
    this.defaultPreference = 'Veg',
    this.onboardingCompleted = false,
  });

  MiseUser copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    List<UserAddress>? addresses,
    String? selectedAddressTag,
    String? defaultPreference,
    bool? onboardingCompleted,
  }) {
    return MiseUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      addresses: addresses ?? this.addresses,
      selectedAddressTag: selectedAddressTag ?? this.selectedAddressTag,
      defaultPreference: defaultPreference ?? this.defaultPreference,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  factory MiseUser.fromJson(Map<String, dynamic> json) {
    return MiseUser(
      id: json['id'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      addresses: (json['addresses'] as List? ?? [])
          .map((a) => UserAddress.fromJson(a as Map<String, dynamic>))
          .toList(),
      selectedAddressTag: json['selected_address_tag'] ?? 'Office',
      defaultPreference: json['default_preference'] ?? 'Veg',
      onboardingCompleted: json['onboarding_completed'] ?? false,
    );
  }
}

class Subscription {
  final String id;
  final String userId;
  final SubscriptionStatus status;
  final int mealsRemaining;
  final DateTime startDate;
  final DateTime? endDate;

  Subscription({
    required this.id,
    required this.userId,
    required this.status,
    required this.mealsRemaining,
    required this.startDate,
    this.endDate,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      userId: json['user_id'],
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => SubscriptionStatus.active,
      ),
      mealsRemaining: json['meals_remaining'],
      startDate: DateTime.parse(json['created_at']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
    );
  }
}
