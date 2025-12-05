import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/booking_entity.dart';
import '../../../data/datasources/bookings_datasource.dart';
import 'bookings_event_state.dart';

class BookingsBloc extends Bloc<BookingsEvent, BookingsState> {
  final BookingsDataSource _bookingsDataSource = BookingsDataSource();

  BookingsBloc() : super(BookingsInitial()) {
    on<LoadBookings>(_onLoadBookings);
    on<LoadProviderBookings>(_onLoadProviderBookings);
    on<CancelBooking>(_onCancelBooking);
    on<ReviewBooking>(_onReviewBooking);
    on<AcceptBooking>(_onAcceptBooking);
    on<StartService>(_onStartService);
    on<CompleteService>(_onCompleteService);
  }

  Future<void> _onLoadBookings(
    LoadBookings event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    try {
      final bookings = await _bookingsDataSource.getBookings();
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
      final bookings = await _bookingsDataSource.getProviderBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onCancelBooking(
    CancelBooking event,
    Emitter<BookingsState> emit,
  ) async {
    try {
      await _bookingsDataSource.cancelBooking(event.bookingId);
      // Reload bookings
      final bookings = await _bookingsDataSource.getBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onReviewBooking(
    ReviewBooking event,
    Emitter<BookingsState> emit,
  ) async {
    try {
      await _bookingsDataSource.reviewBooking(
        event.bookingId,
        event.rating,
        event.comment,
      );
      // Reload bookings
      final bookings = await _bookingsDataSource.getBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onAcceptBooking(
    AcceptBooking event,
    Emitter<BookingsState> emit,
  ) async {
    try {
      await _bookingsDataSource.acceptBooking(event.bookingId);
      // Reload provider bookings
      final bookings = await _bookingsDataSource.getProviderBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onStartService(
    StartService event,
    Emitter<BookingsState> emit,
  ) async {
    try {
      await _bookingsDataSource.startService(event.bookingId);
      // Reload provider bookings
      final bookings = await _bookingsDataSource.getProviderBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onCompleteService(
    CompleteService event,
    Emitter<BookingsState> emit,
  ) async {
    try {
      await _bookingsDataSource.completeService(event.bookingId);
      // Reload provider bookings
      final bookings = await _bookingsDataSource.getProviderBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }
}
