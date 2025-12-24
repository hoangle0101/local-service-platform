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
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.user!.fullName,
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
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
              return _buildIconButton(
                  Icons.sync_rounded, () => context.go('/provider/home'));
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(width: 8),
        _buildIconButton(Icons.notifications_none_rounded, () {}),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.shelf,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.textPrimary, size: 20),
        onPressed: onTap,
        splashRadius: 24,
      ),
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
      child: MinTextField(
        hint: 'Bạn đang tìm dịch vụ gì?',
        prefixIcon:
            const Icon(Icons.search_rounded, color: AppColors.textTertiary),
      ),
    );
  }

  Widget _buildStatsRow() {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 200),
      child: Row(
        children: [
          Expanded(
              child: _buildStatItem('Lịch hẹn', '0',
                  Icons.calendar_today_rounded, AppColors.primary)),
          const SizedBox(width: 16),
          Expanded(
              child: _buildStatItem(
                  'Yêu thích', '0', Icons.favorite_rounded, AppColors.error)),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return MinCard(
      padding: const EdgeInsets.all(20),
      color: AppColors.shelf,
      border: const BorderSide(color: AppColors.divider),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18)),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, VoidCallback onTap) {
    return FadeInAnimation(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          TextButton(
            onPressed: onTap,
            child: const Text('Xem thêm',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return SizedBox(
      height: 104,
      child: BlocBuilder<CategoriesBloc, CategoriesState>(
        builder: (context, state) {
          if (state is CategoriesLoading) {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, _) => const ShimmerCategoryCard(),
            );
          }
          if (state is CategoriesLoaded) {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              clipBehavior:
                  Colors.transparent == null ? Clip.hardEdge : Clip.none,
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(title,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
