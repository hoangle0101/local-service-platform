import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/minimalist_widgets.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            context.go('/');
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Authenticated && state.user != null) {
              return _buildContent(context, state.user!);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic user) {
    final profile = user.profile;
    final providerProfile = user.providerProfile;
    final avatarUrl = profile?.avatarUrl;
    // Build full avatar URL
    String? fullAvatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      fullAvatarUrl = avatarUrl.startsWith('http')
          ? avatarUrl
          : 'http://10.0.2.2:3000$avatarUrl';
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<AuthBloc>().add(ProfileFetchRequested());
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildProfileHeader(context, user, fullAvatarUrl),
                  const SizedBox(height: 32),
                  _buildStatsSection(context, providerProfile),
                  const SizedBox(height: 32),
                  _buildSectionLabel('Công việc'),
                  const SizedBox(height: 16),
                  _buildWorkCard(context),
                  const SizedBox(height: 32),
                  _buildSectionLabel('Cài đặt'),
                  const SizedBox(height: 16),
                  _buildSettingsCard(context),
                  const SizedBox(height: 48),
                  MinButton(
                    text: 'Đăng xuất',
                    isPrimary: false,
                    onPressed: () => _showLogoutDialog(context),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hồ sơ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/provider/profile/edit'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Sửa hồ sơ',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, dynamic user, String? avatarUrl) {
    final providerProfile = user.providerProfile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            UserAvatar(
              avatarUrl: avatarUrl,
              fullName: user.fullName,
              size: 80,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    providerProfile?.displayName ?? user.fullName,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      MinBadge(
                        label: 'PROVIDER',
                        color: AppColors.primary.withOpacity(0.1),
                        textColor: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      if (providerProfile?.serviceRadiusM != null)
                        MinBadge(
                          label:
                              '${(providerProfile!.serviceRadiusM! / 1000).toStringAsFixed(0)} km',
                          color: AppColors.accent.withOpacity(0.1),
                          textColor: AppColors.accent,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, dynamic providerProfile) {
    final rating = providerProfile?.ratingAvg?.toStringAsFixed(1) ?? '0.0';
    final reviews = providerProfile?.ratingCount?.toString() ?? '0';

    return MinCard(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('0', 'Xong', AppColors.success),
          _buildStatDivider(),
          _buildStatItem(rating, 'Đánh giá', AppColors.warning),
          _buildStatDivider(),
          _buildStatItem(reviews, 'Phản hồi', AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 32, color: AppColors.divider);
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.textTertiary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildWorkCard(BuildContext context) {
    return MinCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildMenuRow(
            icon: Icons.build_circle_outlined,
            title: 'Dịch vụ của tôi',
            onTap: () => context.push('/provider/services'),
          ),
          _buildMenuDivider(),
          _buildMenuRow(
            icon: Icons.calendar_today_rounded,
            title: 'Lịch công việc',
            onTap: () => context.push('/provider/bookings'),
          ),
          _buildMenuDivider(),
          _buildMenuRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Ví của tôi',
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuRow(
            icon: Icons.sync_rounded,
            title: 'Chuyển sang Chế độ khách',
            onTap: () => context.go('/user/home'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return MinCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildMenuRow(
            icon: Icons.notifications_none_rounded,
            title: 'Thông báo',
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuRow(
            icon: Icons.star_outline_rounded,
            title: 'Đánh giá từ khách',
            onTap: () => context.push('/provider/my-reviews'),
          ),
          _buildMenuDivider(),
          _buildMenuRow(
            icon: Icons.help_outline_rounded,
            title: 'Trợ giúp & Hỗ trợ',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.shelf,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textTertiary, size: 20),
    );
  }

  Widget _buildMenuDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: AppColors.divider),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Đăng xuất',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy bỏ',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700)),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(LogoutRequested());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Đăng xuất',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
