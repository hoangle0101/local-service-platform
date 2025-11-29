import 'package:equatable/equatable.dart';
import '../../../core/entities/booking_entity.dart';

// Events
abstract class BookingsEvent extends Equatable {
  const BookingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadBookings extends BookingsEvent {}

class LoadProviderBookings extends BookingsEvent {}

class CancelBooking extends BookingsEvent {
  final String bookingId;

  const CancelBooking(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class ReviewBooking extends BookingsEvent {
  final String bookingId;
  final int rating;
  final String? comment;

  const ReviewBooking(this.bookingId, this.rating, [this.comment]);

  @override
  List<Object?> get props => [bookingId, rating, comment];
}

class AcceptBooking extends BookingsEvent {
  final String bookingId;

  const AcceptBooking(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class StartService extends BookingsEvent {
  final String bookingId;

  const StartService(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class CompleteService extends BookingsEvent {
  final String bookingId;

  const CompleteService(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

// States
abstract class BookingsState extends Equatable {
  const BookingsState();

  @override
  List<Object?> get props => [];
}

class BookingsInitial extends BookingsState {}

class BookingsLoading extends BookingsState {}

class BookingsLoaded extends BookingsState {
  final List<BookingEntity> bookings;

  const BookingsLoaded(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

class BookingsError extends BookingsState {
  final String message;

  const BookingsError(this.message);

  @override
  List<Object?> get props => [message];
}
