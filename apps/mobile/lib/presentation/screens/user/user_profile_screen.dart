import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/user_datasource.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/profile_menu_item.dart';
import '../../widgets/gradient_header.dart';

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
    final avatarUrl = profile?.avatarUrl;
    final bio = profile?.bio;

    // Build full avatar URL
    String? fullAvatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      fullAvatarUrl = avatarUrl.startsWith('http')
          ? avatarUrl
          : 'http://10.0.2.2:3000$avatarUrl';
    }
    debugPrint('[UserProfile] AvatarUrl from profile: $avatarUrl');
    debugPrint('[UserProfile] Full avatar URL: $fullAvatarUrl');

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AuthBloc>().add(ProfileFetchRequested());
        await _loadDefaultAddress();
      },
      child: CustomScrollView(
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
                          onTap: () async {
                            await context.push('/user/edit-profile');
                            // Reload data after returning
                            if (mounted) {
                              _loadDefaultAddress();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Avatar
                    UserAvatar(
                      avatarUrl: fullAvatarUrl,
                      fullName: user.fullName,
                      size: 100,
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Phone
                    _buildInfoRow(Icons.phone_outlined, user.phone),

                    // Address (if available)
                    if (_defaultAddress != null &&
                        _defaultAddress!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildInfoRow(
                          Icons.location_on_outlined, _defaultAddress!,
                          maxLines: 2),
                    ],

                    const SizedBox(height: 12),

                    // Role badge
                    _buildRoleBadge(user.role),

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
                  _buildAccountCard(context),
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
      ),
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
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 16),
          const SizedBox(width: 6),
          Text(
            role.toUpperCase(),
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

  Widget _buildAccountCard(BuildContext context) {
    return _buildCard([
      ProfileMenuItem(
        icon: Icons.person_outline,
        iconColor: Colors.blue,
        title: 'Chỉnh sửa hồ sơ',
        subtitle: 'Cập nhật thông tin cá nhân',
        onTap: () async {
          await context.push('/user/edit-profile');
          if (mounted) _loadDefaultAddress();
        },
      ),
      ProfileMenuItem(
        icon: Icons.location_on_outlined,
        iconColor: Colors.green,
        title: 'Địa chỉ',
        subtitle: _defaultAddress ?? 'Chưa có địa chỉ',
        onTap: () {},
      ),
      ProfileMenuItem(
        icon: Icons.favorite_outline,
        iconColor: Colors.red,
        title: 'Yêu thích',
        subtitle: 'Các dịch vụ đã lưu',
        onTap: () => context.push('/user/favorites'),
      ),
      ProfileMenuItem(
        icon: Icons.calendar_today_outlined,
        iconColor: Colors.orange,
        title: 'Lịch đặt',
        subtitle: 'Xem lịch sử đặt dịch vụ',
        onTap: () => context.push('/user/bookings'),
      ),
    ]);
  }

  Widget _buildSettingsCard(BuildContext context) {
    return _buildCard([
      ProfileMenuItem(
        icon: Icons.notifications_outlined,
        iconColor: Colors.purple,
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
