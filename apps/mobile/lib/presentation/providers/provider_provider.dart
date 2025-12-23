import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'review_provider.dart';

// Get provider statistics using review API with userId
// This is a FamilyProvider that takes userId as a parameter
final providerStatisticsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, userId) async {
  final dataSource = ref.watch(reviewDataSourceProvider);

  print('[providerStatisticsProvider] Fetching stats for userId: $userId');

  try {
    final result = await dataSource.getProviderStatistics(userId);
    print('[providerStatisticsProvider] API result: $result');
    return result;
  } catch (e) {
    print('[providerStatisticsProvider] Error fetching stats: $e');
    rethrow;
  }
});

// Extract rating from statistics provider
final providerRatingProvider =
    FutureProvider.family<double, int>((ref, userId) async {
  try {
    final stats = await ref.watch(providerStatisticsProvider(userId).future);
    print('[providerRatingProvider] Stats: $stats');

    final rating = stats['averageRating'];
    print(
        '[providerRatingProvider] Raw rating value: $rating (type: ${rating.runtimeType})');

    if (rating is String) {
      return double.parse(rating);
    }
    return (rating as num).toDouble();
  } catch (e) {
    print('[providerRatingProvider] Error parsing rating: $e');
    return 0.0;
  }
});

// Completed count provider - returns 0 as placeholder
final providerCompletedCountProvider =
    FutureProvider.family<int, int>((ref, userId) async {
  // Note: Backend doesn't provide completedCount in review stats
  // This would need to come from a separate booking API
  // For now, return 0 as placeholder
  return 0;
});

// Extract review count from statistics provider
final providerReviewCountProvider =
    FutureProvider.family<int, int>((ref, userId) async {
  try {
    final stats = await ref.watch(providerStatisticsProvider(userId).future);
    final count = stats['totalReviews'];
    print('[providerReviewCountProvider] Review count: $count');
    return (count as int?) ?? 0;
  } catch (e) {
    print('[providerReviewCountProvider] Error: $e');
    return 0;
  }
});
