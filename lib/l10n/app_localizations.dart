import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';
import 'app_localizations_om.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en'),
    Locale('om'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'RideLink'**
  String get appName;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to RideLink'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @passenger.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get passenger;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select Your Role'**
  String get selectRole;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @driversLicense.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s License'**
  String get driversLicense;

  /// No description provided for @vehicleModel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Model'**
  String get vehicleModel;

  /// No description provided for @vehiclePlate.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Plate Number'**
  String get vehiclePlate;

  /// No description provided for @vehicleSeats.
  ///
  /// In en, this message translates to:
  /// **'Available Seats'**
  String get vehicleSeats;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @driverDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver dashboard'**
  String get driverDashboardTitle;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @searchRide.
  ///
  /// In en, this message translates to:
  /// **'Where are you going?'**
  String get searchRide;

  /// No description provided for @origin.
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get origin;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Drop-off Location'**
  String get destination;

  /// No description provided for @availableDrivers.
  ///
  /// In en, this message translates to:
  /// **'Available Drivers'**
  String get availableDrivers;

  /// No description provided for @noDriversFound.
  ///
  /// In en, this message translates to:
  /// **'No drivers found for this route'**
  String get noDriversFound;

  /// No description provided for @bookRide.
  ///
  /// In en, this message translates to:
  /// **'Book Ride'**
  String get bookRide;

  /// No description provided for @requestBooking.
  ///
  /// In en, this message translates to:
  /// **'Request Booking'**
  String get requestBooking;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBooking;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get bookingConfirmed;

  /// No description provided for @bookingPending.
  ///
  /// In en, this message translates to:
  /// **'Booking Pending'**
  String get bookingPending;

  /// No description provided for @createTrip.
  ///
  /// In en, this message translates to:
  /// **'Create Trip'**
  String get createTrip;

  /// No description provided for @departureTime.
  ///
  /// In en, this message translates to:
  /// **'Departure Time'**
  String get departureTime;

  /// No description provided for @pricePerSeat.
  ///
  /// In en, this message translates to:
  /// **'Price per Seat'**
  String get pricePerSeat;

  /// No description provided for @seats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get seats;

  /// No description provided for @tripSchedule.
  ///
  /// In en, this message translates to:
  /// **'Trip Schedule'**
  String get tripSchedule;

  /// No description provided for @bookingRequests.
  ///
  /// In en, this message translates to:
  /// **'Booking Requests'**
  String get bookingRequests;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @liveTracking.
  ///
  /// In en, this message translates to:
  /// **'Live Tracking'**
  String get liveTracking;

  /// No description provided for @eta.
  ///
  /// In en, this message translates to:
  /// **'Estimated Arrival'**
  String get eta;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'SOS Emergency'**
  String get sos;

  /// No description provided for @sosActivated.
  ///
  /// In en, this message translates to:
  /// **'Emergency alert sent!'**
  String get sosActivated;

  /// No description provided for @sosCountdown.
  ///
  /// In en, this message translates to:
  /// **'SOS activating in {seconds}s'**
  String sosCountdown(int seconds);

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @bookingFrequency.
  ///
  /// In en, this message translates to:
  /// **'Booking frequency'**
  String get bookingFrequency;

  /// No description provided for @oneTimeTrip.
  ///
  /// In en, this message translates to:
  /// **'One time'**
  String get oneTimeTrip;

  /// No description provided for @numberOfSeats.
  ///
  /// In en, this message translates to:
  /// **'Number of seats'**
  String get numberOfSeats;

  /// No description provided for @noSeatsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No seats available on this trip'**
  String get noSeatsAvailable;

  /// No description provided for @recurringBookingNote.
  ///
  /// In en, this message translates to:
  /// **'Recurring requests are subject to driver confirmation.'**
  String get recurringBookingNote;

  /// No description provided for @passengerHomeHi.
  ///
  /// In en, this message translates to:
  /// **'Hi,'**
  String get passengerHomeHi;

  /// No description provided for @passengerHomeOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get passengerHomeOnTheWay;

  /// No description provided for @passengerHomeActiveTrips.
  ///
  /// In en, this message translates to:
  /// **'Your active trips'**
  String get passengerHomeActiveTrips;

  /// No description provided for @passengerHomeEnRouteHint.
  ///
  /// In en, this message translates to:
  /// **'En route · driver is heading to your pickup'**
  String get passengerHomeEnRouteHint;

  /// No description provided for @passengerHomeOpenLiveView.
  ///
  /// In en, this message translates to:
  /// **'Open live view'**
  String get passengerHomeOpenLiveView;

  /// No description provided for @passengerDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Current Trip'**
  String get passengerDashboardTitle;

  /// No description provided for @passengerDashboardSosShort.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get passengerDashboardSosShort;

  /// No description provided for @passengerDashboardMinutesAway.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min away'**
  String passengerDashboardMinutesAway(int minutes);

  /// No description provided for @passengerDashboardTravelBanner.
  ///
  /// In en, this message translates to:
  /// **'Have a pleasant journey.'**
  String get passengerDashboardTravelBanner;

  /// No description provided for @passengerDashboardPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get passengerDashboardPickup;

  /// No description provided for @passengerDashboardDropoff.
  ///
  /// In en, this message translates to:
  /// **'Drop-off'**
  String get passengerDashboardDropoff;

  /// No description provided for @passengerDashboardEtaLabel.
  ///
  /// In en, this message translates to:
  /// **'ETA {time}'**
  String passengerDashboardEtaLabel(String time);

  /// No description provided for @passengerDashboardSeatsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Seats'**
  String passengerDashboardSeatsCount(int count);

  /// No description provided for @passengerDashboardAcOn.
  ///
  /// In en, this message translates to:
  /// **'AC On'**
  String get passengerDashboardAcOn;

  /// No description provided for @passengerDashboardIveArrived.
  ///
  /// In en, this message translates to:
  /// **'I\'ve Arrived'**
  String get passengerDashboardIveArrived;

  /// No description provided for @passengerBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get passengerBookingsTitle;

  /// No description provided for @bookingSectionAwaitingYou.
  ///
  /// In en, this message translates to:
  /// **'Awaiting your confirmation'**
  String get bookingSectionAwaitingYou;

  /// No description provided for @bookingSectionPendingDriver.
  ///
  /// In en, this message translates to:
  /// **'Pending driver approval'**
  String get bookingSectionPendingDriver;

  /// No description provided for @bookingSectionActive.
  ///
  /// In en, this message translates to:
  /// **'Active & upcoming'**
  String get bookingSectionActive;

  /// No description provided for @bookingKindAwaitingYou.
  ///
  /// In en, this message translates to:
  /// **'Your action'**
  String get bookingKindAwaitingYou;

  /// No description provided for @bookingKindPendingDriver.
  ///
  /// In en, this message translates to:
  /// **'Awaiting driver'**
  String get bookingKindPendingDriver;

  /// No description provided for @bookingKindActive.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get bookingKindActive;

  /// No description provided for @recurrentTrip.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurrentTrip;

  /// No description provided for @bookingEmptyAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting for your confirmation'**
  String get bookingEmptyAwaiting;

  /// No description provided for @bookingEmptyPending.
  ///
  /// In en, this message translates to:
  /// **'No requests sent to drivers yet'**
  String get bookingEmptyPending;

  /// No description provided for @bookingEmptyActive.
  ///
  /// In en, this message translates to:
  /// **'No active trips'**
  String get bookingEmptyActive;

  /// No description provided for @bookingAcceptedMessage.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed. You\'re all set!'**
  String get bookingAcceptedMessage;

  /// No description provided for @bookingCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'Booking request cancelled.'**
  String get bookingCancelledMessage;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @rateYourTrip.
  ///
  /// In en, this message translates to:
  /// **'Rate Your Trip'**
  String get rateYourTrip;

  /// No description provided for @leaveComment.
  ///
  /// In en, this message translates to:
  /// **'Leave a comment (optional)'**
  String get leaveComment;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit Rating'**
  String get submitRating;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get report;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Share Your Ride'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Connect with drivers heading your way and share the cost of your daily commute.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Safe & Reliable'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Verified drivers, real-time tracking, and SOS emergency features keep you safe.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Save Money Daily'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Affordable fares capped by distance. Subscribe weekly or monthly for even better value.'**
  String get onboardingDesc3;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @etb.
  ///
  /// In en, this message translates to:
  /// **'ETB'**
  String get etb;

  /// No description provided for @perSeat.
  ///
  /// In en, this message translates to:
  /// **'/seat'**
  String get perSeat;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @verifyIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verify identity'**
  String get verifyIdentity;

  /// No description provided for @mySubscriptions.
  ///
  /// In en, this message translates to:
  /// **'My subscriptions'**
  String get mySubscriptions;

  /// No description provided for @pendingVerification.
  ///
  /// In en, this message translates to:
  /// **'Your account is pending verification. Please wait for admin approval.'**
  String get pendingVerification;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @myTrips.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get myTrips;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @totalTrips.
  ///
  /// In en, this message translates to:
  /// **'Total Trips'**
  String get totalTrips;

  /// No description provided for @activeTrip.
  ///
  /// In en, this message translates to:
  /// **'Active Trip'**
  String get activeTrip;

  /// No description provided for @scheduledTrips.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Trips'**
  String get scheduledTrips;

  /// No description provided for @completedTrips.
  ///
  /// In en, this message translates to:
  /// **'Completed Trips'**
  String get completedTrips;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @preferredRoutes.
  ///
  /// In en, this message translates to:
  /// **'Preferred Routes'**
  String get preferredRoutes;

  /// No description provided for @emergencyAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Alert'**
  String get emergencyAlertTitle;

  /// No description provided for @emergencyAlertSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s the emergency?'**
  String get emergencyAlertSubtitle;

  /// No description provided for @emergencyTypeCarMalfunction.
  ///
  /// In en, this message translates to:
  /// **'Car malfunction'**
  String get emergencyTypeCarMalfunction;

  /// No description provided for @emergencyTypeMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical emergency'**
  String get emergencyTypeMedical;

  /// No description provided for @emergencyTypeSuspicious.
  ///
  /// In en, this message translates to:
  /// **'Suspicious activity'**
  String get emergencyTypeSuspicious;

  /// No description provided for @emergencyTypeAccident.
  ///
  /// In en, this message translates to:
  /// **'Accident'**
  String get emergencyTypeAccident;

  /// No description provided for @emergencySendAlert.
  ///
  /// In en, this message translates to:
  /// **'Send Emergency Alert'**
  String get emergencySendAlert;

  /// No description provided for @emergencySendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send alert. Try again or call emergency services.'**
  String get emergencySendFailed;

  /// No description provided for @profileNamePhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and phone number are required'**
  String get profileNamePhoneRequired;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @profileActivityAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get profileActivityAccountCreated;

  /// No description provided for @profileActivityDriverConfigured.
  ///
  /// In en, this message translates to:
  /// **'Driver profile configured'**
  String get profileActivityDriverConfigured;

  /// No description provided for @profileActivityPassengerActive.
  ///
  /// In en, this message translates to:
  /// **'Passenger profile active'**
  String get profileActivityPassengerActive;

  /// No description provided for @profileActivityVehicleDetails.
  ///
  /// In en, this message translates to:
  /// **'Vehicle details available'**
  String get profileActivityVehicleDetails;

  /// No description provided for @profileActivityReadyToBook.
  ///
  /// In en, this message translates to:
  /// **'Ready to book rides'**
  String get profileActivityReadyToBook;

  /// No description provided for @profileActivityIdentityVerification.
  ///
  /// In en, this message translates to:
  /// **'Identity verification'**
  String get profileActivityIdentityVerification;

  /// No description provided for @profileStatusGoodStanding.
  ///
  /// In en, this message translates to:
  /// **'In good standing'**
  String get profileStatusGoodStanding;

  /// No description provided for @profileStatusPendingVerificationDetails.
  ///
  /// In en, this message translates to:
  /// **'Pending verification details'**
  String get profileStatusPendingVerificationDetails;

  /// No description provided for @profileActivityManageAlerts.
  ///
  /// In en, this message translates to:
  /// **'Manage alerts from your account menu'**
  String get profileActivityManageAlerts;

  /// No description provided for @profilePersonalDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get profilePersonalDetailsTitle;

  /// No description provided for @profilePersonalDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account information used for bookings and safety.'**
  String get profilePersonalDetailsSubtitle;

  /// No description provided for @profileDriverDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver details'**
  String get profileDriverDetailsTitle;

  /// No description provided for @profileDriverDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle details visible to passengers while booking.'**
  String get profileDriverDetailsSubtitle;

  /// No description provided for @profileQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get profileQuickActionsTitle;

  /// No description provided for @profileQuickActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently used account actions and preferences.'**
  String get profileQuickActionsSubtitle;

  /// No description provided for @profileRecentActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get profileRecentActivityTitle;

  /// No description provided for @profileRecentActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'A quick overview of your latest account events.'**
  String get profileRecentActivitySubtitle;

  /// No description provided for @profileNoActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get profileNoActivityTitle;

  /// No description provided for @profileNoActivityMessage.
  ///
  /// In en, this message translates to:
  /// **'Once you book rides or update your profile, updates will appear here.'**
  String get profileNoActivityMessage;

  /// No description provided for @profileCompletionLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile completion'**
  String get profileCompletionLabel;

  /// No description provided for @profileRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profileRoleLabel;

  /// No description provided for @profileStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get profileStatusLabel;

  /// No description provided for @profileStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get profileStatusActive;

  /// No description provided for @profileStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get profileStatusPending;

  /// No description provided for @profileNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get profileNotProvided;

  /// No description provided for @profileEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your personal details and ride identity information.'**
  String get profileEditSubtitle;

  /// No description provided for @profilePhotoUploadPreview.
  ///
  /// In en, this message translates to:
  /// **'Photo upload preview'**
  String get profilePhotoUploadPreview;

  /// No description provided for @profilePhotoSyncingNote.
  ///
  /// In en, this message translates to:
  /// **'Photo syncing will be enabled in the next API update.'**
  String get profilePhotoSyncingNote;

  /// No description provided for @profileBasicInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic information'**
  String get profileBasicInformationTitle;

  /// No description provided for @profileBasicInformationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This information appears to riders and admins.'**
  String get profileBasicInformationSubtitle;

  /// No description provided for @profileVehicleInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle information'**
  String get profileVehicleInformationTitle;

  /// No description provided for @profileVehicleInformationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep these details current so passengers can trust your listing.'**
  String get profileVehicleInformationSubtitle;

  /// No description provided for @profileSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get profileSaving;

  /// No description provided for @profileUserLabel.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get profileUserLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en', 'om'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
    case 'om':
      return AppLocalizationsOm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
