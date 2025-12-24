import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/entities/entities.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/services/services_bloc.dart';
import '../bloc/services/services_event_state.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import 'reviews/provider_reviews_screen.dart';
import '../widgets/minimalist_widgets.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final int serviceId;
  final ProviderService? service;

  const ServiceDetailsScreen({
    super.key,
    required this.serviceId,
    this.service,
  });

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  late ServicesBloc _servicesBloc;
  ProviderService? _service;

  @override
  void initState() {
    super.initState();
    _service = widget.service;
    _servicesBloc = ServicesBloc();

    if (_service == null) {
      _servicesBloc.add(LoadServiceDetails(widget.serviceId));
    }
  }

  @override
  void dispose() {
    _servicesBloc.close();
    super.dispose();
  }

  void _openProviderReviews(BuildContext context, ProviderService service) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProviderReviewsScreen(
          providerId: service.providerUserId,
          providerName: service.provider.displayName,
          ratingAvg: service.provider.ratingAvg,
          ratingCount: service.provider.ratingCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_service != null) {
      return _buildContent(_service!);
    }

    return BlocProvider.value(
      value: _servicesBloc,
      child: BlocBuilder<ServicesBloc, ServicesState>(
        builder: (context, state) {
          if (state is ServicesLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (state is ServiceDetailsLoaded) {
            _service = state.service;
            return _buildContent(state.service);
          } else if (state is ServicesError) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: Text('Error: ${state.message}'),
              ),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildContent(ProviderService service) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, service),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, service, currencyFormat),
                  const SizedBox(height: 24),
                  _buildProviderInfo(context, service),
                  const SizedBox(height: 24),
                  _buildDescription(context, service),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(context, service, currencyFormat),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ProviderService service) {
    return SliverAppBar(
      expandedHeight: 300.0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildPlaceholderImage(),
            // Subtle Gradient overlay for top control visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    AppColors.black.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leadingWidth: 70,
      leading: Center(
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 18),
          ),
        ),
      ),
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.share_rounded,
                  color: AppColors.textPrimary, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: const Center(
        child: Icon(Icons.image, size: 64, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProviderService service,
      NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                service.service.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_filled_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${service.service.durationMinutes ?? 60} p',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          currencyFormat.format(service.price).replaceAll(',00', ''),
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildProviderInfo(BuildContext context, ProviderService service) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                service.provider.displayName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        service.provider.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (service.provider.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded,
                          size: 16, color: AppColors.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _openProviderReviews(context, service),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '${service.provider.ratingAvg} ',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '(${service.provider.ratingCount} đánh giá)',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.shelf,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.chat_bubble_rounded,
                color: AppColors.primary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context, ProviderService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mô tả dịch vụ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          service.service.description ??
              'Thông tin chi tiết về dịch vụ này hiện đang được cập nhật.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.6,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, ProviderService service,
      NumberFormat currencyFormat) {
    final authState = context.read<AuthBloc>().state;
    String? currentUserId;
    if (authState is Authenticated && authState.user != null) {
      currentUserId = authState.user!.id;
    }

    final isOwnService =
        currentUserId != null && service.providerUserId == currentUserId;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng thanh toán',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currencyFormat.format(service.price).replaceAll(',00', ''),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: isOwnService
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.shelf,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Center(
                        child: Text(
                          'Của bạn',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  : MinButton(
                      text: 'Đặt ngay',
                      onPressed: () {
                        context.push(
                          '/booking/create',
                          extra: {
                            'serviceId': service.serviceId,
                            'service': service,
                            'providerId': int.tryParse(service.providerUserId),
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
