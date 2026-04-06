class AppConstants {
  AppConstants._();

  static const String appName = 'RideLink';
  static const String baseUrl = 'https://backend-way5.onrender.com/api';
  static const String convexUrl = 'https://resilient-crane-323.eu-west-1.convex.cloud';
  /// Must match backend `FRONTEND_URL` used by Better Auth/CORS.
  /// Ask backend team for the exact value.
  static const String frontendUrl = 'http://localhost:5173';

  // Gebeta Maps
  static const String gebetaMapsApiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb21wYW55bmFtZSI6IllvaGFubmVzIiwiZGVzY3JpcHRpb24iOiIxYWYyMmM4Ni01ODRiLTQwOGItYTBhZi04NmQ1NzYwYWExYmIiLCJpZCI6IjY1ODU3MTdiLTA3NTMtNGQ1OS1hMmZhLTg5NTFlZTg3YzcyNCIsImlzc3VlZF9hdCI6MTc3MjM0NDE2MiwiaXNzdWVyIjoiaHR0cHM6Ly9tYXBhcGkuZ2ViZXRhLmFwcCIsImp3dF9pZCI6IjAiLCJzY29wZXMiOlsiRElSRUNUSU9OIiwiR0VPQ09ESU5HIiwiVElMRSIsIk1BVFJJWCIsIk9OTSJdLCJ1c2VybmFtZSI6ImpvdmFuaSJ9.9WUsYmsAimx-1hrqP6BYSol8YoLc4lBWIdj86cId8AI';
  static const String gebetaDirectionsUrl =
      'https://mapapi.gebeta.app/api/route/direction/';
  static const String gebetaMapsBaseUrl = 'https://mapapi.gebeta.app/api/v1';
  static const String gebetaMapsStyleUrl =
      'https://tiles.gebeta.app/style.json';

  // Chapa Payment
  static const String chapaBaseUrl = 'https://api.chapa.co/v1';
  static const String chapaPublicKey = 'CHAPUBK_TEST-COgrH35nl5JCmsIQYMD1XNYr4VyMrlHi';

  // Addis Ababa default center
  static const double defaultLat = 9.0192;
  static const double defaultLng = 38.7525;
  static const double defaultZoom = 13.0;

  static const double maxPricePerKmPerSeat = 4.0;
  static const int sosCountdownSeconds = 5;
  static const int maxVehicleSeats = 10;

  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  static const Duration locationUpdateInterval = Duration(seconds: 5);
  static const Duration sessionTimeout = Duration(minutes: 30);
}
