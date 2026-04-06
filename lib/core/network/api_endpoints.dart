class ApiEndpoints {
  ApiEndpoints._();

  // Auth (Better Auth)
  static const String signIn = '/auth/sign-in/email';
  static const String signUp = '/auth/sign-up/email';
  static const String signOut = '/auth/sign-out';
  static const String getSession = '/auth/get-session';
  static const String getToken = '/auth/token';

  // User
  static const String completeProfile = '/users/complete-profile';
  static const String becomeDriver = '/users/become-driver';
  // Uploads (presigned URLs)
  static const String presignUpload = '/upload';
  static const String completeUpload = '/complete';

  // Trips
  static const String trips = '/trips';
  static String tripById(String id) => '/trips/$id';
  static String tripStatus(String id) => '/trips/$id/status';
  static String tripBookings(String tripId) => '/trips/$tripId/bookings';
  static String driverTrips(String driverId) => '/trips/drivers/$driverId/trips';
  static String passengerBookings(String passengerId) =>
      '/trips/passengers/$passengerId/bookings';

  // Bookings
  static const String createBooking = '/trips/bookings';
  static String bookingById(String id) => '/trips/bookings/$id';
  static String acceptBooking(String id) => '/trips/bookings/$id/accept';
  static String declineBooking(String id) => '/trips/bookings/$id/decline';
  static String cancelBooking(String id) => '/trips/bookings/$id/cancel';

  // Series
  static const String series = '/series';
  static String seriesById(String id) => '/series/$id';
  static String deactivateSeries(String id) => '/series/$id/deactivate';
  static String generateTrips(String id) => '/series/$id/generate';
  static String seriesSubscriptions(String seriesId) =>
      '/series/$seriesId/subscriptions';

  // Subscriptions
  static const String createSubscription = '/series/subscriptions';
  static String subscriptionById(String id) => '/series/subscriptions/$id';
  static String cancelSubscription(String id) =>
      '/series/subscriptions/$id/cancel';
  static String passengerSubscriptions(String passengerId) =>
      '/series/passengers/$passengerId/subscriptions';

  // Feedback
  static const String feedback = '/feedback';
  static String feedbackForUser(String userId) => '/feedback/$userId';

  // Notifications (Convex-only, no REST endpoints)

  // Emergency (Convex-only, no REST endpoints)
}
