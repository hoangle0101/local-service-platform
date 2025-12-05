import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/entities.dart';
import '../../../data/datasources/marketplace_datasource.dart';
import 'services_event_state.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final MarketplaceDataSource _marketplaceDataSource = MarketplaceDataSource();

  ServicesBloc() : super(ServicesInitial()) {
    on<LoadServices>(_onLoadServices);
    on<LoadServicesByCategory>(_onLoadServicesByCategory);
    on<LoadServiceDetails>(_onLoadServiceDetails);
  }

  Future<void> _onLoadServices(
    LoadServices event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());
    try {
      final services =
          await _marketplaceDataSource.searchServices(limit: event.limit);
      emit(ServicesLoaded(services));
    } catch (e) {
      emit(ServicesError(e.toString()));
    }
  }

  Future<void> _onLoadServicesByCategory(
    LoadServicesByCategory event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());
    try {
      final services = await _marketplaceDataSource.searchServices(
        limit: event.limit,
        categoryId: event.categoryId,
      );
      emit(ServicesLoaded(services));
    } catch (e) {
      emit(ServicesError(e.toString()));
    }
  }

  Future<void> _onLoadServiceDetails(
    LoadServiceDetails event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());
    try {
      final service =
          await _marketplaceDataSource.getServiceById(event.serviceId);
      emit(ServiceDetailsLoaded(service));
    } catch (e) {
      emit(ServicesError(e.toString()));
    }
  }
}
