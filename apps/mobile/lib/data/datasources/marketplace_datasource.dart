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

  Future<List<ProviderService>> searchServices({
    int limit = 10,
    int? categoryId,
  }) async {
    try {
      final queryParams = {'limit': limit};
      if (categoryId != null) {
        queryParams['categoryId'] = categoryId;
      }

      final response = await _dio.get(
        '/marketplace/services/search',
        queryParameters: queryParams,
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

  Future<ProviderService> getServiceById(int serviceId) async {
    try {
      final response = await _dio.get('/marketplace/services/$serviceId');

      // Handle nested response: {data: {providerUserId, ..., service: {...}, provider: {...}}}
      // OR double nested: {data: {data: {...}}}
      var data = response.data;

      // Unwrap outer 'data' if present
      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }
      // Unwrap inner 'data' if present (double wrap case)
      if (data is Map &&
          data.containsKey('data') &&
          !data.containsKey('service')) {
        data = data['data'];
      }

      return _providerServiceFromJson(data);
    } catch (e) {
      throw Exception('Failed to load service details: $e');
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
    try {
      return Category(
        id: _parseInt(json['id']),
        code: (json['code'] ?? '').toString(),
        name: (json['name'] ?? 'Category').toString(),
        slug: json['slug']?.toString(),
        description: json['description']?.toString(),
        iconUrl: json['iconUrl']?.toString() ?? json['icon_url']?.toString(),
        parentId: json['parentId'] != null
            ? _parseInt(json['parentId'])
            : (json['parent_id'] != null ? _parseInt(json['parent_id']) : null),
      );
    } catch (e, stackTrace) {
      print('[Marketplace] Error parsing Category: $e');
      print('[Marketplace] Category JSON: $json');
      print('[Marketplace] Stack: $stackTrace');
      rethrow;
    }
  }

  ProviderService _providerServiceFromJson(Map<String, dynamic> json) {
    try {
      final serviceData = json['service'];
      final providerData = json['provider'];

      if (serviceData == null || providerData == null) {
        print('[Marketplace] Missing service or provider data: $json');
        throw Exception('Missing service or provider data');
      }

      // Extract categoryId: first try direct field, then try nested category object
      int categoryId = 0;
      if (serviceData['categoryId'] != null) {
        categoryId = _parseInt(serviceData['categoryId']);
      } else if (serviceData['category_id'] != null) {
        categoryId = _parseInt(serviceData['category_id']);
      } else if (serviceData['category'] != null &&
          serviceData['category'] is Map) {
        categoryId = _parseInt(serviceData['category']['id']);
      }

      return ProviderService(
        providerUserId:
            (json['providerUserId'] ?? json['provider_user_id'] ?? '')
                .toString(),
        serviceId: _parseInt(json['serviceId'] ?? json['service_id']),
        price: _parseDouble(json['price']),
        currency: (json['currency'] ?? 'VND').toString(),
        isActive:
            json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
        service: Service(
          id: _parseInt(serviceData['id']),
          categoryId: categoryId,
          name: (serviceData['name'] ?? 'Service').toString(),
          description: serviceData['description']?.toString(),
          iconUrl: serviceData['iconUrl']?.toString() ??
              serviceData['icon_url']?.toString(),
          durationMinutes: _parseInt(serviceData['durationMinutes'] ??
              serviceData['duration_minutes']),
        ),
        provider: ProviderInfo(
          userId: (providerData['userId'] ?? providerData['user_id'] ?? '')
              .toString(),
          displayName: (providerData['displayName'] ??
                  providerData['display_name'] ??
                  'Provider')
              .toString(),
          isVerified: providerData['isVerified'] as bool? ??
              providerData['is_verified'] as bool? ??
              false,
          ratingAvg: _parseDouble(
              providerData['ratingAvg'] ?? providerData['rating_avg']),
          ratingCount: _parseInt(
              providerData['ratingCount'] ?? providerData['rating_count']),
        ),
      );
    } catch (e, stackTrace) {
      print('[Marketplace] Error parsing ProviderService: $e');
      print('[Marketplace] JSON data: $json');
      print('[Marketplace] Stack trace: $stackTrace');
      rethrow;
    }
  }
}
