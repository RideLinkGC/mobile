// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'RideLink';

  @override
  String get welcome => 'Welcome to RideLink';

  @override
  String get login => 'Log In';

  @override
  String get register => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get passenger => 'Passenger';

  @override
  String get driver => 'Driver';

  @override
  String get selectRole => 'Select Your Role';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get nationalId => 'National ID';

  @override
  String get driversLicense => 'Driver\'s License';

  @override
  String get vehicleModel => 'Vehicle Model';

  @override
  String get vehiclePlate => 'Vehicle Plate Number';

  @override
  String get vehicleSeats => 'Available Seats';

  @override
  String get uploadDocument => 'Upload Document';

  @override
  String get next => 'Next';

  @override
  String get submit => 'Submit';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get search => 'Search';

  @override
  String get home => 'Home';

  @override
  String get driverDashboardTitle => 'Driver dashboard';

  @override
  String get trips => 'Trips';

  @override
  String get chat => 'Chat';

  @override
  String get profile => 'Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get settings => 'Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get logout => 'Log Out';

  @override
  String get searchRide => 'Where are you going?';

  @override
  String get origin => 'Pickup Location';

  @override
  String get destination => 'Drop-off Location';

  @override
  String get availableDrivers => 'Available Drivers';

  @override
  String get noDriversFound => 'No drivers found for this route';

  @override
  String get bookRide => 'Book Ride';

  @override
  String get requestBooking => 'Request Booking';

  @override
  String get cancelBooking => 'Cancel Booking';

  @override
  String get bookingConfirmed => 'Booking Confirmed';

  @override
  String get bookingPending => 'Booking Pending';

  @override
  String get createTrip => 'Create Trip';

  @override
  String get departureTime => 'Departure Time';

  @override
  String get pricePerSeat => 'Price per Seat';

  @override
  String get seats => 'Seats';

  @override
  String get tripSchedule => 'Trip Schedule';

  @override
  String get bookingRequests => 'Booking Requests';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get liveTracking => 'Live Tracking';

  @override
  String get eta => 'Estimated Arrival';

  @override
  String get sos => 'SOS Emergency';

  @override
  String get sosActivated => 'Emergency alert sent!';

  @override
  String sosCountdown(int seconds) {
    return 'SOS activating in ${seconds}s';
  }

  @override
  String get payment => 'Payment';

  @override
  String get payNow => 'Pay Now';

  @override
  String get paymentHistory => 'Payment History';

  @override
  String get subscription => 'Subscription';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get bookingFrequency => 'Booking frequency';

  @override
  String get oneTimeTrip => 'One time';

  @override
  String get numberOfSeats => 'Number of seats';

  @override
  String get noSeatsAvailable => 'No seats available on this trip';

  @override
  String get recurringBookingNote =>
      'Recurring requests are subject to driver confirmation.';

  @override
  String get passengerHomeHi => 'Hi,';

  @override
  String get passengerHomeOnTheWay => 'On the way';

  @override
  String get passengerHomeActiveTrips => 'Your active trips';

  @override
  String get passengerHomeEnRouteHint =>
      'En route · driver is heading to your pickup';

  @override
  String get passengerHomeOpenLiveView => 'Open live view';

  @override
  String get passengerDashboardTitle => 'Current Trip';

  @override
  String get passengerDashboardSosShort => 'SOS';

  @override
  String passengerDashboardMinutesAway(int minutes) {
    return '$minutes min away';
  }

  @override
  String get passengerDashboardTravelBanner => 'Have a pleasant journey.';

  @override
  String get passengerDashboardPickup => 'Pickup';

  @override
  String get passengerDashboardDropoff => 'Drop-off';

  @override
  String passengerDashboardEtaLabel(String time) {
    return 'ETA $time';
  }

  @override
  String passengerDashboardSeatsCount(int count) {
    return '$count Seats';
  }

  @override
  String get passengerDashboardAcOn => 'AC On';

  @override
  String get passengerDashboardIveArrived => 'I\'ve Arrived';

  @override
  String get passengerBookingsTitle => 'Bookings';

  @override
  String get bookingSectionAwaitingYou => 'Awaiting your confirmation';

  @override
  String get bookingSectionPendingDriver => 'Pending driver approval';

  @override
  String get bookingSectionActive => 'Active & upcoming';

  @override
  String get bookingKindAwaitingYou => 'Your action';

  @override
  String get bookingKindPendingDriver => 'Awaiting driver';

  @override
  String get bookingKindActive => 'Confirmed';

  @override
  String get recurrentTrip => 'Recurring';

  @override
  String get bookingEmptyAwaiting => 'Nothing waiting for your confirmation';

  @override
  String get bookingEmptyPending => 'No requests sent to drivers yet';

  @override
  String get bookingEmptyActive => 'No active trips';

  @override
  String get bookingAcceptedMessage => 'Booking confirmed. You\'re all set!';

  @override
  String get bookingCancelledMessage => 'Booking request cancelled.';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get rating => 'Rating';

  @override
  String get rateYourTrip => 'Rate Your Trip';

  @override
  String get leaveComment => 'Leave a comment (optional)';

  @override
  String get submitRating => 'Submit Rating';

  @override
  String get report => 'Report Issue';

  @override
  String get onboardingTitle1 => 'Share Your Ride';

  @override
  String get onboardingDesc1 =>
      'Connect with drivers heading your way and share the cost of your daily commute.';

  @override
  String get onboardingTitle2 => 'Safe & Reliable';

  @override
  String get onboardingDesc2 =>
      'Verified drivers, real-time tracking, and SOS emergency features keep you safe.';

  @override
  String get onboardingTitle3 => 'Save Money Daily';

  @override
  String get onboardingDesc3 =>
      'Affordable fares capped by distance. Subscribe weekly or monthly for even better value.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get skip => 'Skip';

  @override
  String get etb => 'ETB';

  @override
  String get perSeat => '/seat';

  @override
  String get km => 'km';

  @override
  String get verifyIdentity => 'Verify identity';

  @override
  String get mySubscriptions => 'My subscriptions';

  @override
  String get pendingVerification =>
      'Your account is pending verification. Please wait for admin approval.';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get myTrips => 'My Trips';

  @override
  String get earnings => 'Earnings';

  @override
  String get totalTrips => 'Total Trips';

  @override
  String get activeTrip => 'Active Trip';

  @override
  String get scheduledTrips => 'Scheduled Trips';

  @override
  String get completedTrips => 'Completed Trips';

  @override
  String get about => 'About';

  @override
  String get preferredRoutes => 'Preferred Routes';

  @override
  String get emergencyAlertTitle => 'Emergency Alert';

  @override
  String get emergencyAlertSubtitle => 'What\'s the emergency?';

  @override
  String get emergencyTypeCarMalfunction => 'Car malfunction';

  @override
  String get emergencyTypeMedical => 'Medical emergency';

  @override
  String get emergencyTypeSuspicious => 'Suspicious activity';

  @override
  String get emergencyTypeAccident => 'Accident';

  @override
  String get emergencySendAlert => 'Send Emergency Alert';

  @override
  String get emergencySendFailed =>
      'Could not send alert. Try again or call emergency services.';
}
