import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/entities/entities.dart';
import '../theme/app_colors.dart';
import '../widgets/rating_display.dart';

class ServiceCardWidget extends StatelessWidget {
  final ProviderService service;

  const ServiceCardWidget({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          print('ServiceCardWidget: Tapped service ${service.serviceId}');
          print('ServiceCardWidget: Service object: $service');
          context.push(
            '/service/${service.serviceId}',
            extra: service,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider Info
              Row(
                children: [
                  CircleAvatar(
                    child: Text(service.provider.displayName[0]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                service.provider.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            if (service.provider.isVerified)
                              const Icon(
                                Icons.verified,
                                size: 16,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                        RatingDisplay(
                          rating: service.provider.ratingAvg,
                          count: service.provider.ratingCount,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Service Name
              Text(
                service.service.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              // Description
              if (service.service.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  service.service.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Price & Favorite
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Starting at',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${service.price.toStringAsFixed(0)} ${service.currency}',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {
                      // TODO: Add to favorites
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
