// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

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
}
