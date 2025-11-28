import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/marketplace_datasource.dart';
import 'categories_event_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final MarketplaceDataSource dataSource;

  CategoriesBloc({required this.dataSource}) : super(CategoriesInitial()) {
    on<LoadCategories>(_onLoadCategories);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());
    try {
      final categories = await dataSource.getCategories();
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }
}
