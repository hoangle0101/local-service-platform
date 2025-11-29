import 'package:dio/dio.dart';
import '../../core/entities/booking_entity.dart';
import '../storage/secure_storage.dart';

class BookingsDataSource {
  final Dio _dio;

  BookingsDataSource()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://10.0.2.2:3000',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  Future<List<BookingEntity>> getBookings() async {
    try {
      final token = await SecureStorage.getAccessToken();
      final response = await _dio.get(
        '/bookings',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      // Backend returns {statusCode, message, data: [...]}
      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        final data = responseData['data'];
        if (data is List) {
          return data
              .map((json) =>
                  BookingEntity.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }

      // If data is directly a list
      if (responseData is List) {
        return responseData
            .map((json) => BookingEntity.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to load bookings: ${e.toString()}');
    }
  }

  Future<List<BookingEntity>> getProviderBookings() async {
    try {
      final token = await SecureStorage.getAccessToken();
      final response = await _dio.get(
        '/bookings/provider',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      // Backend returns {statusCode, message, data: [...]}
      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        final data = responseData['data'];
        if (data is List) {
          return data
              .map((json) =>
                  BookingEntity.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }

      // If data is directly a list
      if (responseData is List) {
        return responseData
            .map((json) => BookingEntity.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to load provider bookings: ${e.toString()}');
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      final token = await SecureStorage.getAccessToken();
      await _dio.patch(
        '/bookings/$bookingId/cancel',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      throw Exception('Failed to cancel booking: ${e.toString()}');
    }
  }

  Future<void> reviewBooking(
      String bookingId, int rating, String? comment) async {
    try {
      final token = await SecureStorage.getAccessToken();
      await _dio.post(
        '/bookings/$bookingId/review',
        data: {
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      throw Exception('Failed to submit review: ${e.toString()}');
    }
  }

  Future<void> acceptBooking(String bookingId) async {
    try {
      final token = await SecureStorage.getAccessToken();
      await _dio.patch(
        '/bookings/provider/$bookingId/accept',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      throw Exception('Failed to accept booking: ${e.toString()}');
    }
  }

  Future<void> startService(String bookingId) async {
    try {
      final token = await SecureStorage.getAccessToken();
      await _dio.patch(
        '/bookings/provider/$bookingId/start',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      throw Exception('Failed to start service: ${e.toString()}');
    }
  }

  Future<void> completeService(String bookingId) async {
    try {
      final token = await SecureStorage.getAccessToken();
      await _dio.patch(
        '/bookings/provider/$bookingId/complete',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      throw Exception('Failed to complete service: ${e.toString()}');
    }
  }
}
