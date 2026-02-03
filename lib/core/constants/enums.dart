enum UserRole { passenger, driver, admin }

enum UserStatus { active, pending, deactivated }

enum TripStatus { scheduled, inProgress, completed, canceled }

enum BookingStatus { pending, confirmed, canceled, completed }

enum PaymentStatus { pending, completed, failed }

enum PaymentMethod { inApp, cash }

enum SubscriptionType { weekly, monthly }

enum FeedbackType { rating, report }

enum TrackingStatus { active, paused, completed }

enum EmergencyAlertStatus { active, resolved }

enum NotificationType {
  bookingRequest,
  bookingConfirmed,
  bookingDeclined,
  bookingCancelled,
  tripStarted,
  tripCompleted,
  tripCancelled,
  sosAlert,
  sosResolved,
  warning,
  system,
}
