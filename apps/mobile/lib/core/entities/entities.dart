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

  @override
  List<Object?> get props =>
      [id, code, name, slug, description, iconUrl, parentId];
}

class Service extends Equatable {
  final int id;
  final int? categoryId;
  final String name;
  final String? description;
  final double basePrice;
  final int? durationMinutes;

  const Service({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.basePrice,
    this.durationMinutes,
  });

  @override
  List<Object?> get props =>
      [id, categoryId, name, description, basePrice, durationMinutes];
}

class Provider extends Equatable {
  final String userId;
  final String displayName;
  final String? bio;
  final double ratingAvg;
  final int ratingCount;
  final bool isAvailable;
  final String verificationStatus;

  const Provider({
    required this.userId,
    required this.displayName,
    this.bio,
    required this.ratingAvg,
    required this.ratingCount,
    required this.isAvailable,
    required this.verificationStatus,
  });

  bool get isVerified => verificationStatus == 'verified';

  @override
  List<Object?> get props => [
        userId,
        displayName,
        bio,
        ratingAvg,
        ratingCount,
        isAvailable,
        verificationStatus
      ];
}

class ProviderService extends Equatable {
  final String providerUserId;
  final int serviceId;
  final double price;
  final String currency;
  final bool isActive;
  final Service service;
  final Provider provider;

  const ProviderService({
    required this.providerUserId,
    required this.serviceId,
    required this.price,
    required this.currency,
    required this.isActive,
    required this.service,
    required this.provider,
  });

  @override
  List<Object?> get props =>
      [providerUserId, serviceId, price, currency, isActive, service, provider];
}
