import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/favorites_datasource.dart';

// DataSource provider
final favoritesDataSourceProvider = Provider<FavoritesDataSource>((ref) {
  return FavoritesDataSource();
});

// Favorites list provider - Returns list of favorite providers with pagination
final favoriteProvidersProvider =
    FutureProvider.family<Map<String, dynamic>, ({int page, int limit})>(
  (ref, params) async {
    // Depend on the global refresh trigger so we can force refetches.
    ref.watch(favoritesListRefreshProvider);
    final dataSource = ref.watch(favoritesDataSourceProvider);
    final result = await dataSource.getFavoriteProviders(
        page: params.page, limit: params.limit);
    return result;
  },
);

// Provider to check if a specific provider is favorited
final isFavoriteProvider =
    FutureProvider.family<bool, int>((ref, providerId) async {
  print('[isFavoriteProvider] Checking favorite for providerId: $providerId');

  final dataSource = ref.watch(favoritesDataSourceProvider);
  final isFavorite = await dataSource.checkFavoriteProvider(providerId);

  print(
      '[isFavoriteProvider] Result: providerId=$providerId, isFavorite=$isFavorite');
  return isFavorite;
});

// Provider for add favorite - callable from event handler
final addFavoriteProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, providerId) async {
  print('[addFavoriteProvider] Adding favorite for providerId: $providerId');

  final dataSource = ref.watch(favoritesDataSourceProvider);
  final result = await dataSource.addFavoriteProvider(providerId);

  print('[addFavoriteProvider] Success! Result: $result');
  return result;
});

// Provider for remove favorite - callable from event handler
final removeFavoriteProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, providerId) async {
  print(
      '[removeFavoriteProvider] Removing favorite for providerId: $providerId');

  final dataSource = ref.watch(favoritesDataSourceProvider);
  final result = await dataSource.removeFavoriteProvider(providerId);

  print('[removeFavoriteProvider] Success! Result: $result');
  return result ?? {};
});

// Simple in-memory cache for favorite flags to enable optimistic UI updates.
final favoritesCacheProvider = StateProvider<Map<int, bool>>((ref) => {});

// Trigger to force refresh of favorites list across the app.
final favoritesListRefreshProvider = StateProvider<int>((ref) => 0);

// Local in-memory list of favorite provider payloads to allow immediate
// UI updates on the Favorites screen without waiting for remote fetch.
final favoritesListStateProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

// Locks to prevent concurrent toggle operations per providerId
final favoritesToggleLockProvider = StateProvider<Map<int, bool>>((ref) => {});

// Controller to toggle favorites with optimistic update
class FavoritesController {
  final Ref ref;
  FavoritesController(this.ref);

  Future<void> toggleFavorite(int providerId) async {
    // Prevent concurrent toggles for the same provider
    final lockNotifier = ref.read(favoritesToggleLockProvider.notifier);
    final locks = Map<int, bool>.from(lockNotifier.state);
    if (locks[providerId] == true) {
      print(
          '[FavoritesController] toggle ignored - lock active for $providerId');
      return;
    }
    locks[providerId] = true;
    lockNotifier.state = locks;

    final cacheNotifier = ref.read(favoritesCacheProvider.notifier);
    final currentCache = Map<int, bool>.from(cacheNotifier.state);

    // Determine current value (from cache or remote)
    bool current = currentCache[providerId] ??
        await ref.read(isFavoriteProvider(providerId).future);

    final newValue = !current;

    // Optimistic update
    currentCache[providerId] = newValue;
    cacheNotifier.state = currentCache;

    try {
      Map<String, dynamic>? opResult;
      if (newValue) {
        opResult = await ref.read(addFavoriteProvider(providerId).future);
        print('[FavoritesController] addFavorite opResult: $opResult');
      } else {
        opResult = await ref.read(removeFavoriteProvider(providerId).future);
        print('[FavoritesController] removeFavorite opResult: $opResult');
      }

      // Refresh remote-backed providers (trigger a new fetch)
      ref.refresh(isFavoriteProvider(providerId));
      // Wait for the refreshed value to be available
      await ref.read(isFavoriteProvider(providerId).future);
      // Refresh the currently relevant favorites page (page 1) and update
      // the local in-memory favorites list with the authoritative server
      // payload. This avoids brute-force invalidating many pages which
      // causes racing requests and empty responses.
      try {
        // If the add/remove endpoint returned the provider payload, use it
        // to update local state immediately and avoid an extra page fetch.
        final providerPayload =
            opResult != null && opResult.containsKey('provider')
                ? (opResult['provider'] as Map<String, dynamic>?)
                : null;

        if (providerPayload != null) {
          final favNotifier = ref.read(favoritesListStateProvider.notifier);
          // Normalize userId to string for stable comparison/storage
          providerPayload['userId'] = providerPayload['userId'].toString();

          if (newValue) {
            final exists = favNotifier.state.any(
                (p) => p['userId'].toString() == providerPayload['userId']);
            if (!exists) {
              favNotifier.state = [...favNotifier.state, providerPayload];
            }
          } else {
            favNotifier.state = favNotifier.state
                .where(
                    (p) => p['userId'].toString() != providerPayload['userId'])
                .toList();
          }
        } else {
          // Fallback: refresh page 1 and replace local list with server payload
          ref.invalidate(favoriteProvidersProvider((page: 1, limit: 20)));
          final pageData = await ref
              .read(favoriteProvidersProvider((page: 1, limit: 20)).future);

          final providers = (pageData['providers'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              <Map<String, dynamic>>[];

          ref.read(favoritesListStateProvider.notifier).state = providers;
        }
      } catch (e) {
        // If fetching the refreshed page fails, still bump the trigger
        // so UI consumers can decide how to react.
        print('[FavoritesController] Failed to refresh favorites page: $e');
      }

      // Bump the global refresh trigger so any listeners refetch if needed.
      final notifier = ref.read(favoritesListRefreshProvider.notifier);
      notifier.state = notifier.state + 1;
      print(
          '[FavoritesController] Bumped favoritesListRefreshProvider to ${notifier.state}');
    } catch (e) {
      // Revert on failure
      currentCache[providerId] = current;
      cacheNotifier.state = currentCache;
      rethrow;
    } finally {
      // Release lock
      final lockNotifier2 = ref.read(favoritesToggleLockProvider.notifier);
      final locks2 = Map<int, bool>.from(lockNotifier2.state);
      locks2[providerId] = false;
      lockNotifier2.state = locks2;
    }
  }
}

final favoritesControllerProvider = Provider((ref) => FavoritesController(ref));
