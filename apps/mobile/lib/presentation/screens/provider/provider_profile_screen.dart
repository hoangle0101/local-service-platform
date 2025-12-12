import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../providers/provider_provider.dart';

class ProviderProfileScreen extends ConsumerWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;

    if (authState is Unauthenticated) {
      Future.microtask(() => context.go('/'));
      return const SizedBox.shrink();
    }

    if (authState is! Authenticated) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = authState.user;
    if (user == null) {
      return const Center(
        child: Text('User data not available'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.white,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.phone,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.role.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stats
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ref
                      .watch(providerCompletedCountProvider(int.parse(user.id)))
                      .when(
                        data: (count) => _buildStatItem(
                            context, count.toString(), 'Completed'),
                        loading: () =>
                            _buildStatItem(context, '...', 'Completed'),
                        error: (e, st) {
                          print('[ProfileScreen] Completed error: $e');
                          return _buildStatItem(context, '0', 'Completed');
                        },
                      ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                  ),
                  ref.watch(providerRatingProvider(int.parse(user.id))).when(
                        data: (rating) => _buildStatItem(
                            context, rating.toStringAsFixed(1), 'Rating'),
                        loading: () => _buildStatItem(context, '...', 'Rating'),
                        error: (e, st) {
                          print('[ProfileScreen] Rating error: $e');
                          return _buildStatItem(context, '0.0', 'Rating');
                        },
                      ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                  ),
                  ref
                      .watch(providerReviewCountProvider(int.parse(user.id)))
                      .when(
                        data: (count) => _buildStatItem(
                            context, count.toString(), 'Reviews'),
                        loading: () =>
                            _buildStatItem(context, '...', 'Reviews'),
                        error: (e, st) {
                          print('[ProfileScreen] Reviews error: $e');
                          return _buildStatItem(context, '0', 'Reviews');
                        },
                      ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Menu Items
            Container(
              color: AppColors.white,
              child: Column(
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () {
                      // TODO: Navigate to edit profile
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.build_outlined,
                    title: 'My Services',
                    onTap: () {
                      context.push('/provider/services');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.calendar_today_outlined,
                    title: 'Bookings',
                    onTap: () {
                      context.push('/provider/bookings');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.payment_outlined,
                    title: 'Earnings',
                    onTap: () {
                      // TODO: Navigate to earnings
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Settings
            Container(
              color: AppColors.white,
              child: Column(
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      // TODO: Navigate to settings
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      // TODO: Navigate to help
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () {
                      // TODO: Navigate to about
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Logout Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  _showLogoutDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryDark),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
