import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../bloc/favorites/favorites_bloc.dart';
import '../../widgets/favorite_service_card.dart';
import '../../widgets/minimalist_widgets.dart';

/// Beautiful, modern favorites screen with pull-to-refresh
class UserFavoritesScreen extends StatefulWidget {
  const UserFavoritesScreen({super.key});

  @override
  State<UserFavoritesScreen> createState() => _UserFavoritesScreenState();
}

class _UserFavoritesScreenState extends State<UserFavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // Load favorites on screen open
    context.read<FavoritesBloc>().add(LoadFavorites());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildHeader(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.divider.withOpacity(0.5)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AppColors.textPrimary),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ĐÃ LƯU',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Yêu thích',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -1,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            BlocBuilder<FavoritesBloc, FavoritesState>(
              builder: (context, state) {
                final count = state is FavoritesLoaded ? state.items.length : 0;
                return Text(
                  'Bạn đang có $count dịch vụ đã lưu vào danh sách',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, state) {
        if (state is FavoritesLoading && state.favoriteIds.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (state is FavoritesError) {
          return SliverFillRemaining(
            child: _buildErrorState(state.message),
          );
        }

        if (state is FavoritesLoaded) {
          if (state.items.isEmpty) {
            return SliverFillRemaining(
              child: _buildEmptyState(),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = state.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: FavoriteServiceCard(
                      favorite: item,
                      onRemove: () {
                        context
                            .read<FavoritesBloc>()
                            .add(RemoveFavorite(item.serviceId));
                        _showSnackBar('Đã xóa khỏi yêu thích');
                      },
                    ),
                  );
                },
                childCount: state.items.length,
              ),
            ),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: const BoxDecoration(
                color: AppColors.shelf,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 64,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'Chưa có dịch vụ yêu thích',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Khám phá và lưu những dịch vụ bạn quan tâm để dễ dàng tìm kiếm và đặt lịch sau này!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),
            MinButton(
              text: 'Khám phá ngay',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Đã có lỗi xảy ra',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 48),
            MinButton(
              text: 'Thử lại',
              onPressed: () {
                context.read<FavoritesBloc>().add(LoadFavorites());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
