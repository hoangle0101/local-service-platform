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
    int? providerId, // Optional: for direct booking (Book Now)
  }) async {
    try {
      final data = <String, dynamic>{
        'serviceId': serviceId,
        'scheduledAt': scheduledAt.toIso8601String(),
        'addressText': addressText,
        'latitude': latitude,
        'longitude': longitude,
      };

      if (notes != null && notes.isNotEmpty) {
        data['notes'] = notes;
      }

      // Add providerId if this is a direct booking
      if (providerId != null) {
        data['providerId'] = providerId;
        print(
            '[BookingsDataSource] Direct booking with providerId: $providerId');
      } else {
        print('[BookingsDataSource] General booking (no providerId)');
      }

      print('[BookingsDataSource] Sending booking data: $data');

      final response = await _dio.post('/bookings', data: data);

      print('[BookingsDataSource] Response: ${response.data}');

      // Handle nested response format: {statusCode, message, data: {...}}
      final responseBody = response.data;
      final bookingData =
          responseBody is Map && responseBody.containsKey('data')
              ? responseBody['data']
              : responseBody;

      print('[BookingsDataSource] Extracted booking data: $bookingData');

      return {
        'id': bookingData['id']?.toString() ?? '',
        'code': bookingData['code']?.toString() ?? 'N/A',
        'status': bookingData['status']?.toString() ?? 'pending',
        'providerId': bookingData['providerId']?.toString(),
        'isDirectBooking': bookingData['isDirectBooking'] ?? false,
        'nearbyProviderIds': bookingData['nearbyProviderIds'] ?? [],
      };
    } on DioException catch (e) {
      print('[BookingsDataSource] DioException creating booking: ${e.message}');
      print('[BookingsDataSource] Error Response Body: ${e.response?.data}');
      if (e.response?.data is Map && e.response!.data.containsKey('message')) {
        final msg = e.response!.data['message'];
        // Backend validation errors can be array
        if (msg is List) {
          throw Exception(msg.join(', '));
        }
        throw Exception(msg);
      }
      throw Exception('Failed to create booking: ${e.message}');
    } catch (e) {
      print('[BookingsDataSource] Error creating booking: $e');
      throw Exception('Failed to create booking: $e');
    }
  }

  Future<List<BookingOffer>> getBookingOffers(int bookingId) async {
    try {
      print(
          '[BookingsDataSource] getBookingOffers called for bookingId: $bookingId');
      final response = await _dio.get('/bookings/$bookingId/offers');
      print('[BookingsDataSource] getBookingOffers response: ${response.data}');

      // Handle nested response format: {statusCode, message, data: {offers: [...]}}
      // OR direct format: {offers: [...]}
      final responseBody = response.data;
      List<dynamic> offersData = [];

      if (responseBody is Map) {
        if (responseBody.containsKey('data') && responseBody['data'] is Map) {
          // Nested format
          offersData = responseBody['data']['offers'] as List<dynamic>? ?? [];
        } else if (responseBody.containsKey('offers')) {
          // Direct format
          offersData = responseBody['offers'] as List<dynamic>? ?? [];
        }
      }

      print('[BookingsDataSource] Found ${offersData.length} offers');
      return offersData
          .map((json) => BookingOffer.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('[BookingsDataSource] DioException loading offers: ${e.message}');
      print('[BookingsDataSource] Error response: ${e.response?.data}');
      throw Exception('Failed to load offers: ${e.message}');
    } catch (e) {
      print('[BookingsDataSource] Error loading offers: $e');
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

  Future<Booking> getBookingById(String bookingId) async {
    try {
      print('[BookingsDataSource] Fetching booking detail for id: $bookingId');
      final response = await _dio.get('/bookings/$bookingId');

      print('[BookingsDataSource] Booking detail response: ${response.data}');

      // Handle different response formats from backend
      final responseData = response.data;
      Map<String, dynamic> bookingData = {};

      if (responseData is Map<String, dynamic>) {
        // Try different possible keys
        if (responseData.containsKey('data')) {
          bookingData = responseData['data'] as Map<String, dynamic>;
        } else {
          bookingData = responseData;
        }
      }

      print('[BookingsDataSource] Parsed booking detail: $bookingData');

      return Booking.fromJson(bookingData);
    } catch (e) {
      print('[BookingsDataSource] Error fetching booking detail: $e');
      throw Exception('Failed to load booking detail: $e');
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

      print('[BookingsDataSource] getProviderBookings called');
      final response =
          await _dio.get('/bookings', queryParameters: queryParams);

      print(
          '[BookingsDataSource] getProviderBookings response: ${response.data}');

      // Handle nested response format: {statusCode, message, data: {bookings: [...]}}
      final responseBody = response.data;
      List<dynamic> bookingsData = [];

      if (responseBody is Map<String, dynamic>) {
        if (responseBody.containsKey('data') && responseBody['data'] is Map) {
          final data = responseBody['data'] as Map<String, dynamic>;
          bookingsData = data['bookings'] as List? ?? [];
        } else if (responseBody.containsKey('bookings')) {
          bookingsData = responseBody['bookings'] as List? ?? [];
        }
      }

      print(
          '[BookingsDataSource] getProviderBookings found ${bookingsData.length} bookings');

      return bookingsData
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[BookingsDataSource] getProviderBookings error: $e');
      throw Exception('Failed to load bookings: $e');
    }
  }

  Future<List<Booking>> getProviderRequests() async {
    try {
      final response = await _dio.get('/provider/bookings/requests');
      print(
          '[BookingsDataSource] getProviderRequests response: ${response.data}');

      // Handle nested response format: {statusCode, message, data: {requests: [...]}}
      // OR direct format: {requests: [...]}
      final responseBody = response.data;
      Map<String, dynamic> dataObj;

      if (responseBody is Map &&
          responseBody.containsKey('data') &&
          responseBody['data'] is Map) {
        dataObj = responseBody['data'] as Map<String, dynamic>;
      } else {
        dataObj = responseBody as Map<String, dynamic>;
      }

      final List<dynamic> requestsList = dataObj['requests'] ?? [];
      print('[BookingsDataSource] Found ${requestsList.length} requests');

      return requestsList
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[BookingsDataSource] Error loading requests: $e');
      throw Exception('Failed to load requests: $e');
    }
  }

  /// Get global booking requests (optionally filtered by serviceId or categoryId)
  Future<List<Booking>> getGlobalRequests(
      {int? serviceId, int? categoryId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (serviceId != null) queryParams['serviceId'] = serviceId;
      if (categoryId != null) queryParams['categoryId'] = categoryId;

      final response = await _dio.get('/provider/bookings/global',
          queryParameters: queryParams);

      // Handle nested response format
      final responseBody = response.data;
      Map<String, dynamic> dataObj;

      if (responseBody is Map &&
          responseBody.containsKey('data') &&
          responseBody['data'] is Map) {
        dataObj = responseBody['data'] as Map<String, dynamic>;
      } else {
        dataObj = responseBody as Map<String, dynamic>;
      }

      final List<dynamic> requestsList = dataObj['requests'] ?? [];
      return requestsList
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load global requests: $e');
    }
  }

  Future<Map<String, dynamic>> acceptBookingRequest(int bookingId) async {
    try {
      final response = await _dio.post('/provider/bookings/$bookingId/offer');
      print(
          '[BookingsDataSource] acceptBookingRequest response: ${response.data}');

      // Handle nested response format
      final responseBody = response.data;
      if (responseBody is Map && responseBody.containsKey('data')) {
        return responseBody['data'] as Map<String, dynamic>;
      }
      return responseBody as Map<String, dynamic>;
    } catch (e) {
      print('[BookingsDataSource] Error accepting request: $e');
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

  Future<Map<String, dynamic>> reviewBooking(
      String bookingId, int rating, String comment) async {
    try {
      print('[BookingsDataSource] Submitting review for booking $bookingId');
      print('[BookingsDataSource] Rating: $rating, Comment: $comment');

      final response = await _dio.post('/bookings/$bookingId/review', data: {
        'rating': rating,
        'comment': comment,
      });

      print(
          '[BookingsDataSource] Review submitted successfully: ${response.data}');

      // Handle nested response format
      final responseBody = response.data;
      if (responseBody is Map && responseBody.containsKey('data')) {
        return responseBody['data'] as Map<String, dynamic>;
      }
      return responseBody as Map<String, dynamic>;
    } on DioException catch (e) {
      print(
          '[BookingsDataSource] DioException submitting review: ${e.message}');
      print('[BookingsDataSource] Response data: ${e.response?.data}');
      throw Exception(
          'Failed to submit review: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('[BookingsDataSource] Error submitting review: $e');
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

  // Customer confirms service completion
  Future<Map<String, dynamic>> confirmCompletion(String bookingId) async {
    try {
      final response =
          await _dio.patch('/bookings/$bookingId/confirm-completion');
      final responseBody = response.data;
      if (responseBody is Map && responseBody.containsKey('data')) {
        return responseBody['data'] as Map<String, dynamic>;
      }
      return responseBody as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to confirm completion: $e');
    }
  }

  // Customer disputes service completion
  Future<Map<String, dynamic>> disputeBooking(
      String bookingId, String reason) async {
    try {
      final response = await _dio.patch('/bookings/$bookingId/dispute', data: {
        'reason': reason,
      });
      final responseBody = response.data;
      if (responseBody is Map && responseBody.containsKey('data')) {
        return responseBody['data'] as Map<String, dynamic>;
      }
      return responseBody as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to dispute booking: $e');
    }
  }
}
