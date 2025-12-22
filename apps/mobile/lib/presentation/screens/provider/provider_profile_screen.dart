import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/profile_menu_item.dart';
import '../../widgets/gradient_header.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
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
    final address = providerProfile?.address;
    final bio = providerProfile?.bio ?? profile?.bio;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: GradientHeader(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      HeaderActionButton(
                        icon: Icons.arrow_back,
                        onTap: () => context.pop(),
                      ),
                      HeaderActionButton(
                        icon: Icons.edit_outlined,
                        onTap: () => context.push('/provider/profile/edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Avatar
                  UserAvatar(
                    avatarUrl: avatarUrl != null
                        ? 'http://10.0.2.2:3000$avatarUrl'
                        : null,
                    fullName: user.fullName,
                    size: 100,
                  ),
                  const SizedBox(height: 16),

                  // Name
                  Text(
                    providerProfile?.displayName ?? user.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Phone
                  _buildInfoRow(Icons.phone_outlined, user.phone),

                  // Address
                  if (address != null && address.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildInfoRow(Icons.location_on_outlined, address,
                        maxLines: 2),
                  ],

                  const SizedBox(height: 12),

                  // Role & Verification badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBadge(
                        icon: Icons.verified,
                        label: 'PROVIDER',
                        color: Colors.amber,
                      ),
                      if (providerProfile?.serviceRadiusM != null) ...[
                        const SizedBox(width: 8),
                        _buildBadge(
                          icon: Icons.radar,
                          label:
                              '${(providerProfile!.serviceRadiusM! / 1000).toStringAsFixed(0)} km',
                          color: Colors.lightBlue,
                        ),
                      ],
                    ],
                  ),

                  // Bio
                  if (bio != null && bio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      bio,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Stats card
                _buildStatsCard(context, providerProfile),
                const SizedBox(height: 16),
                _buildWorkCard(context),
                const SizedBox(height: 16),
                _buildSettingsCard(context),
                const SizedBox(height: 16),
                _buildLogoutButton(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style:
                  TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, dynamic providerProfile) {
    final rating = providerProfile?.ratingAvg?.toStringAsFixed(1) ?? '0.0';
    final reviews = providerProfile?.ratingCount?.toString() ?? '0';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(context, '0', 'Hoàn thành', Colors.green),
          _buildDivider(),
          _buildStatItem(context, rating, 'Đánh giá', Colors.amber),
          _buildDivider(),
          _buildStatItem(context, reviews, 'Reviews', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildWorkCard(BuildContext context) {
    return _buildCard([
      ProfileMenuItem(
        icon: Icons.person_outline,
        iconColor: Colors.blue,
        title: 'Chỉnh sửa hồ sơ',
        subtitle: 'Cập nhật thông tin cá nhân',
        onTap: () => context.push('/provider/profile/edit'),
      ),
      ProfileMenuItem(
        icon: Icons.build_outlined,
        iconColor: Colors.orange,
        title: 'Dịch vụ của tôi',
        subtitle: 'Quản lý dịch vụ cung cấp',
        onTap: () => context.push('/provider/services'),
      ),
      ProfileMenuItem(
        icon: Icons.calendar_today_outlined,
        iconColor: Colors.green,
        title: 'Lịch đặt',
        subtitle: 'Xem và quản lý booking',
        onTap: () => context.push('/provider/bookings'),
      ),
      ProfileMenuItem(
        icon: Icons.payments_outlined,
        iconColor: Colors.purple,
        title: 'Thu nhập',
        subtitle: 'Xem thống kê thu nhập',
        onTap: () {},
      ),
    ]);
  }

  Widget _buildSettingsCard(BuildContext context) {
    return _buildCard([
      ProfileMenuItem(
        icon: Icons.notifications_outlined,
        iconColor: Colors.red,
        title: 'Thông báo',
        subtitle: 'Cài đặt thông báo',
        onTap: () {},
      ),
      ProfileMenuItem(
        icon: Icons.lock_outline,
        iconColor: Colors.teal,
        title: 'Bảo mật',
        subtitle: 'Đổi mật khẩu',
        onTap: () {},
      ),
      ProfileMenuItem(
        icon: Icons.help_outline,
        iconColor: Colors.indigo,
        title: 'Trợ giúp',
        subtitle: 'Hỗ trợ & FAQ',
        onTap: () {},
      ),
    ]);
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: children.expand((w) sync* {
          if (children.indexOf(w) > 0) {
            yield Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: Colors.grey.shade100),
            );
          }
          yield w;
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
