// Auth-related entities
class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}

class UserEntity {
  final String id;
  final String phone;
  final String? email;
  final String status;
  final bool isVerified;
  final DateTime? lastLoginAt;
  final UserProfileEntity? profile;

  UserEntity({
    required this.id,
    required this.phone,
    this.email,
    required this.status,
    required this.isVerified,
    this.lastLoginAt,
    this.profile,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'].toString(),
      phone: json['phone'] as String,
      email: json['email'] as String?,
      status: json['status'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      profile: json['profile'] != null
          ? UserProfileEntity.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
    );
  }
}

class UserProfileEntity {
  final String userId;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final String? gender;
  final DateTime? birthDate;

  UserProfileEntity({
    required this.userId,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.gender,
    this.birthDate,
  });

  factory UserProfileEntity.fromJson(Map<String, dynamic> json) {
    return UserProfileEntity(
      userId: json['userId'].toString(),
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      gender: json['gender'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
    );
  }
}

class ProviderProfileEntity {
  final String userId;
  final String displayName;
  final String? bio;
  final Map<String, dynamic>? skills;
  final double ratingAvg;
  final int ratingCount;
  final bool isAvailable;
  final String verificationStatus;
  final int serviceRadiusM;

  ProviderProfileEntity({
    required this.userId,
    required this.displayName,
    this.bio,
    this.skills,
    required this.ratingAvg,
    required this.ratingCount,
    required this.isAvailable,
    required this.verificationStatus,
    required this.serviceRadiusM,
  });

  factory ProviderProfileEntity.fromJson(Map<String, dynamic> json) {
    return ProviderProfileEntity(
      userId: json['userId'].toString(),
      displayName: json['displayName'] as String,
      bio: json['bio'] as String?,
      skills: json['skills'] as Map<String, dynamic>?,
      ratingAvg: _parseDouble(json['ratingAvg']),
      ratingCount: _parseInt(json['ratingCount']),
      isAvailable: json['isAvailable'] as bool? ?? false,
      verificationStatus: json['verificationStatus'] as String? ?? 'unverified',
      serviceRadiusM: _parseInt(json['serviceRadiusM'], defaultValue: 5000),
    );
  }

  static double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}
