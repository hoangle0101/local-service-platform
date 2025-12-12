import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'review_form_widget.dart';

/// ReviewDialog - Modal dialog for quick review entry after booking completion
class ReviewDialog extends StatelessWidget {
  final int bookingId;
  final int revieweeId;
  final String serviceTitle;
  final VoidCallback? onSubmitSuccess;

  const ReviewDialog({
    Key? key,
    required this.bookingId,
    required this.revieweeId,
    required this.serviceTitle,
    this.onSubmitSuccess,
  }) : super(key: key);

  static void show({
    required BuildContext context,
    required int bookingId,
    required int revieweeId,
    required String serviceTitle,
    VoidCallback? onSubmitSuccess,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReviewDialog(
        bookingId: bookingId,
        revieweeId: revieweeId,
        serviceTitle: serviceTitle,
        onSubmitSuccess: onSubmitSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(24),
      ),
      child: Container(
        color: AppColors.white,
        child: SafeArea(
          child: ReviewFormWidget(
            bookingId: bookingId,
            revieweeId: revieweeId,
            onSubmitSuccess: onSubmitSuccess,
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

/// Quick review dialog - simplified version with just rating and comment
class QuickReviewDialog extends StatefulWidget {
  final int bookingId;
  final int revieweeId;
  final VoidCallback? onSubmitSuccess;

  const QuickReviewDialog({
    Key? key,
    required this.bookingId,
    required this.revieweeId,
    this.onSubmitSuccess,
  }) : super(key: key);

  static void show({
    required BuildContext context,
    required int bookingId,
    required int revieweeId,
    VoidCallback? onSubmitSuccess,
  }) {
    showDialog(
      context: context,
      builder: (context) => QuickReviewDialog(
        bookingId: bookingId,
        revieweeId: revieweeId,
        onSubmitSuccess: onSubmitSuccess,
      ),
    );
  }

  @override
  State<QuickReviewDialog> createState() => _QuickReviewDialogState();
}

class _QuickReviewDialogState extends State<QuickReviewDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rate_review,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Rate Your Experience',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Your feedback helps us improve',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Rating section
            Text(
              'How would you rate this service?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(5, (index) {
                  final rating = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = rating),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        _rating >= rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 40,
                        color: _rating >= rating
                            ? AppColors.primary
                            : AppColors.grey300,
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),

            // Comment field
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Add a comment (optional)',
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
                fillColor: AppColors.grey50,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.grey300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Skip',
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
                    onPressed: _rating == 0 ? null : () => _submit(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.grey300,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Submit',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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

  void _submit() {
    // TODO: Implement review submission
    // This would call the review provider to submit
    widget.onSubmitSuccess?.call();
    Navigator.of(context).pop();
  }
}
