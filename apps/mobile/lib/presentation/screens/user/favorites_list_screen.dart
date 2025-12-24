import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/favorites_provider.dart';

/// Modern Minimalist Favorites screen
class FavoritesListScreen extends ConsumerWidget {
  const FavoritesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localProviders = ref.watch(favoritesListStateProvider);

    // If we have local state, use it
    if (localProviders.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Thợ yêu thích',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: localProviders.length,
          itemBuilder: (context, index) =>
              _buildProviderCard(context, ref, localProviders[index]),
        ),
      );
    }

    // Fallback to remote fetch
    final favoritesAsync =
        ref.watch(favoriteProvidersProvider((page: 1, limit: 20)));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Thợ yêu thích',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: favoritesAsync.when(
        data: (favoritesData) {
          final providers = (favoritesData['providers'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [];

          if (providers.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: providers.length,
            itemBuilder: (context, index) =>
                _buildProviderCard(context, ref, providers[index]),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => _buildErrorState(context, error.toString()),
      ),
    );
  }

  Widget _buildProviderCard(
      BuildContext context, WidgetRef ref, Map<String, dynamic> provider) {
    final userIdValue = provider['userId'];
    final providerId = (userIdValue is String)
        ? int.tryParse(userIdValue) ?? 0
        : (userIdValue is int ? userIdValue : 0);

    if (providerId == 0) return const SizedBox.shrink();

    final displayName = provider['displayName'] as String? ?? 'Không tên';
    final avatarUrl = provider['avatarUrl'] as String?;
    final bio = provider['bio'] as String?;
    final ratingAvg = (provider['ratingAvg'] as num?)?.toDouble() ?? 0.0;
    final ratingCount = provider['ratingCount'] as int? ?? 0;
    final verificationStatus = provider['verificationStatus'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (verificationStatus == 'verified')
                            const Icon(
                              Icons.verified_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${ratingAvg.toStringAsFixed(1)} ($ratingCount đánh giá)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Remove favorite button
                IconButton(
                  onPressed: () async {
                    await ref.read(removeFavoriteProvider(providerId).future);
                    ref.invalidate(isFavoriteProvider(providerId));
                    ref.read(favoritesListRefreshProvider.notifier).state++;
                    // Remove from local list immediately
                    final notifier =
                        ref.read(favoritesListStateProvider.notifier);
                    notifier.state = notifier.state
                        .where((p) =>
                            p['userId'].toString() != providerId.toString())
                        .toList();
                  },
                  icon: const Icon(Icons.favorite_rounded),
                  color: AppColors.error,
                ),
              ],
            ),
            // Bio
            if (bio != null && bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                bio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            // Services
            if (provider['services'] != null &&
                (provider['services'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (provider['services'] as List).take(3).map((service) {
                  final serviceName = service['serviceName'] as String? ?? '';
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.shelf,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      serviceName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.shelf.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_outline_rounded,
              size: 64,
              color: AppColors.textTertiary.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có thợ yêu thích',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Thêm thợ vào danh sách yêu thích để đặt dịch vụ nhanh hơn',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          const Text(
            'Không thể tải dữ liệu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
