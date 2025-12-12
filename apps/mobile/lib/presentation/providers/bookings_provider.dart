import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/datasources/bookings_datasource.dart';
import '../../presentation/bloc/bookings/bookings_event_state.dart';

// ============================================
// PROVIDERS - CORE DEPENDENCIES
// ============================================

/// Dio instance provider (assuming you have this)
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl:
          'http://10.0.2.2:3000', // Android emulator: use 10.0.2.2 instead of localhost
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
});

/// BookingsDataSource provider
final bookingsDataSourceProvider = Provider<BookingsDataSource>((ref) {
  return BookingsDataSource();
});

// ============================================
// FUTURE PROVIDERS - DATA FETCHING
// ============================================

/// Fetch a single booking by ID with full details including review
final bookingDetailProvider =
    FutureProvider.family<Booking, String>((ref, bookingId) async {
  final dataSource = ref.watch(bookingsDataSourceProvider);
  return dataSource.getBookingById(bookingId);
});

/// Fetch user bookings with optional status filter
final userBookingsProvider =
    FutureProvider.family<List<Booking>, String?>((ref, status) async {
  final dataSource = ref.watch(bookingsDataSourceProvider);
  return dataSource.getUserBookings(status: status);
});

/// Fetch provider bookings with optional status filter
final providerBookingsProvider =
    FutureProvider.family<List<Booking>, String?>((ref, status) async {
  final dataSource = ref.watch(bookingsDataSourceProvider);
  return dataSource.getProviderBookings(status: status);
});
