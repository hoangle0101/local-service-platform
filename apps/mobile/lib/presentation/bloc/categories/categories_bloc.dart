import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entities/entities.dart';
import '../../../data/datasources/marketplace_datasource.dart';
import 'categories_event_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final MarketplaceDataSource _marketplaceDataSource = MarketplaceDataSource();

  CategoriesBloc() : super(CategoriesInitial()) {
    on<LoadCategories>(_onLoadCategories);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());
    try {
      print('[CategoriesBloc] Loading categories...');
      final categories = await _marketplaceDataSource.getCategories();
      print('[CategoriesBloc] Loaded ${categories.length} categories');
      emit(CategoriesLoaded(categories));
    } catch (e, stackTrace) {
      print('[CategoriesBloc] ERROR: $e');
      print('[CategoriesBloc] Stack: $stackTrace');
      emit(CategoriesError(e.toString()));
    }
  }
}
