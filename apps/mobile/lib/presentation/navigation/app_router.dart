import 'package:go_router/go_router.dart';
import '../screens/guest_home_screen.dart';
import '../screens/service_details_screen.dart';
import '../screens/provider_profile_screen.dart';
import '../screens/category_services_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/register_user_screen.dart';
import '../screens/auth/register_provider_screen.dart';
import '../screens/auth/otp_verification_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const GuestHomeScreen(),
    ),

    // Authentication Routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register/role',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/register/user',
      builder: (context, state) => const RegisterUserScreen(),
    ),
    GoRoute(
      path: '/register/provider',
      builder: (context, state) => const RegisterProviderScreen(),
    ),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return OtpVerificationScreen(
          phone: extra?['phone'] as String? ?? '',
          purpose: extra?['purpose'] as String? ?? 'verify_phone',
          devCode: extra?['code'] as String?,
        );
      },
    ),

    // Service Routes
    GoRoute(
      path: '/service/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return ServiceDetailsScreen(serviceId: id);
      },
    ),
    GoRoute(
      path: '/provider/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ProviderProfileScreen(providerId: id);
      },
    ),
    GoRoute(
      path: '/category/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return CategoryServicesScreen(categoryId: id);
      },
    ),
  ],
);
