import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/datasources/review_datasource.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository.dart';

// ============================================
// PROVIDERS - CORE DEPENDENCIES
// ============================================

/// Dio instance provider (assuming you have this)
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl:
          'http://10.0.2.2:3000', // Android emulator: use 10.0.2.2 instead of localhost
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
});

/// ReviewDataSource provider
final reviewDataSourceProvider = Provider<ReviewDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return ReviewDataSource(dio: dio);
});

/// ReviewRepository provider
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final dataSource = ref.watch(reviewDataSourceProvider);
  return ReviewRepository(dataSource: dataSource);
});

// ============================================
// FUTURE PROVIDERS - DATA FETCHING
// ============================================

/// Fetch reviews for a specific booking
final fetchReviewsByBookingProvider =
    FutureProvider.family<List<Review>, int>((ref, bookingId) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getBookingReviews(bookingId);
});

/// Fetch reviews received by a user (provider profile)
final fetchUserReceivedReviewsProvider = FutureProvider.family<
    ReviewListResponse,
    ({int userId, int page, int pageSize})>((ref, params) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getUserReceivedReviews(
    params.userId,
    page: params.page,
    pageSize: params.pageSize,
  );
});

/// Fetch reviews given by a user
final fetchUserGivenReviewsProvider =
    FutureProvider.family<List<Review>, int>((ref, userId) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getUserGivenReviews(userId);
});

/// Get provider/user statistics (average rating, total reviews)
final fetchReviewStatisticsProvider =
    FutureProvider.family<ReviewStatistics, int>((ref, userId) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getProviderStatistics(userId);
});

/// Check if user has already reviewed a booking
final hasUserReviewedBookingProvider =
    FutureProvider.family<bool, ({int bookingId, int userId})>(
        (ref, params) async {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.hasUserReviewedBooking(params.bookingId, params.userId);
});

// ============================================
// SUBMIT REVIEW PROVIDER - Form Submission
// ============================================

/// Submit review with loading state
final submitReviewProvider = FutureProvider.autoDispose
    .family<Review, CreateReviewRequest>((ref, request) async {
  final repository = ref.watch(reviewRepositoryProvider);
  final review = await repository.submitReview(request);

  // Invalidate related providers to refresh data
  ref.invalidate(fetchReviewsByBookingProvider(request.bookingId));
  ref.invalidate(fetchReviewStatisticsProvider(request.revieweeId));
  ref.invalidate(
    hasUserReviewedBookingProvider(
      (bookingId: request.bookingId, userId: request.revieweeId),
    ),
  );

  return review;
});

// ============================================
// STATE PROVIDERS - FORM STATE MANAGEMENT
// ============================================

/// Review form state - manages rating, title, comment
final reviewFormStateProvider =
    StateProvider.autoDispose<ReviewFormState>((ref) {
  return const ReviewFormState();
});

/// Computed: Average rating for display
final averageRatingProvider =
    FutureProvider.family<double, List<Review>>((ref, reviews) async {
  if (reviews.isEmpty) return 0.0;
  final sum = reviews.fold<int>(0, (acc, review) => acc + review.rating);
  return sum / reviews.length;
});

/// Computed: Rating distribution (1 star: x, 2 stars: y, etc)
final ratingDistributionProvider =
    FutureProvider.family<Map<int, int>, List<Review>>((ref, reviews) async {
  final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  for (var review in reviews) {
    distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
  }
  return distribution;
});

// ============================================
// FORM STATE CLASS
// ============================================

class ReviewFormState {
  final int rating; // 0-5 (0 means not selected)
  final String title;
  final String comment;
  final bool isSubmitting;
  final String? errorMessage;

  const ReviewFormState({
    this.rating = 0,
    this.title = '',
    this.comment = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  /// Create a copy with modifications
  ReviewFormState copyWith({
    int? rating,
    String? title,
    String? comment,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return ReviewFormState(
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  /// Check if form is valid
  bool get isValid => rating > 0 && title.isNotEmpty;

  /// Reset form to initial state
  ReviewFormState reset() => const ReviewFormState();
}

// ============================================
// EXTENDED PROVIDERS FOR FORM MANAGEMENT
// ============================================

/// Notifier for managing form state changes
final reviewFormNotifierProvider =
    StateNotifierProvider.autoDispose<ReviewFormNotifier, ReviewFormState>(
        (ref) {
  return ReviewFormNotifier();
});

class ReviewFormNotifier extends StateNotifier<ReviewFormState> {
  ReviewFormNotifier() : super(const ReviewFormState());

  /// Update rating
  void setRating(int rating) {
    state = state.copyWith(rating: rating);
  }

  /// Update title
  void setTitle(String title) {
    state = state.copyWith(
      title: title,
      errorMessage: null, // Clear error when user starts typing
    );
  }

  /// Update comment
  void setComment(String comment) {
    state = state.copyWith(comment: comment);
  }

  /// Set submitting state
  void setSubmitting(bool isSubmitting) {
    state = state.copyWith(isSubmitting: isSubmitting);
  }

  /// Set error message
  void setError(String? message) {
    state = state.copyWith(errorMessage: message);
  }

  /// Reset form
  void reset() {
    state = const ReviewFormState();
  }
}
