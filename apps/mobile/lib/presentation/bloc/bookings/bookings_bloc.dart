import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/bookings_datasource.dart';
import 'bookings_event_state.dart';

class BookingsBloc extends Bloc<BookingsEvent, BookingsState> {
  final BookingsDataSource _dataSource = BookingsDataSource();

  BookingsBloc() : super(BookingsInitial()) {
    on<LoadBookings>(_onLoadBookings);
    on<LoadUserBookingsEvent>(_onLoadUserBookings);
    on<CreateBookingEvent>(_onCreateBooking);
    on<LoadBookingOffersEvent>(_onLoadBookingOffers);
    on<SelectProviderEvent>(_onSelectProvider);
    on<CancelBooking>(_onCancelBooking);
    on<ReviewBooking>(_onReviewBooking);
    on<LoadProviderBookings>(_onLoadProviderBookings);
    on<LoadProviderRequestsEvent>(_onLoadProviderRequests);
    on<AcceptBookingRequestEvent>(_onAcceptBookingRequest);
    on<AcceptBooking>(_onAcceptBookingLegacy);
    on<StartService>(_onStartService);
    on<CompleteService>(_onCompleteService);
  }

  Future<void> _onLoadBookings(
    LoadBookings event,
    Emitter<BookingsState> emit,
  ) async {
    print('[BookingsBloc] _onLoadBookings called');
    emit(BookingsLoading());
    try {
      final bookings = await _dataSource.getUserBookings();
      print('[BookingsBloc] Loaded ${bookings.length} bookings');
      emit(BookingsLoaded(bookings));
      print('[BookingsBloc] Emitted BookingsLoaded state');
    } catch (e) {
      print('[BookingsBloc] Error loading bookings: $e');
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onLoadUserBookings(
    LoadUserBookingsEvent event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    try {
      final bookings = await _dataSource.getUserBookings(status: event.status);
      emit(UserBookingsLoaded(bookings));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onCreateBooking(
    CreateBookingEvent event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    try {
      final result = await _dataSource.createBooking(
        serviceId: event.serviceId,
        scheduledAt: event.scheduledAt,
        addressText: event.addressText,
        latitude: event.latitude,
        longitude: event.longitude,
        notes: event.notes,
        providerId: event.providerId, // Pass providerId for direct booking
      );

      // Safely extract values with proper null handling and type conversion
      final String bookingId = (result['id'] ?? '').toString();
      final String bookingCode = (result['code'] ?? 'N/A').toString();
      final rawProviderIds = result['nearbyProviderIds'];
      final List<String> nearbyProviderIds = rawProviderIds != null
          ? (rawProviderIds as List).map((e) => e.toString()).toList()
          : <String>[];
      final bool isDirectBooking = result['isDirectBooking'] == true;
      final String? providerId = result['providerId']?.toString();

      emit(BookingCreated(
        bookingId: bookingId,
        bookingCode: bookingCode,
        nearbyProviderIds: nearbyProviderIds,
        isDirectBooking: isDirectBooking,
        providerId: providerId,
      ));
    } catch (e) {
      emit(BookingsError('Failed to create booking: ${e.toString()}'));
    }
  }

  Future<void> _onLoadBookingOffers(
    LoadBookingOffersEvent event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    try {
      final offers = await _dataSource.getBookingOffers(event.bookingId);
      emit(BookingOffersLoaded(offers));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onSelectProvider(
    SelectProviderEvent event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    try {
      final result = await _dataSource.selectProvider(
        event.bookingId,
        event.providerId,
      );
      emit(ProviderSelected(
        result['bookingId'],
        result['providerId'],
      ));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onCancelBooking(
    CancelBooking event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    try {
      await _dataSource.cancelBooking(event.bookingId, event.reason);
      emit(const BookingActionSuccess('Booking cancelled successfully'));
      // Reload bookings
      final bookings = await _dataSource.getUserBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onReviewBooking(
    ReviewBooking event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    try {
      await _dataSource.reviewBooking(
          event.bookingId, event.rating, event.comment);
      emit(const BookingActionSuccess('Review submitted successfully'));
      // Reload bookings
      final bookings = await _dataSource.getUserBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onLoadProviderBookings(
    LoadProviderBookings event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    try {
      final bookings = await _dataSource.getProviderBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onLoadProviderRequests(
    LoadProviderRequestsEvent event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    try {
      final requests = await _dataSource.getProviderRequests();
      emit(ProviderRequestsLoaded(requests));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onAcceptBookingRequest(
    AcceptBookingRequestEvent event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    try {
      final result = await _dataSource.acceptBookingRequest(event.bookingId);
      emit(BookingOfferSent(result['offerId']));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onAcceptBookingLegacy(
    AcceptBooking event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    try {
      await _dataSource.acceptBookingLegacy(event.bookingId);
      emit(const BookingActionSuccess('Booking accepted'));
      // Reload bookings
      final bookings = await _dataSource.getProviderBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onStartService(
    StartService event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    try {
      await _dataSource.startService(event.bookingId);
      emit(const BookingActionSuccess('Service started'));
      // Reload bookings
      final bookings = await _dataSource.getProviderBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onCompleteService(
    CompleteService event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    try {
      await _dataSource.completeService(event.bookingId);
      emit(const BookingActionSuccess('Service completed'));
      // Reload bookings
      final bookings = await _dataSource.getProviderBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }
}
