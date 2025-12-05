import 'package:equatable/equatable.dart';

// ========== EVENTS ==========

abstract class BookingsEvent extends Equatable {
  const BookingsEvent();

  @override
  List<Object?> get props => [];
}

// User Events
class LoadUserBookingsEvent extends BookingsEvent {
  final String? status;

  const LoadUserBookingsEvent({this.status});

  @override
  List<Object?> get props => [status];
}

// Alias for backward compatibility
class LoadBookings extends BookingsEvent {
  const LoadBookings();
}

class CreateBookingEvent extends BookingsEvent {
  final int serviceId;
  final DateTime scheduledAt;
  final String addressText;
  final double latitude;
  final double longitude;
  final String? notes;

  const CreateBookingEvent({
    required this.serviceId,
    required this.scheduledAt,
    required this.addressText,
    required this.latitude,
    required this.longitude,
    this.notes,
  });

  @override
  List<Object?> get props =>
      [serviceId, scheduledAt, addressText, latitude, longitude, notes];
}

class LoadBookingOffersEvent extends BookingsEvent {
  final int bookingId;

  const LoadBookingOffersEvent(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class SelectProviderEvent extends BookingsEvent {
  final int bookingId;
  final int providerId;

  const SelectProviderEvent(this.bookingId, this.providerId);

  @override
  List<Object?> get props => [bookingId, providerId];
}

class CancelBooking extends BookingsEvent {
  final String bookingId;
  final String? reason;

  const CancelBooking(this.bookingId, [this.reason]);

  @override
  List<Object?> get props => [bookingId, reason];
}

class ReviewBooking extends BookingsEvent {
  final String bookingId;
  final int rating;
  final String comment;

  const ReviewBooking(this.bookingId, this.rating, this.comment);

  @override
  List<Object?> get props => [bookingId, rating, comment];
}

// Provider Events
class LoadProviderBookings extends BookingsEvent {
  const LoadProviderBookings();
}

class LoadProviderRequestsEvent extends BookingsEvent {
  const LoadProviderRequestsEvent();
}

class AcceptBookingRequestEvent extends BookingsEvent {
  final int bookingId;

  const AcceptBookingRequestEvent(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

// Alias for backward compatibility
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

// ========== STATES ==========

abstract class BookingsState extends Equatable {
  const BookingsState();

  @override
  List<Object?> get props => [];
}

class BookingsInitial extends BookingsState {}

class BookingsLoading extends BookingsState {}

// Main loaded state for list of bookings
class BookingsLoaded extends BookingsState {
  final List<Booking> bookings;

  const BookingsLoaded(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

class BookingCreated extends BookingsState {
  final String bookingId;
  final String bookingCode;
  final List<String> nearbyProviderIds;

  const BookingCreated({
    required this.bookingId,
    required this.bookingCode,
    required this.nearbyProviderIds,
  });

  @override
  List<Object?> get props => [bookingId, bookingCode, nearbyProviderIds];
}

class BookingOffersLoaded extends BookingsState {
  final List<BookingOffer> offers;

  const BookingOffersLoaded(this.offers);

  @override
  List<Object?> get props => [offers];
}

class ProviderSelected extends BookingsState {
  final String bookingId;
  final String providerId;

  const ProviderSelected(this.bookingId, this.providerId);

  @override
  List<Object?> get props => [bookingId, providerId];
}

class UserBookingsLoaded extends BookingsState {
  final List<Booking> bookings;

  const UserBookingsLoaded(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

class ProviderRequestsLoaded extends BookingsState {
  final List<Booking> requests;

  const ProviderRequestsLoaded(this.requests);

  @override
  List<Object?> get props => [requests];
}

class BookingOfferSent extends BookingsState {
  final String offerId;

  const BookingOfferSent(this.offerId);

  @override
  List<Object?> get props => [offerId];
}

class BookingActionSuccess extends BookingsState {
  final String message;

  const BookingActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class BookingsError extends BookingsState {
  final String message;

  const BookingsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ========== HELPER MODELS ==========

class BookingOffer {
  final int id;
  final int bookingId;
  final int providerId;
  final String providerName;
  final double? rating;
  final double price;
  final String status;

  BookingOffer({
    required this.id,
    required this.bookingId,
    required this.providerId,
    required this.providerName,
    this.rating,
    required this.price,
    required this.status,
  });

  factory BookingOffer.fromJson(Map<String, dynamic> json) {
    return BookingOffer(
      id: int.parse(json['id'].toString()),
      bookingId: int.parse(json['bookingId'].toString()),
      providerId: int.parse(json['providerId'].toString()),
      providerName: json['providerName'] ?? 'Unknown',
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString())
          : null,
      price: double.parse(json['price'].toString()),
      status: json['status'],
    );
  }
}

class Booking {
  final String id;
  final String code;
  final String status;
  final DateTime scheduledAt;
  final String addressText;
  final double? estimatedPrice;
  final String serviceName;
  final String? providerName;
  final String? customerName;

  Booking({
    required this.id,
    required this.code,
    required this.status,
    required this.scheduledAt,
    required this.addressText,
    this.estimatedPrice,
    required this.serviceName,
    this.providerName,
    this.customerName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'].toString(),
      code: json['code'] ?? '',
      status: json['status'] ?? 'pending',
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'])
          : DateTime.now(),
      addressText: json['addressText'] ?? '',
      estimatedPrice: json['estimatedPrice'] != null
          ? double.tryParse(json['estimatedPrice'].toString())
          : null,
      serviceName:
          json['service']?['name'] ?? json['serviceName'] ?? 'Unknown Service',
      providerName: json['provider']?['fullName'] ?? json['providerName'],
      customerName: json['customer']?['fullName'] ?? json['customerName'],
    );
  }
}
