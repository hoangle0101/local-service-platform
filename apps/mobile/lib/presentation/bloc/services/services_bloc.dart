import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/marketplace_datasource.dart';
import 'services_event_state.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final MarketplaceDataSource dataSource;

  ServicesBloc({required this.dataSource}) : super(ServicesInitial()) {
    on<LoadServices>(_onLoadServices);
  }

  Future<void> _onLoadServices(
    LoadServices event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());
    try {
      final services = await dataSource.searchServices(limit: event.limit);
      emit(ServicesLoaded(services));
    } catch (e) {
      emit(ServicesError(e.toString()));
    }
  }
}
