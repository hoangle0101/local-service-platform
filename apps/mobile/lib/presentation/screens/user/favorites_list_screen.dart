import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/favorites_provider.dart';

/// Minimal, clean Favorites screen — prefers local `favoritesListStateProvider`.
class FavoritesListScreen extends ConsumerWidget {
  const FavoritesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localProviders = ref.watch(favoritesListStateProvider);

    Widget buildCard(Map<String, dynamic> provider) {
      final userIdValue = provider['userId'];
      final providerId = (userIdValue is String)
          ? int.tryParse(userIdValue) ?? 0
          : (userIdValue is int ? userIdValue : 0);
      if (providerId == 0) return const SizedBox.shrink();

      final displayName = provider['displayName'] as String? ?? 'Unknown';
      final avatarUrl = provider['avatarUrl'] as String?;

      return Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? Image.network(avatarUrl, width: 60, height: 60, fit: BoxFit.cover)
                    : Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.person)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(displayName, style: Theme.of(context).textTheme.titleMedium)),
              IconButton(
                onPressed: () async {
                  await ref.read(removeFavoriteProvider(providerId).future);
                  ref.invalidate(isFavoriteProvider(providerId));
                  ref.read(favoritesListRefreshProvider.notifier).state++;
                },
                icon: const Icon(Icons.favorite),
                color: Colors.red,
              ),
            ],
          ),
        ),
      );
    }

    if (localProviders.isNotEmpty) {
      final providers = localProviders;
      return Scaffold(
        appBar: AppBar(title: const Text('Favorite Providers')),
        body: ListView.builder(
          itemCount: providers.length,
          itemBuilder: (context, index) => buildCard(providers[index] as Map<String, dynamic>),
        ),
      );
    }

    // fallback to remote
    final favoritesAsync = ref.watch(favoriteProvidersProvider((page: 1, limit: 20)));

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Providers')),
      body: favoritesAsync.when(
        data: (favoritesData) {
          final providers = (favoritesData['providers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          if (providers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No favorite providers yet', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: providers.length,
            itemBuilder: (context, index) => buildCard(providers[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading favorites: $error')),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/favorites_provider.dart';

/// Minimal, clean Favorites screen — prefers local `favoritesListStateProvider`.
class FavoritesListScreen extends ConsumerWidget {
  const FavoritesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localProviders = ref.watch(favoritesListStateProvider);

    Widget buildCard(Map<String, dynamic> provider) {
      final userIdValue = provider['userId'];
      final providerId = (userIdValue is String)
          ? int.tryParse(userIdValue) ?? 0
          : (userIdValue is int ? userIdValue : 0);
      if (providerId == 0) return const SizedBox.shrink();

      final displayName = provider['displayName'] as String? ?? 'Unknown';
      final avatarUrl = provider['avatarUrl'] as String?;

      return Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? Image.network(avatarUrl, width: 60, height: 60, fit: BoxFit.cover)
                    : Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.person)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(displayName, style: Theme.of(context).textTheme.titleMedium)),
              IconButton(
                onPressed: () async {
                  await ref.read(removeFavoriteProvider(providerId).future);
                  ref.invalidate(isFavoriteProvider(providerId));
                  ref.read(favoritesListRefreshProvider.notifier).state++;
                },
                icon: const Icon(Icons.favorite),
                color: Colors.red,
              ),
            ],
          ),
        ),
      );
    }

    if (localProviders.isNotEmpty) {
      final providers = localProviders;
      return Scaffold(
        appBar: AppBar(title: const Text('Favorite Providers')),
        body: ListView.builder(
          itemCount: providers.length,
          itemBuilder: (context, index) => buildCard(providers[index] as Map<String, dynamic>),
        ),
      );
    }

    // fallback to remote
    final favoritesAsync = ref.watch(favoriteProvidersProvider((page: 1, limit: 20)));

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Providers')),
      body: favoritesAsync.when(
        data: (favoritesData) {
          final providers = (favoritesData['providers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          if (providers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No favorite providers yet', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: providers.length,
            itemBuilder: (context, index) => buildCard(providers[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading favorites: $error')),
      ),
    );
  }
}
            loading: () => Center(
              child = const CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => Center(
              child = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading favorites',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(Icons.person),
                                          ),
                                        )
                                      : Container(
                                          width = 60,
                                          height = 60,
                                          decoration = BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child = const Icon(Icons.person),
                                        ),
                                ),
                                SizedBox(width = 12),
                                // Provider info
                                Expanded(
                                  child = Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Name and verification
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              displayName ?? 'Unknown',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                          ),
                                          if (verificationStatus == 'verified')
                                            const Tooltip(
                                              message: 'Verified provider',
                                              child: Icon(
                                                Icons.verified,
                                                color: Colors.blue,
                                                size: 18,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Bio
                                      if (bio != null && bio.isNotEmpty)
                                        Text(
                                          bio,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      const SizedBox(height: 8),
                                      // Rating
                                      Row(
                                        children: [
                                          ...List.generate(
                                            5,
                                            (i) => Icon(
                                              i < ratingAvg.toInt()
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.amber,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${ratingAvg.toStringAsFixed(1)} (${ratingCount ?? 0} reviews)',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Remove favorite button
                                IconButton(
                                  onPressed = () {
                                    _onRemoveFavorite(
                                      providerId,
                                      displayName ?? 'Provider',
                                    );
                                  },
                                  icon = const Icon(Icons.favorite),
                                  color = Colors.red,
                                  splashRadius = 24,
                                ),
                              ],
                            ),
                            // Services section
                            SizedBox(height = 12),
                            if (provider['services'] != null &&
                                (provider['services'] as List).isNotEmpty)
                              Column(
                                crossAxisAlignment = CrossAxisAlignment.start,
                                children = [
                                  Text(
                                    'Services:',
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: (provider['services'] as List)
                                        .map((service) {
                                      final serviceName =
                                          service['serviceName'] as String?;
                                      final price = service['price'];
                                      return Chip(
                                        label: Text(
                                          serviceName != null
                                              ? '$serviceName - \$${price ?? '0'}'
                                              : '\$${price ?? '0'}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall,
                                        ),
                                        backgroundColor: Colors.blue.shade50,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            // Book again button
                            SizedBox(height = 12),
                            SizedBox(
                              width = double.infinity,
                              child = ElevatedButton.icon(
                                onPressed: () {
                                  // TODO: Navigate to booking flow with provider pre-selected
                                  // context.pushNamed('book-service', pathParameters: {'providerId': providerId.toString()});
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Book Service'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Load more button
                if (currentPage < totalPages)
                  Padding(
                    padding = const EdgeInsets.all(16.0),
                    child = ElevatedButton.icon(
                      onPressed: _loadMoreFavorites,
                      icon: const Icon(Icons.add),
                      label: const Text('Load More'),
                    ),
                  )
                else if (providers.isNotEmpty)
                  Padding(
                    padding = const EdgeInsets.all(16.0),
                    child = Text(
                      'No more providers',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => Center(
          child = const CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading favorites',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
