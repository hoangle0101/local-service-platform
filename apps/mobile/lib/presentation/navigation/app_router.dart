import 'package:go_router/go_router.dart';
import '../../../core/entities/entities.dart';
import '../screens/guest_home_screen.dart';
import '../screens/service_details_screen.dart';
import '../screens/booking/create_booking_screen.dart';
import '../screens/booking/complete_booking_screen.dart';
import '../screens/category_services_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/register_user_screen.dart';
import '../screens/auth/register_provider_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/user/user_home_screen.dart';
import '../screens/user/user_profile_screen.dart';
import '../screens/user/user_bookings_screen.dart';
import '../screens/user/user_favorites_screen.dart';
import '../screens/provider/provider_home_screen.dart';
import '../screens/provider/provider_profile_screen.dart';
import '../screens/provider/provider_services_screen.dart';
import '../screens/provider/provider_bookings_screen.dart';
import '../screens/provider/provider_edit_profile_screen.dart';

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

    // User Routes
    GoRoute(
      path: '/user/home',
      builder: (context, state) => const UserHomeScreen(),
    ),
    GoRoute(
      path: '/user/profile',
      builder: (context, state) => const UserProfileScreen(),
    ),
    GoRoute(
      path: '/user/bookings',
      builder: (context, state) => const UserBookingsScreen(),
    ),
    GoRoute(
      path: '/user/favorites',
      builder: (context, state) => const UserFavoritesScreen(),
    ),

    // Provider Routes
    GoRoute(
      path: '/provider/home',
      builder: (context, state) => const ProviderHomeScreen(),
    ),
    GoRoute(
      path: '/provider/profile',
      builder: (context, state) => const ProviderProfileScreen(),
    ),
    GoRoute(
      path: '/provider/services',
      builder: (context, state) => const ProviderServicesScreen(),
    ),
    GoRoute(
      path: '/provider/bookings',
      builder: (context, state) => const ProviderBookingsScreen(),
    ),
    GoRoute(
      path: '/provider/profile/edit',
      builder: (context, state) => const ProviderEditProfileScreen(),
    ),

    // Service Routes
    GoRoute(
      path: '/service/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        final service = state.extra as ProviderService?;
        return ServiceDetailsScreen(
          serviceId: id,
          service: service,
        );
      },
    ),

    // Booking Routes
    GoRoute(
      path: '/booking/new',
      builder: (context, state) => const CompleteBookingScreen(),
    ),
    GoRoute(
      path: '/booking/create',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return CreateBookingScreen(
          serviceId: extra['serviceId'] as int,
          service: extra['service'] as ProviderService?,
        );
      },
    ),

    // Category Routes
    GoRoute(
      path: '/category/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        final category = state.extra as Category?;
        return CategoryServicesScreen(
          categoryId: id,
          category: category,
        );
      },
    ),
  ],
);
