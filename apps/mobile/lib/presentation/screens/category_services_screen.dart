import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CategoryServicesScreen extends StatelessWidget {
  final int categoryId;

  const CategoryServicesScreen({
    super.key,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Services'),
      ),
      body: Column(
        children: [
          // Category Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              children: [
                const Icon(Icons.category, size: 48, color: AppColors.white),
                const SizedBox(height: 8),
                Text(
                  'Category Name',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Category ID: $categoryId',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.white,
                      ),
                ),
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Show filter dialog
                    },
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filter'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Show sort dialog
                    },
                    icon: const Icon(Icons.sort),
                    label: const Text('Sort'),
                  ),
                ),
              ],
            ),
          ),

          // Services List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.cleaning_services),
                    ),
                    title: Text('Service ${index + 1}'),
                    subtitle: const Text('Professional service provider'),
                    trailing: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '150,000 VND',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            SizedBox(width: 2),
                            Text('4.8'),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      // TODO: Navigate to service details
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
