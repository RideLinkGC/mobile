import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/driver_setup_screen.dart';
import '../../features/passenger/home/screens/passenger_home_screen.dart';
import '../../features/driver/home/screens/driver_home_screen.dart';
import '../../features/passenger/search/screens/search_screen.dart';
import '../../features/passenger/search/screens/search_results_screen.dart';
import '../../features/passenger/search/screens/driver_detail_screen.dart';
import '../../features/passenger/booking/screens/booking_confirm_screen.dart';
import '../../features/passenger/booking/screens/active_booking_screen.dart';
import '../../features/driver/trip/screens/create_trip_screen.dart';
import '../../features/driver/trip/screens/trip_detail_screen.dart';
import '../../features/driver/trip/screens/booking_requests_screen.dart';
import '../../features/tracking/screens/live_tracking_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/payment/screens/payment_screen.dart';
import '../../features/payment/screens/payment_history_screen.dart';
import '../../features/payment/screens/subscription_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/profile/screens/verification_screen.dart';
import '../../features/driver/trip/screens/create_series_screen.dart';
import '../../features/passenger/booking/screens/my_subscriptions_screen.dart';
import '../../features/passenger/booking/screens/passenger_bookings_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/emergency/screens/sos_screen.dart';
import '../../features/feedback/screens/rating_screen.dart';
import '../../features/feedback/screens/report_screen.dart';
import '../widgets/main_scaffold.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      redirect: (context, state) {
        final isAuth = authProvider.isAuthenticated;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/register/driver-setup' ||
            state.matchedLocation == '/register/driver-documents' ||
            state.matchedLocation == '/onboarding' ||
            state.matchedLocation == '/splash';

        if (!isAuth && !isAuthRoute) return '/login';
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/register/driver-setup',
          builder: (context, state) => const DriverSetupScreen(),
        ),
        GoRoute(
          path: '/register/driver-documents',
          builder: (context, state) => const DriverDocumentsScreen(),
        ),

        // Passenger shell
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => MainScaffold(child: child),
          routes: [
            GoRoute(
              path: '/passenger',
              builder: (context, state) => const PassengerHomeScreen(),
            ),
            GoRoute(
              path: '/driver',
              builder: (context, state) => const DriverHomeScreen(),
            ),
            GoRoute(
              path: '/chat-list',
              builder: (context, state) => const ChatListScreen(),
            ),
            GoRoute(
              path: '/passenger-bookings',
              builder: (context, state) => const PassengerBookingsScreen(),
            ),
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),

        // Full-screen routes
        GoRoute(
          path: '/search-results',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return SearchResultsScreen(
              origin: extra?['origin'] as String? ?? '',
              destination: extra?['destination'] as String? ?? '',
            );
          },
        ),
        GoRoute(
          path: '/driver-detail/:tripId',
          builder: (context, state) => DriverDetailScreen(
            tripId: state.pathParameters['tripId']!,
          ),
        ),
        GoRoute(
          path: '/booking-confirm/:tripId',
          builder: (context, state) => BookingConfirmScreen(
            tripId: state.pathParameters['tripId']!,
          ),
        ),
        GoRoute(
          path: '/active-booking/:tripId',
          builder: (context, state) => ActiveBookingScreen(
            tripId: state.pathParameters['tripId']!,
          ),
        ),
        GoRoute(
          path: '/create-trip',
          builder: (context, state) => const CreateTripScreen(),
        ),
        GoRoute(
          path: '/booking-requests/:tripId',
          builder: (context, state) => BookingRequestsScreen(
            tripId: state.pathParameters['tripId']!,
          ),
        ),
        GoRoute(
          path: '/trip-detail/:tripId',
          builder: (context, state) => TripDetailScreen(
            tripId: state.pathParameters['tripId'],
          ),
        ),
        GoRoute(
          path: '/tracking/:tripId',
          builder: (context, state) => LiveTrackingScreen(
            tripId: state.pathParameters['tripId']!,
          ),
        ),
        GoRoute(
          path: '/chat/:conversationId',
          builder: (context, state) => ChatScreenPage(
            conversationId: state.pathParameters['conversationId']!,
          ),
        ),
        GoRoute(
          path: '/payment/:bookingId',
          builder: (context, state) => PaymentScreen(
            bookingId: state.pathParameters['bookingId']!,
          ),
        ),
        GoRoute(
          path: '/payment-history',
          builder: (context, state) => const PaymentHistoryScreen(),
        ),
        GoRoute(
          path: '/subscription/:tripId',
          builder: (context, state) => SubscriptionScreen(
            tripId: state.pathParameters['tripId']!,
          ),
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/verification',
          builder: (context, state) => const VerificationScreen(),
        ),
        GoRoute(
          path: '/create-series',
          builder: (context, state) => const CreateSeriesScreen(),
        ),
        GoRoute(
          path: '/my-subscriptions',
          builder: (context, state) => const MySubscriptionsScreen(),
        ),
        GoRoute(
          path: '/sos/:tripId',
          builder: (context, state) => SosScreen(
            tripId: state.pathParameters['tripId']!,
          ),
        ),
        GoRoute(
          path: '/rating/:tripId',
          builder: (context, state) => RatingScreen(
            tripId: state.pathParameters['tripId']!,
          ),
        ),
        GoRoute(
          path: '/report/:targetId',
          builder: (context, state) => ReportScreen(
            targetId: state.pathParameters['targetId']!,
          ),
        ),
      ],
    );
  }
}
