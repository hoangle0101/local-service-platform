import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/favorites_datasource.dart';

// Events
abstract class FavoritesEvent {}

class LoadFavorites extends FavoritesEvent {}

class ToggleFavorite extends FavoritesEvent {
  final int serviceId;
  ToggleFavorite(this.serviceId);
}

class RemoveFavorite extends FavoritesEvent {
  final int serviceId;
  RemoveFavorite(this.serviceId);
}

// States
abstract class FavoritesState {
  final Set<int> favoriteIds;
  const FavoritesState({this.favoriteIds = const {}});
}

class FavoritesInitial extends FavoritesState {
  const FavoritesInitial() : super();
}

class FavoritesLoading extends FavoritesState {
  const FavoritesLoading({super.favoriteIds});
}

class FavoritesLoaded extends FavoritesState {
  final List<FavoriteItem> items;

  const FavoritesLoaded({
    required this.items,
    required Set<int> favoriteIds,
  }) : super(favoriteIds: favoriteIds);
}

class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError({
    required this.message,
    super.favoriteIds,
  });
}

// BLoC
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoritesDataSource _dataSource;

  FavoritesBloc({FavoritesDataSource? dataSource})
      : _dataSource = dataSource ?? FavoritesDataSource(),
        super(const FavoritesInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<ToggleFavorite>(_onToggleFavorite);
    on<RemoveFavorite>(_onRemoveFavorite);
  }

  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(FavoritesLoading(favoriteIds: state.favoriteIds));

    try {
      final items = await _dataSource.getFavorites();
      final favoriteIds = items.map((item) => item.serviceId).toSet();

      emit(FavoritesLoaded(items: items, favoriteIds: favoriteIds));
    } catch (e) {
      emit(FavoritesError(
        message: e.toString(),
        favoriteIds: state.favoriteIds,
      ));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<FavoritesState> emit,
  ) async {
    final isFavorite = state.favoriteIds.contains(event.serviceId);

    // Optimistic update
    final newFavoriteIds = Set<int>.from(state.favoriteIds);
    if (isFavorite) {
      newFavoriteIds.remove(event.serviceId);
    } else {
      newFavoriteIds.add(event.serviceId);
    }

    // Emit optimistic state
    if (state is FavoritesLoaded) {
      final currentItems = (state as FavoritesLoaded).items;
      emit(FavoritesLoaded(
        items: isFavorite
            ? currentItems.where((i) => i.serviceId != event.serviceId).toList()
            : currentItems,
        favoriteIds: newFavoriteIds,
      ));
    } else {
      emit(FavoritesLoading(favoriteIds: newFavoriteIds));
    }

    // Perform API call
    bool success;
    if (isFavorite) {
      success = await _dataSource.removeFavorite(event.serviceId);
    } else {
      success = await _dataSource.addFavorite(event.serviceId);
    }

    // Revert on failure
    if (!success) {
      if (state is FavoritesLoaded) {
        emit(FavoritesLoaded(
          items: (state as FavoritesLoaded).items,
          favoriteIds: state.favoriteIds,
        ));
      }
    }
  }

  Future<void> _onRemoveFavorite(
    RemoveFavorite event,
    Emitter<FavoritesState> emit,
  ) async {
    // Optimistic update
    final newFavoriteIds = Set<int>.from(state.favoriteIds)
      ..remove(event.serviceId);

    if (state is FavoritesLoaded) {
      final currentItems = (state as FavoritesLoaded).items;
      emit(FavoritesLoaded(
        items:
            currentItems.where((i) => i.serviceId != event.serviceId).toList(),
        favoriteIds: newFavoriteIds,
      ));
    }

    await _dataSource.removeFavorite(event.serviceId);
  }

  /// Check if a service is favorited
  bool isFavorite(int serviceId) => state.favoriteIds.contains(serviceId);
}
