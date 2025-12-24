import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/entities/entities.dart';
import '../bloc/favorites/favorites_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/minimalist_widgets.dart';

class ServiceCardWidget extends StatelessWidget {
  final ProviderService service;

  const ServiceCardWidget({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return MinCard(
      padding: EdgeInsets.zero,
      onTap: () {
        context.push('/service/${service.serviceId}', extra: service);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProviderIdentity(
                  provider: service.provider,
                  serviceId: service.serviceId,
                ),
                const SizedBox(height: 16),
                _ServiceInformation(
                    name: service.service.name,
                    description: service.service.description),
              ],
            ),
          ),
          _MetricRibbon(service: service),
        ],
      ),
    );
  }
}

class _ProviderIdentity extends StatelessWidget {
  final ProviderInfo provider;
  final int serviceId;

  const _ProviderIdentity({
    required this.provider,
    required this.serviceId,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              provider.displayName[0].toUpperCase(),
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      provider.displayName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (provider.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded,
                        size: 14, color: AppColors.primary),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Đối tác uy tín',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        _FavoriteToggle(serviceId: serviceId),
      ],
    );
  }
}

class _ServiceInformation extends StatelessWidget {
  final String name;
  final String? description;

  const _ServiceInformation({required this.name, this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontSize: 18),
        ),
        if (description != null) ...[
          const SizedBox(height: 6),
          Text(
            description!,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _MetricRibbon extends StatelessWidget {
  final ProviderService service;

  const _MetricRibbon({required this.service});

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.shelf,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildMetric(context, Icons.star_rounded,
                  service.provider.ratingAvg.toStringAsFixed(1), Colors.orange),
              _buildVerticalDivider(),
              _buildMetric(context, Icons.location_on_rounded, 'Cách 1.2 km',
                  AppColors.primary),
            ],
          ),
          Text(
            priceFormat.format(service.price).replaceAll(',00', ''),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
      BuildContext context, IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 12,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.borderMedium.withOpacity(0.5),
    );
  }
}

class _FavoriteToggle extends StatelessWidget {
  final int serviceId;

  const _FavoriteToggle({required this.serviceId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, state) {
        final isFavorite = state.favoriteIds.contains(serviceId);
        return GestureDetector(
          onTap: () =>
              context.read<FavoritesBloc>().add(ToggleFavorite(serviceId)),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isFavorite
                  ? AppColors.error.withOpacity(0.1)
                  : AppColors.shelf,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
              size: 18,
              color: isFavorite ? AppColors.error : AppColors.textTertiary,
            ),
          ),
        );
      },
    );
  }
}
