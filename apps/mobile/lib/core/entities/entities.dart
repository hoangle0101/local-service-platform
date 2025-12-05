import 'package:equatable/equatable.dart';

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
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String? ?? json['iconUrl'] as String?,
      parentId: json['parent_id'] as int? ?? json['parentId'] as int?,
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
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      categoryId: json['category_id'] as int? ?? json['categoryId'] as int,
      iconUrl: json['icon_url'] as String? ?? json['iconUrl'] as String?,
      durationMinutes:
          json['duration_minutes'] as int? ?? json['durationMinutes'] as int?,
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
    return ProviderService(
      serviceId: json['service_id'] as int? ?? json['serviceId'] as int,
      providerUserId: json['provider_user_id'] as String? ??
          json['providerUserId'] as String,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
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
    return ProviderInfo(
      userId: json['user_id'] as String? ?? json['userId'] as String,
      displayName:
          json['display_name'] as String? ?? json['displayName'] as String,
      isVerified:
          json['is_verified'] as bool? ?? json['isVerified'] as bool? ?? false,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ??
          (json['ratingAvg'] as num?)?.toDouble() ??
          0.0,
      ratingCount:
          json['rating_count'] as int? ?? json['ratingCount'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [userId, displayName, isVerified, ratingAvg, ratingCount];
}
