import 'package:equatable/equatable.dart';

// Helper functions for safe type parsing
int _safeParseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

double _safeParseDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

class Category extends Equatable {
  final int id;
  final String code;
  final String name;
  final String? slug;
  final String? description;
  final String? iconUrl;
  final int? parentId;

  const Category({
    required this.id,
    required this.code,
    required this.name,
    this.slug,
    this.description,
    this.iconUrl,
    this.parentId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: _safeParseInt(json['id']),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? 'Category').toString(),
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
      iconUrl: json['icon_url']?.toString() ?? json['iconUrl']?.toString(),
      parentId: json['parent_id'] != null
          ? _safeParseInt(json['parent_id'])
          : (json['parentId'] != null ? _safeParseInt(json['parentId']) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'slug': slug,
      'description': description,
      'iconUrl': iconUrl,
      'parentId': parentId,
    };
  }

  @override
  List<Object?> get props =>
      [id, code, name, slug, description, iconUrl, parentId];
}

class Service extends Equatable {
  final int id;
  final String name;
  final String? description;
  final int categoryId;
  final String? iconUrl;
  final int? durationMinutes;

  const Service({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
    this.iconUrl,
    this.durationMinutes,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: _safeParseInt(json['id']),
      name: (json['name'] ?? 'Service').toString(),
      description: json['description']?.toString(),
      categoryId: _safeParseInt(json['category_id'] ?? json['categoryId']),
      iconUrl: json['icon_url']?.toString() ?? json['iconUrl']?.toString(),
      durationMinutes: json['duration_minutes'] != null
          ? _safeParseInt(json['duration_minutes'])
          : (json['durationMinutes'] != null
              ? _safeParseInt(json['durationMinutes'])
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'icon_url': iconUrl,
      'duration_minutes': durationMinutes,
    };
  }

  @override
  List<Object?> get props =>
      [id, name, description, categoryId, iconUrl, durationMinutes];
}

class ProviderService extends Equatable {
  final int serviceId;
  final String providerUserId;
  final double price;
  final String currency;
  final bool isActive;
  final Service service;
  final ProviderInfo provider;

  const ProviderService({
    required this.serviceId,
    required this.providerUserId,
    required this.price,
    required this.currency,
    required this.isActive,
    required this.service,
    required this.provider,
  });

  factory ProviderService.fromJson(Map<String, dynamic> json) {
    // Parse serviceId - could be int or String from backend
    int serviceId;
    if (json['service_id'] != null) {
      serviceId = json['service_id'] is int
          ? json['service_id']
          : int.parse(json['service_id'].toString());
    } else {
      serviceId = json['serviceId'] is int
          ? json['serviceId']
          : int.parse(json['serviceId'].toString());
    }

    // Parse providerUserId - could be int or String
    String providerUserId =
        (json['provider_user_id'] ?? json['providerUserId']).toString();

    // Parse price - could be String or num
    double price = 0.0;
    final priceValue = json['price'];
    if (priceValue != null) {
      price = priceValue is num
          ? priceValue.toDouble()
          : double.tryParse(priceValue.toString()) ?? 0.0;
    }

    return ProviderService(
      serviceId: serviceId,
      providerUserId: providerUserId,
      price: price,
      currency: json['currency'] as String? ?? 'VND',
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      service: Service.fromJson(json['service'] as Map<String, dynamic>),
      provider: ProviderInfo.fromJson(json['provider'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props =>
      [serviceId, providerUserId, price, currency, isActive, service, provider];
}

class ProviderInfo extends Equatable {
  final String userId;
  final String displayName;
  final bool isVerified;
  final double ratingAvg;
  final int ratingCount;

  const ProviderInfo({
    required this.userId,
    required this.displayName,
    required this.isVerified,
    required this.ratingAvg,
    required this.ratingCount,
  });

  factory ProviderInfo.fromJson(Map<String, dynamic> json) {
    // Parse userId - could be int or String
    String userId = (json['user_id'] ?? json['userId']).toString();

    // Parse displayName
    String displayName =
        (json['display_name'] ?? json['displayName'] ?? 'Provider').toString();

    // Parse isVerified
    bool isVerified =
        json['is_verified'] as bool? ?? json['isVerified'] as bool? ?? false;

    // Parse ratingAvg - could be String or num
    double ratingAvg = 0.0;
    final ratingValue = json['rating_avg'] ?? json['ratingAvg'];
    if (ratingValue != null) {
      ratingAvg = ratingValue is num
          ? ratingValue.toDouble()
          : double.tryParse(ratingValue.toString()) ?? 0.0;
    }

    // Parse ratingCount - could be String or int
    int ratingCount = 0;
    final countValue = json['rating_count'] ?? json['ratingCount'];
    if (countValue != null) {
      ratingCount = countValue is int
          ? countValue
          : int.tryParse(countValue.toString()) ?? 0;
    }

    return ProviderInfo(
      userId: userId,
      displayName: displayName,
      isVerified: isVerified,
      ratingAvg: ratingAvg,
      ratingCount: ratingCount,
    );
  }

  @override
  List<Object?> get props =>
      [userId, displayName, isVerified, ratingAvg, ratingCount];
}
