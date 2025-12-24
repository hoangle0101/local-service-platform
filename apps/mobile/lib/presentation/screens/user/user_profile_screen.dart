import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/user_datasource.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/minimalist_widgets.dart';
import '../../widgets/phone_verification_card.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserDataSource _userDataSource = UserDataSource();
  String? _defaultAddress;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final addresses = await _userDataSource.getAddresses();
      if (addresses.isNotEmpty && mounted) {
        // Find default address or use first one
        final defaultAddr = addresses.firstWhere(
          (a) => a['isDefault'] == true,
          orElse: () => addresses.first,
        );
        setState(() {
          _defaultAddress = defaultAddr['addressText'] as String?;
        });
      }
    } catch (e) {
      debugPrint('[UserProfile] Error loading addresses: $e');
    }
  }

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
        await _loadDefaultAddress();
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
                  _buildVerificationBanner(user),
                  const SizedBox(height: 32),
                  _buildSectionLabel('Tài khoản'),
                  const SizedBox(height: 16),
                  _buildAccountCard(context),
                  const SizedBox(height: 32),
                  _buildSectionLabel('Cài đặt'),
                  const SizedBox(height: 16),
                  _buildSettingsCard(context),
                  const SizedBox(height: 48),
                  _buildLogoutButton(context),
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
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 16),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.divider.withOpacity(0.5)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.textPrimary),
              ),
            ),
            GestureDetector(
              onTap: () async {
                await context.push('/user/edit-profile');
                if (mounted) _loadDefaultAddress();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Sửa hồ sơ',
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.1), width: 4),
              ),
              child: UserAvatar(
                avatarUrl: avatarUrl,
                fullName: user.fullName,
                size: 80,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.shelf,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_iphone_rounded,
                            size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Text(
                          user.phone,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_defaultAddress != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.divider.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.02),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Địa chỉ mặc định',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _defaultAddress!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
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

  Widget _buildVerificationBanner(dynamic user) {
    if (user.isVerified) return const SizedBox.shrink();
    return PhoneVerificationCard(
      isVerified: false,
      verifiedAt: null,
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    return MinCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildMenuRow(
            icon: Icons.location_on_outlined,
            title: 'Địa chỉ của tôi',
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuRow(
            icon: Icons.favorite_outline_rounded,
            title: 'Dịch vụ yêu thích',
            onTap: () => context.push('/user/favorites'),
          ),
          _buildMenuDivider(),
          _buildMenuRow(
            icon: Icons.calendar_today_rounded,
            title: 'Lịch sử đặt lịch',
            onTap: () => context.push('/user/bookings'),
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
            icon: Icons.lock_outline_rounded,
            title: 'Bảo mật',
            onTap: () {},
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.shelf,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textTertiary, size: 22),
    );
  }

  Widget _buildMenuDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: AppColors.divider.withOpacity(0.5)),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return MinButton(
      text: 'Đăng xuất tài khoản',
      isPrimary: false,
      onPressed: () => _showLogoutDialog(context),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng và kết thúc phiên làm việc này?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: MinButton(
                  text: 'Hủy',
                  isPrimary: false,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    context.read<AuthBloc>().add(LogoutRequested());
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Đăng xuất',
                        style: TextStyle(
                            color: AppColors.error,
                            fontSize: 15,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
