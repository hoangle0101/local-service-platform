import 'package:dio/dio.dart';
import '../../core/entities/auth_entities.dart';
import '../storage/secure_storage.dart';

class ProviderDataSource {
  final Dio _dio;

  ProviderDataSource()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://10.0.2.2:3000',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    // Add interceptor to include auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  // Create provider profile
  Future<ProviderProfileEntity> createProviderProfile({
    required String displayName,
    String? bio,
    Map<String, dynamic>? skills,
    Map<String, dynamic>? location,
    int serviceRadiusM = 5000,
  }) async {
    try {
      final response = await _dio.post('/provider', data: {
        'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (skills != null) 'skills': skills,
        if (location != null) 'location': location,
        'serviceRadiusM': serviceRadiusM,
      });

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('data')) {
          return ProviderProfileEntity.fromJson(
              data['data'] as Map<String, dynamic>);
        }
        return ProviderProfileEntity.fromJson(data);
      }
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception('Failed to create provider profile: $e');
    }
  }

  // Get provider profile
  Future<ProviderProfileEntity> getProviderProfile(String userId) async {
    try {
      final response = await _dio.get('/provider/$userId');

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('data')) {
          return ProviderProfileEntity.fromJson(
              data['data'] as Map<String, dynamic>);
        }
        return ProviderProfileEntity.fromJson(data);
      }
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception('Failed to get provider profile: $e');
    }
  }

  // Update provider profile
  Future<ProviderProfileEntity> updateProviderProfile({
    required String userId,
    String? displayName,
    String? bio,
    Map<String, dynamic>? skills,
    bool? isAvailable,
    int? serviceRadiusM,
  }) async {
    try {
      final response = await _dio.patch('/provider/$userId', data: {
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (skills != null) 'skills': skills,
        if (isAvailable != null) 'isAvailable': isAvailable,
        if (serviceRadiusM != null) 'serviceRadiusM': serviceRadiusM,
      });

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('data')) {
          return ProviderProfileEntity.fromJson(
              data['data'] as Map<String, dynamic>);
        }
        return ProviderProfileEntity.fromJson(data);
      }
      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception('Failed to update provider profile: $e');
    }
  }
}
