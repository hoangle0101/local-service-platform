import 'package:dio/dio.dart';
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
        );

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final token = await SecureStorage.getAccessToken();
      final response = await _dio.get(
        '/provider/statistics',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load statistics: ${e.toString()}');
    }
  }

  Future<void> updateAvailability(bool isAvailable) async {
    try {
      final token = await SecureStorage.getAccessToken();
      await _dio.patch(
        '/provider/me/availability',
        data: {'isAvailable': isAvailable},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      throw Exception('Failed to update availability: ${e.toString()}');
    }
  }

  Future<void> createProviderProfile({
    required String displayName,
    String? bio,
    List<String>? skills,
    int? serviceRadiusM,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      final token = await SecureStorage.getAccessToken();
      print(
          'Creating provider profile with token: ${token?.substring(0, 10)}...');
      print('Request data: ${{
        'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (skills != null) 'skills': skills,
        if (serviceRadiusM != null) 'serviceRadiusM': serviceRadiusM,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (address != null) 'address': address,
      }}');

      await _dio.post(
        '/provider/onboarding',
        data: {
          'displayName': displayName,
          if (bio != null) 'bio': bio,
          if (skills != null) 'skills': skills,
          if (serviceRadiusM != null) 'serviceRadiusM': serviceRadiusM,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (address != null) 'address': address,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      // Detailed error handling
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final errorData = e.response!.data;
        String errorMessage = 'Failed to create provider profile';

        if (errorData is Map && errorData.containsKey('message')) {
          errorMessage = errorData['message'].toString();
        }

        throw Exception('Error $statusCode: $errorMessage');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to create provider profile: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getMyServices() async {
    try {
      final token = await SecureStorage.getAccessToken();
      final response = await _dio.get(
        '/provider/services',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final data = response.data['data'];
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load services: ${e.toString()}');
    }
  }

  Future<void> addService({
    required int serviceId,
    required double price,
    String currency = 'VND',
  }) async {
    try {
      final token = await SecureStorage.getAccessToken();
      await _dio.post(
        '/provider/services',
        data: {
          'serviceId': serviceId,
          'price': price,
          'currency': currency,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      throw Exception('Failed to add service: ${e.toString()}');
    }
  }

  Future<void> updateService({
    required int serviceId,
    double? price,
    bool? isActive,
  }) async {
    try {
      final token = await SecureStorage.getAccessToken();
      await _dio.patch(
        '/provider/services/$serviceId',
        data: {
          if (price != null) 'price': price,
          if (isActive != null) 'isActive': isActive,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      throw Exception('Failed to update service: ${e.toString()}');
    }
  }

  Future<void> deleteService(int serviceId) async {
    try {
      final token = await SecureStorage.getAccessToken();
      await _dio.delete(
        '/provider/services/$serviceId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      throw Exception('Failed to delete service: ${e.toString()}');
    }
  }
}
