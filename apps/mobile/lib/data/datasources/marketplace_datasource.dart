import 'package:dio/dio.dart';
import '../../core/entities/entities.dart';

class MarketplaceDataSource {
  final Dio _dio;

  MarketplaceDataSource()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://10.0.2.2:3000',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get('/marketplace/categories');
      final dynamic responseData = response.data;

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        final data = responseData['data'];
        if (data is List) {
          return data
              .map((json) => _categoryFromJson(json as Map<String, dynamic>))
              .toList();
        }
      } else if (responseData is List) {
        return responseData
            .map((json) => _categoryFromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<List<ProviderService>> searchServices({int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/marketplace/services/search',
        queryParameters: {'limit': limit},
      );

      // Backend returns: {"statusCode":200, "message":"Success", "data": {"results": [...], "meta": {...}}}
      final dynamic responseData = response.data;

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        final outerData = responseData['data'];

        if (outerData is Map<String, dynamic>) {
          // Check for 'results' field (backend uses this)
          if (outerData.containsKey('results')) {
            final results = outerData['results'];
            if (results is List) {
              return results
                  .map((json) =>
                      _providerServiceFromJson(json as Map<String, dynamic>))
                  .toList();
            }
          }
          // Fallback: check for 'data' field
          else if (outerData.containsKey('data')) {
            final innerData = outerData['data'];
            if (innerData is List) {
              return innerData
                  .map((json) =>
                      _providerServiceFromJson(json as Map<String, dynamic>))
                  .toList();
            }
          }
        } else if (outerData is List) {
          return outerData
              .map((json) =>
                  _providerServiceFromJson(json as Map<String, dynamic>))
              .toList();
        }
      } else if (responseData is List) {
        return responseData
            .map((json) =>
                _providerServiceFromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception('Failed to load services: $e');
    }
  }

  // Helper function to safely parse numbers (handles String, int, double, null)
  double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  Category _categoryFromJson(Map<String, dynamic> json) {
    return Category(
      id: _parseInt(json['id']),
      code: json['code'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      iconUrl: json['iconUrl'] as String?,
      parentId: json['parentId'] != null ? _parseInt(json['parentId']) : null,
    );
  }

  ProviderService _providerServiceFromJson(Map<String, dynamic> json) {
    final serviceData = json['service'];
    final providerData = json['provider'];

    if (serviceData == null || providerData == null) {
      throw Exception('Missing service or provider data');
    }

    return ProviderService(
      providerUserId: json['providerUserId'].toString(),
      serviceId: _parseInt(json['serviceId']),
      price: _parseDouble(json['price']),
      currency: json['currency'] as String? ?? 'VND',
      isActive: json['isActive'] as bool? ?? true,
      service: Service(
        id: _parseInt(serviceData['id']),
        categoryId: serviceData['categoryId'] != null
            ? _parseInt(serviceData['categoryId'])
            : null,
        name: serviceData['name'] as String,
        description: serviceData['description'] as String?,
        basePrice: _parseDouble(serviceData['basePrice']),
        durationMinutes: serviceData['durationMinutes'] != null
            ? _parseInt(serviceData['durationMinutes'])
            : null,
      ),
      provider: Provider(
        userId: providerData['userId'].toString(),
        displayName: providerData['displayName'] as String,
        bio: providerData['bio'] as String?,
        ratingAvg: _parseDouble(providerData['ratingAvg']),
        ratingCount: _parseInt(providerData['ratingCount']),
        isAvailable: providerData['isAvailable'] as bool? ?? false,
        verificationStatus:
            providerData['verificationStatus'] as String? ?? 'unverified',
      ),
    );
  }
}
