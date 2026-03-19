import 'package:convex_flutter/convex_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/network/api_client.dart';
import 'core/services/chapa_service.dart';
import 'core/services/gebeta_maps_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/locale_provider.dart';
import 'core/services/location_service.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/driver/trip/providers/trip_provider.dart';
import 'features/driver/trip/providers/trip_series_provider.dart';
import 'features/emergency/providers/emergency_provider.dart';
import 'features/feedback/providers/feedback_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/passenger/booking/providers/booking_provider.dart';
import 'features/passenger/search/providers/search_provider.dart';
import 'features/payment/providers/payment_provider.dart';
import 'features/tracking/providers/tracking_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  final apiClient = ApiClient(storageService);
  final locationService = LocationService();
  final gebetaMapsService = GebetaMapsService();
  final chapaService = ChapaService();

  ConvexClient? convex;
  final isConvexConfigured =
      !AppConstants.convexUrl.contains('your-convex-deployment');
  if (isConvexConfigured) {
    await ConvexClient.initialize(
      ConvexConfig(
        deploymentUrl: AppConstants.convexUrl,
        clientId: 'ridelink-flutter',
        operationTimeout: const Duration(seconds: 30),
      ),
    );
    convex = ConvexClient.instance;
  }

  runApp(
    MultiProvider(
      providers: [
        // Core services
        Provider.value(value: apiClient),
        Provider.value(value: storageService),
        Provider.value(value: locationService),
        Provider.value(value: gebetaMapsService),
        Provider.value(value: chapaService),
        Provider<ConvexClient?>.value(value: convex),

        // Theme & locale
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider(storageService)),

        // Auth
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiClient, storageService),
        ),

        // Real-time providers
        ChangeNotifierProvider(
          create: (_) => TrackingProvider(convex, locationService),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(convex, ''),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(convex, ''),
        ),

        // Trip & booking
        ChangeNotifierProvider(
            create: (_) => TripProvider(apiClient, storageService)),
        ChangeNotifierProvider(
          create: (_) => SearchProvider(apiClient, gebetaMapsService),
        ),
        ChangeNotifierProvider(
            create: (_) => BookingProvider(apiClient, storageService)),
        ChangeNotifierProvider(
            create: (_) => TripSeriesProvider(apiClient, storageService)),

        // Payment
        ChangeNotifierProvider(
          create: (_) => PaymentProvider(chapaService, apiClient),
        ),

        // Emergency & feedback
        ChangeNotifierProvider(
          create: (_) => EmergencyProvider(convex, locationService),
        ),
        ChangeNotifierProvider(create: (_) => FeedbackProvider(apiClient)),
      ],
      child: const RideLinkApp(),
    ),
  );
}
