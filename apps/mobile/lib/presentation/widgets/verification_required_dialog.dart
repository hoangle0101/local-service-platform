import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class VerificationRequiredDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? phone;
  final bool canSkip;
  final VoidCallback? onVerifySuccess;

  const VerificationRequiredDialog({
    super.key,
    this.title = 'Phone Verification Required',
    this.message =
        'Please verify your phone number to continue with this action.',
    this.phone,
    this.canSkip = true,
    this.onVerifySuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone_android,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Benefits
            _buildBenefits(),
            const SizedBox(height: 24),

            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleVerify(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Verify Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Skip Button (optional)
            if (canSkip) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Skip for Now',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenefits() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why verify?',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            'Secure your account',
            'Enable instant bookings',
            'Access exclusive features',
            'Better customer support',
          ].map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        benefit,
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _handleVerify(BuildContext context) async {
    Navigator.of(context).pop(true);

    // Navigate to OTP verification
    final result = await context.push('/otp-verify', extra: {
      'phone': phone ?? 'current_user_phone',
      'purpose': 'verify_phone',
    });

    // If verification was successful, call the callback
    if (result == true && onVerifySuccess != null) {
      onVerifySuccess!();
    }
  }

  /// Show the dialog and return true if user verified, false if skipped
  static Future<bool> show(
    BuildContext context, {
    String? title,
    String? message,
    String? phone,
    bool canSkip = true,
    VoidCallback? onVerifySuccess,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: canSkip,
      builder: (context) => VerificationRequiredDialog(
        title: title ?? 'Phone Verification Required',
        message: message ??
            'Please verify your phone number to continue with this action.',
        phone: phone,
        canSkip: canSkip,
        onVerifySuccess: onVerifySuccess,
      ),
    );

    return result ?? false;
  }
}
