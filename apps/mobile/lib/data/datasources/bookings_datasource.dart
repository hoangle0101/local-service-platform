import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../presentation/bloc/bookings/bookings_event_state.dart';

class BookingsDataSource {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  BookingsDataSource() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://10.0.2.2:3000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> createBooking({
    required int serviceId,
    required DateTime scheduledAt,
    required String addressText,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    try {
      final response = await _dio.post('/bookings', data: {
        'serviceId': serviceId,
        'scheduledAt': scheduledAt.toIso8601String(),
        'addressText': addressText,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
      });

      final data = response.data;
      return {
        'id': data['id']?.toString() ?? '',
        'code': data['code']?.toString() ?? 'N/A',
        'status': data['status']?.toString() ?? 'pending',
        'nearbyProviderIds': data['nearbyProviderIds'] ?? [],
      };
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  Future<List<BookingOffer>> getBookingOffers(int bookingId) async {
    try {
      final response = await _dio.get('/bookings/$bookingId/offers');
      final List<dynamic> data = response.data['offers'] ?? [];
      return data.map((json) => BookingOffer.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load offers: $e');
    }
  }

  Future<Map<String, dynamic>> selectProvider(
      int bookingId, int providerId) async {
    try {
      final response =
          await _dio.post('/bookings/$bookingId/select-provider/$providerId');
      return response.data;
    } catch (e) {
      throw Exception('Failed to select provider: $e');
    }
  }

  Future<List<Booking>> getUserBookings({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      print('[BookingsDataSource] Fetching user bookings...');
      print('[BookingsDataSource] Query params: $queryParams');

      final response =
          await _dio.get('/bookings', queryParameters: queryParams);

      print('[BookingsDataSource] Response status: ${response.statusCode}');
      print(
          '[BookingsDataSource] Response data type: ${response.data.runtimeType}');
      print('[BookingsDataSource] Response data: ${response.data}');

      // Handle different response formats from backend
      final responseData = response.data;
      List<dynamic> bookingsData = [];

      if (responseData is Map<String, dynamic>) {
        // Try different possible keys
        if (responseData.containsKey('bookings')) {
          bookingsData = responseData['bookings'] as List? ?? [];
        } else if (responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is List) {
            bookingsData = data;
          } else if (data is Map && data.containsKey('bookings')) {
            bookingsData = data['bookings'] as List? ?? [];
          }
        }
      } else if (responseData is List) {
        bookingsData = responseData;
      }

      print('[BookingsDataSource] Found ${bookingsData.length} bookings');

      final bookings = bookingsData.map((json) {
        print('[BookingsDataSource] Parsing booking: $json');
        try {
          return Booking.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          print('[BookingsDataSource] Error parsing booking: $e');
          rethrow;
        }
      }).toList();

      print(
          '[BookingsDataSource] Successfully parsed ${bookings.length} bookings');
      return bookings;
    } on DioException catch (e) {
      print('[BookingsDataSource] DioException: ${e.message}');
      print('[BookingsDataSource] DioException response: ${e.response?.data}');
      throw Exception('Failed to load bookings: ${e.message}');
    } catch (e) {
      print('[BookingsDataSource] Error: $e');
      throw Exception('Failed to load bookings: $e');
    }
  }

  Future<List<Booking>> getProviderBookings({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final response =
          await _dio.get('/bookings', queryParameters: queryParams);
      final List<dynamic> data = response.data['bookings'] ?? [];
      return data.map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load bookings: $e');
    }
  }

  Future<List<Booking>> getProviderRequests() async {
    try {
      final response = await _dio.get('/provider/bookings/requests');
      final List<dynamic> data = response.data['requests'] ?? [];
      return data.map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load requests: $e');
    }
  }

  Future<Map<String, dynamic>> acceptBookingRequest(int bookingId) async {
    try {
      final response = await _dio.post('/provider/bookings/$bookingId/offer');
      return response.data;
    } catch (e) {
      throw Exception('Failed to send offer: $e');
    }
  }

  Future<void> cancelBooking(String bookingId, String? reason) async {
    try {
      await _dio.patch('/bookings/$bookingId/cancel', data: {
        'reason': reason ?? 'Cancelled by user',
      });
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  Future<void> reviewBooking(
      String bookingId, int rating, String comment) async {
    try {
      await _dio.post('/bookings/$bookingId/review', data: {
        'rating': rating,
        'comment': comment,
      });
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  Future<void> acceptBookingLegacy(String bookingId) async {
    try {
      await _dio.patch('/provider/bookings/$bookingId/accept');
    } catch (e) {
      throw Exception('Failed to accept booking: $e');
    }
  }

  Future<void> startService(String bookingId) async {
    try {
      await _dio.patch('/provider/bookings/$bookingId/start');
    } catch (e) {
      throw Exception('Failed to start service: $e');
    }
  }

  Future<void> completeService(String bookingId) async {
    try {
      await _dio.patch('/provider/bookings/$bookingId/complete');
    } catch (e) {
      throw Exception('Failed to complete service: $e');
    }
  }
}
