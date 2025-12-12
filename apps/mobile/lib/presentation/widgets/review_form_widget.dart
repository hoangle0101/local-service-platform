import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../../data/models/review_model.dart';
import '../providers/review_provider.dart';
import 'star_rating_bar.dart';

/// ReviewFormWidget - Form for entering review details
/// Includes rating selection, title, and comment
class ReviewFormWidget extends ConsumerWidget {
  final VoidCallback? onSubmitSuccess;
  final VoidCallback? onCancel;
  final int bookingId;
  final int revieweeId;

  const ReviewFormWidget({
    Key? key,
    this.onSubmitSuccess,
    this.onCancel,
    required this.bookingId,
    required this.revieweeId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(reviewFormNotifierProvider);
    final formNotifier = ref.read(reviewFormNotifierProvider.notifier);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share Your Feedback',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onCancel,
                )
              ],
            ),
            const SizedBox(height: 16),

            // Rating Section
            Text(
              'How would you rate this service?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Center(
              child: StarRatingBar(
                initialRating: formState.rating,
                onRatingChanged: (rating) {
                  formNotifier.setRating(rating);
                },
              ),
            ),
            if (formState.rating > 0) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _getRatingText(formState.rating),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Title Section
            Text(
              'Review Title',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              maxLength: 100,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'e.g., Excellent service, would recommend',
                hintStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.grey300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.grey300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppColors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                errorText:
                    formState.title.isEmpty && formState.errorMessage != null
                        ? 'Title is required'
                        : null,
              ),
              onChanged: (value) => formNotifier.setTitle(value),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Comment Section
            Text(
              'Your Review (Optional)',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              maxLength: 500,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Share your experience. What did you like? Any suggestions?',
                hintStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.grey300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.grey300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppColors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (value) => formNotifier.setComment(value),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            // Error Message
            if (formState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formState.errorMessage ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: formState.isSubmitting ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.grey300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: formState.isSubmitting || !formState.isValid
                        ? null
                        : () => _submitReview(context, ref, formState),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      disabledBackgroundColor: AppColors.grey300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: formState.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Submit Review',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Submit review and handle response
  void _submitReview(
    BuildContext context,
    WidgetRef ref,
    ReviewFormState formState,
  ) async {
    final formNotifier = ref.read(reviewFormNotifierProvider.notifier);

    // Validate
    if (!formState.isValid) {
      formNotifier.setError('Please fill in all required fields');
      return;
    }

    formNotifier.setSubmitting(true);

    try {
      final request = CreateReviewRequest(
        bookingId: bookingId,
        revieweeId: revieweeId,
        rating: formState.rating,
        title: formState.title,
        comment: formState.comment.isEmpty ? null : formState.comment,
      );

      await ref.read(submitReviewProvider(request).future);

      if (context.mounted) {
        formNotifier.reset();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        onSubmitSuccess?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      formNotifier.setError(
        e.toString().replaceAll('Exception: ', ''),
      );
      formNotifier.setSubmitting(false);
    }
  }

  String _getRatingText(int rating) {
    const ratings = [
      '',
      'Poor - Needs improvement',
      'Fair - Could be better',
      'Good - Satisfied',
      'Very Good - Impressed',
      'Excellent - Highly recommended',
    ];
    return rating > 0 && rating <= 5 ? ratings[rating] : '';
  }
}
