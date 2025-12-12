import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/categories/categories_bloc.dart';
import '../bloc/categories/categories_event_state.dart';
import '../bloc/services/services_bloc.dart';
import '../bloc/services/services_event_state.dart';
import '../bloc/auth/auth_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/service_card.dart';
import '../widgets/molecules/app_header.dart';

class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => CategoriesBloc()..add(LoadCategories()),
        ),
        BlocProvider(
          create: (context) =>
              ServicesBloc()..add(const LoadServices(limit: 10)),
        ),
        BlocProvider(
          create: (context) => AuthBloc()..add(AuthCheckRequested()),
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Header
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return AppHeader(
                    isAuthenticated: state is Authenticated,
                    onLogout: () {
                      context.read<AuthBloc>().add(LogoutRequested());
                    },
                  );
                },
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroSection(context),
                      const SizedBox(height: 32),
                      _buildCategoriesSection(context),
                      const SizedBox(height: 32),
                      _buildServicesSection(context),
                      const SizedBox(height: 32),
                      _buildHowItWorks(context),
                      const SizedBox(height: 32),
                      _buildCTASection(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Find Local Services',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with trusted professionals in your area',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.white,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search for services...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Categories',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),
          BlocBuilder<CategoriesBloc, CategoriesState>(
            builder: (context, state) {
              if (state is CategoriesLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is CategoriesLoaded) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: state.categories.take(6).length,
                  itemBuilder: (context, index) {
                    final category = state.categories[index];
                    return InkWell(
                      onTap: () {
                        context.push('/category/${category.id}');
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            category.name,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                );
              } else if (state is CategoriesError) {
                return Text('Error: ${state.message}');
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Services',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BlocBuilder<ServicesBloc, ServicesState>(
            builder: (context, state) {
              if (state is ServicesLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ServicesLoaded) {
                return Column(
                  children: state.services.take(5).map((service) {
                    return ServiceCardWidget(service: service);
                  }).toList(),
                );
              } else if (state is ServicesError) {
                return Text('Error: ${state.message}');
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How It Works',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStep(
                  context,
                  Icons.search,
                  '1. Search',
                  'Find the service you need',
                ),
              ),
              Expanded(
                child: _buildStep(
                  context,
                  Icons.person_search,
                  '2. Choose',
                  'Select verified professionals',
                ),
              ),
              Expanded(
                child: _buildStep(
                  context,
                  Icons.check_circle,
                  '3. Book',
                  'Schedule your service',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
      BuildContext context, IconData icon, String title, String description) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCTASection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.business_center, size: 48, color: AppColors.white),
          const SizedBox(height: 16),
          Text(
            'Become a Service Provider',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Join our platform and start earning by offering your skills',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.white,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              context.push('/register/provider');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.white,
              side: const BorderSide(color: AppColors.white, width: 2),
            ),
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}
