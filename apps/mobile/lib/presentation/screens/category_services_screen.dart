import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/entities/entities.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/services/services_bloc.dart';
import '../bloc/services/services_event_state.dart';
import '../widgets/service_card.dart';
import '../widgets/minimalist_widgets.dart';
import '../widgets/animations/fade_in_animation.dart';
import '../widgets/animations/slide_in_animation.dart';
import '../widgets/loading/shimmer_loading.dart';

class CategoryServicesScreen extends StatefulWidget {
  final int categoryId;
  final Category? category;

  const CategoryServicesScreen({
    super.key,
    required this.categoryId,
    this.category,
  });

  @override
  State<CategoryServicesScreen> createState() => _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<CategoryServicesScreen> {
  late ServicesBloc _servicesBloc;

  @override
  void initState() {
    super.initState();
    _servicesBloc = ServicesBloc();
    _servicesBloc
        .add(LoadServicesByCategory(categoryId: widget.categoryId, limit: 20));
  }

  @override
  void dispose() {
    _servicesBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _servicesBloc,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            _servicesBloc.add(LoadServicesByCategory(
                categoryId: widget.categoryId, limit: 20));
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernAppBar(context),
              _buildContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.shelf,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: AppColors.textPrimary),
                  ),
                ),
                MinBadge(
                    label: 'Danh mục',
                    color: AppColors.primary.withOpacity(0.1)),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              widget.category?.name ?? 'Dịch vụ',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontSize: 32, letterSpacing: -1),
            ),
            if (widget.category?.description != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.category!.description!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (context, state) {
        if (state is ServicesLoading) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                List.generate(
                    3,
                    (index) => const Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: ShimmerServiceCard())),
              ),
            ),
          );
        } else if (state is ServicesError) {
          return SliverFillRemaining(child: _buildErrorState());
        } else if (state is ServicesLoaded) {
          if (state.services.isEmpty)
            return SliverFillRemaining(child: _buildEmptyState());

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tìm thấy ${state.services.length} dịch vụ',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 20),
                        ServiceCardWidget(service: state.services[index]),
                      ],
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ServiceCardWidget(service: state.services[index]),
                  );
                },
                childCount: state.services.length,
              ),
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox());
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
              padding: const EdgeInsets.all(32),
              decoration:
                  BoxDecoration(color: AppColors.shelf, shape: BoxShape.circle),
              child: const Icon(Icons.search_off_rounded,
                  size: 64, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 32),
            Text('Chưa có dịch vụ nào',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              'Hiện tại chưa có đối tác nào cung cấp dịch vụ trong danh mục này. Hãy quay lại sau nhé!',
              textAlign: TextAlign.center,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 40),
            MinButton(
                text: 'Quay lại',
                isPrimary: false,
                onPressed: () => context.pop()),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.05),
                  shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded,
                  size: 64, color: AppColors.error),
            ),
            const SizedBox(height: 32),
            Text('Đã có lỗi xảy ra',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            const Text(
              'Không thể tải danh sách dịch vụ. Vui lòng kiểm tra kết nối mạng và thử lại.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 40),
            MinButton(
              text: 'Thử lại',
              onPressed: () => _servicesBloc.add(LoadServicesByCategory(
                  categoryId: widget.categoryId, limit: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
