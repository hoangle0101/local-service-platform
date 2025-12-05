import 'package:equatable/equatable.dart';
import '../../../core/entities/entities.dart';

// Events
abstract class ServicesEvent extends Equatable {
  const ServicesEvent();

  @override
  List<Object?> get props => [];
}

class LoadServices extends ServicesEvent {
  final int limit;

  const LoadServices({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

// States
abstract class ServicesState extends Equatable {
  const ServicesState();

  @override
  List<Object?> get props => [];
}

class ServicesInitial extends ServicesState {}

class ServicesLoading extends ServicesState {}

class ServicesLoaded extends ServicesState {
  final List<ProviderService> services;

  const ServicesLoaded(this.services);

  @override
  List<Object?> get props => [services];
}

class ServicesError extends ServicesState {
  final String message;

  const ServicesError(this.message);

  @override
  List<Object?> get props => [message];
}
