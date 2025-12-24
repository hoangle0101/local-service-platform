import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/categories/categories_bloc.dart';
import '../../bloc/categories/categories_event_state.dart';
import '../../bloc/services/services_bloc.dart';
import '../../bloc/services/services_event_state.dart';
import '../../widgets/service_card.dart';
import '../../widgets/minimalist_widgets.dart';
import '../../widgets/animations/fade_in_animation.dart';
import '../../widgets/animations/slide_in_animation.dart';
import '../../widgets/loading/shimmer_loading.dart';
import '../../widgets/phone_verification_card.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CategoriesBloc>().add(LoadCategories());
    context.read<ServicesBloc>().add(const LoadServices());
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 17) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          context.read<CategoriesBloc>().add(LoadCategories());
          context.read<ServicesBloc>().add(const LoadServices());
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverHeader(),
            _buildDiscoveryContent(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }

  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is Authenticated && state.user != null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.user!.fullName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                _buildActionIcons(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcons() {
    return Row(
      children: [
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Authenticated && state.user?.isProvider == true) {
              return GestureDetector(
                onTap: () => context.go('/provider/home'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.sync_rounded,
                          color: AppColors.primary, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Đối tác',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider.withOpacity(0.5)),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 22, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoveryContent() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildVerificationBanner(),
          const SizedBox(height: 12),
          _buildSearchBox(),
          const SizedBox(height: 32),
          _buildStatsRow(),
          const SizedBox(height: 40),
          _buildSectionTitle('Danh mục dịch vụ', () {}),
          const SizedBox(height: 20),
          _buildCategoriesList(),
          const SizedBox(height: 40),
          _buildSectionTitle('Dịch vụ phổ biến', () {}),
          const SizedBox(height: 20),
          _buildPopularServices(),
        ]),
      ),
    );
  }

  Widget _buildVerificationBanner() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated &&
            state.user != null &&
            !state.user!.isVerified) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: SlideInAnimation(
              begin: const Offset(0, -0.1),
              child: PhoneVerificationCard(isVerified: false, verifiedAt: null),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSearchBox() {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 100),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: MinTextField(
          hint: 'Bạn cần giúp gì hôm nay?',
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.primary, size: 22),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 200),
      child: Row(
        children: [
          Expanded(
              child: _buildStatItem('Đặt chỗ ngay', 'Lên lịch',
                  Icons.calendar_today_rounded, AppColors.primary)),
          const SizedBox(width: 16),
          Expanded(
              child: _buildStatItem('Dịch vụ ưu đãi', 'Khuyến mãi',
                  Icons.local_offer_rounded, AppColors.secondary)),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return MinCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: AppColors.white,
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, VoidCallback onTap) {
    return FadeInAnimation(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: const Row(
              children: [
                Text(
                  'Tất cả',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return SizedBox(
      height: 110,
      child: BlocBuilder<CategoriesBloc, CategoriesState>(
        builder: (context, state) {
          if (state is CategoriesLoading) {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 4),
              itemCount: 5,
              itemBuilder: (context, _) => const ShimmerCategoryCard(),
            );
          }
          if (state is CategoriesLoaded) {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 4),
              clipBehavior: Clip.none,
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: _buildCategoryItem(
                      category.name, _getCategoryIcon(category.code), () {
                    context.push('/user/home/category/${category.id}',
                        extra: category);
                  }),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCategoryItem(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.divider.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularServices() {
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (context, state) {
        if (state is ServicesLoading) {
          return Column(
              children: List.generate(3, (_) => const ShimmerServiceCard()));
        }
        if (state is ServicesLoaded) {
          return Column(
            children: state.services.asMap().entries.map((entry) {
              return SlideInAnimation(
                delay: Duration(milliseconds: 400 + (entry.key * 100)),
                begin: const Offset(0.1, 0),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ServiceCardWidget(service: entry.value),
                ),
              );
            }).toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildModernFAB() {
    return FloatingActionButton.extended(
      onPressed: () => context.push('/booking/new'),
      backgroundColor: AppColors.primaryDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text('Đặt dịch vụ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }

  IconData _getCategoryIcon(String code) {
    switch (code.toLowerCase()) {
      case 'cleaning':
        return Icons.cleaning_services_rounded;
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'electrical':
        return Icons.electrical_services_rounded;
      case 'carpentry':
        return Icons.carpenter_rounded;
      case 'painting':
        return Icons.format_paint_rounded;
      case 'gardening':
        return Icons.yard_rounded;
      default:
        return Icons.home_repair_service_rounded;
    }
  }
}
