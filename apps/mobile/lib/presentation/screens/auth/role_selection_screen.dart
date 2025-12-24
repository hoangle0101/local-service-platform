import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/minimalist_widgets.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Bạn là ai?',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Chọn vai trò của bạn để bắt đầu trải nghiệm những tiện ích tuyệt vời nhất.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 48),
              _RoleCard(
                icon: Icons.person_search_rounded,
                title: 'Tôi là Khách hàng',
                description:
                    'Tìm kiếm, đặt lịch và trải nghiệm các dịch vụ chất lượng.',
                onTap: () => context.push('/register/user'),
              ),
              const SizedBox(height: 24),
              _RoleCard(
                icon: Icons.business_center_rounded,
                title: 'Tôi là Đối tác',
                description:
                    'Cung cấp dịch vụ chuyên nghiệp và phát triển kinh doanh.',
                onTap: () => context.push('/register/provider'),
              ),
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text(
                    'Quay lại Trang chủ',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MinCard(
      onTap: onTap,
      padding: const EdgeInsets.all(24),
      borderRadius: 32,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 17,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.borderMedium,
            size: 24,
          ),
        ],
      ),
    );
  }
}
