// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Oromo (`om`).
class AppLocalizationsOm extends AppLocalizations {
  AppLocalizationsOm([String locale = 'om']) : super(locale);

  @override
  String get appName => 'RideLink';

  @override
  String get welcome => 'Baga nagaan RideLink dhuftan';

  @override
  String get login => 'Seeni';

  @override
  String get register => 'Galmaa\'i';

  @override
  String get email => 'Imeelii';

  @override
  String get password => 'Jecha darbii';

  @override
  String get forgotPassword => 'Jecha darbii irraanfatte?';

  @override
  String get dontHaveAccount => 'Herrega hin qabdu?';

  @override
  String get alreadyHaveAccount => 'Duraan herrega qabda?';

  @override
  String get passenger => 'Imaltuu';

  @override
  String get driver => 'Konkolaachisaa';

  @override
  String get selectRole => 'Gahee kee filadhu';

  @override
  String get fullName => 'Maqaa guutuu';

  @override
  String get phoneNumber => 'Lakkoofsa bilbilaa';

  @override
  String get nationalId => 'Eenyummaa biyyaalessaa';

  @override
  String get driversLicense => 'Hayyama konkolaachisummaa';

  @override
  String get vehicleModel => 'Moodeela konkolaataa';

  @override
  String get vehiclePlate => 'Lakkoofsa gabatee';

  @override
  String get vehicleSeats => 'Teessoo jiran';

  @override
  String get uploadDocument => 'Sanad olkaa\'i';

  @override
  String get next => 'Itti aanee';

  @override
  String get submit => 'Galchi';

  @override
  String get cancel => 'Haqi';

  @override
  String get confirm => 'Mirkaneessi';

  @override
  String get save => 'Olkaa\'i';

  @override
  String get search => 'Barbaadi';

  @override
  String get home => 'Mana';

  @override
  String get driverDashboardTitle => 'Driver dashboard';

  @override
  String get trips => 'Imala';

  @override
  String get chat => 'Haasaa';

  @override
  String get profile => 'Seenaa';

  @override
  String get notifications => 'Beeksisa';

  @override
  String get settings => 'Qindaa\'ina';

  @override
  String get darkMode => 'Haala dukkana';

  @override
  String get language => 'Afaan';

  @override
  String get logout => 'Ba\'i';

  @override
  String get searchRide => 'Eessa deemta?';

  @override
  String get origin => 'Bakka ka\'umsaa';

  @override
  String get destination => 'Bakka ga\'umsaa';

  @override
  String get availableDrivers => 'Konkolaachistoota jiran';

  @override
  String get noDriversFound => 'Daandii kanaaf konkolaachisaan hin argamne';

  @override
  String get bookRide => 'Imala qabadhu';

  @override
  String get requestBooking => 'Teessoo gaafadhu';

  @override
  String get cancelBooking => 'Teessoo haqi';

  @override
  String get bookingConfirmed => 'Teessoon mirkanaa\'eera';

  @override
  String get bookingPending => 'Teessoon eegamaa jira';

  @override
  String get createTrip => 'Imala uumi';

  @override
  String get departureTime => 'Sa\'aatii ka\'umsaa';

  @override
  String get pricePerSeat => 'Gatii teessoo';

  @override
  String get seats => 'Teessoo';

  @override
  String get tripSchedule => 'Sagantaa imalaa';

  @override
  String get bookingRequests => 'Gaaffii teessoo';

  @override
  String get accept => 'Fudhu';

  @override
  String get decline => 'Diddi';

  @override
  String get liveTracking => 'Hordoffii kallattii';

  @override
  String get eta => 'Yeroo ga\'umsaa tilmaamame';

  @override
  String get sos => 'Balaa yeroo muddamaa';

  @override
  String get sosActivated => 'Akeekkachiisni balaa ergameera!';

  @override
  String sosCountdown(int seconds) {
    return 'SOS sekondii $seconds keessatti hojjeta';
  }

  @override
  String get payment => 'Kaffaltii';

  @override
  String get payNow => 'Amma kafali';

  @override
  String get paymentHistory => 'Seenaa kaffaltii';

  @override
  String get subscription => 'Miseensa';

  @override
  String get weekly => 'Torbaniin';

  @override
  String get monthly => 'Ji\'aan';

  @override
  String get bookingFrequency => 'Sadarkaa teessoo';

  @override
  String get oneTimeTrip => 'Yeroo tokko';

  @override
  String get numberOfSeats => 'Lakkoofsa teessoo';

  @override
  String get noSeatsAvailable => 'Imala kana irratti teessi hin jiru';

  @override
  String get recurringBookingNote =>
      'Gaaffiin yeroo irraa gara yerootti mirkanaa\'ina konkolaachisaa irratti hunda\'ame.';

  @override
  String get passengerHomeHi => 'Akkam,';

  @override
  String get passengerHomeOnTheWay => 'Karaa irratti';

  @override
  String get passengerHomeActiveTrips => 'Imala hojii irratti kee';

  @override
  String get passengerHomeEnRouteHint =>
      'Imala irratti · konkolaachisni fudhata kee irratti deemaa jira';

  @override
  String get passengerHomeOpenLiveView => 'Mul\'isa kallattii banaa';

  @override
  String get passengerDashboardTitle => 'Imala ammaa';

  @override
  String get passengerDashboardSosShort => 'SOS';

  @override
  String passengerDashboardMinutesAway(int minutes) {
    return 'Daqiiqaa $minutes booda';
  }

  @override
  String get passengerDashboardTravelBanner => 'Imala gaarii taasisaa!';

  @override
  String get passengerDashboardPickup => 'Fudhachuu';

  @override
  String get passengerDashboardDropoff => 'Gadi bu\'uu';

  @override
  String passengerDashboardEtaLabel(String time) {
    return 'Yeroo eegamaa $time';
  }

  @override
  String passengerDashboardSeatsCount(int count) {
    return 'Teessoo $count';
  }

  @override
  String get passengerDashboardAcOn => 'AC mallattee';

  @override
  String get passengerDashboardIveArrived => 'Dhufe';

  @override
  String get passengerBookingsTitle => 'Teessoo';

  @override
  String get bookingSectionAwaitingYou => 'Mirkanaa\'ina kee eegaa jira';

  @override
  String get bookingSectionPendingDriver =>
      'Mirkanaa\'ina konkolaachisaa eegaa jira';

  @override
  String get bookingSectionActive => 'Hojii irratti fi kan dhufu';

  @override
  String get bookingKindAwaitingYou => 'Gocha kee';

  @override
  String get bookingKindPendingDriver => 'Konkolaachisaa eegaa';

  @override
  String get bookingKindActive => 'Mirkanaa\'e';

  @override
  String get recurrentTrip => 'Deebi\'aa';

  @override
  String get bookingEmptyAwaiting => 'Mirkanaa\'ina kee eegu waan hin jirre';

  @override
  String get bookingEmptyPending => 'Konkolaachisaatti gaaffiin hin ergamne';

  @override
  String get bookingEmptyActive => 'Imalli hojii irratti hin jiru';

  @override
  String get bookingAcceptedMessage => 'Teessoon mirkanaa\'e. Tole!';

  @override
  String get bookingCancelledMessage => 'Gaaffiin teessoo haqameera.';

  @override
  String get subscribe => 'Miseensa ta\'i';

  @override
  String get rating => 'Sadarkaa';

  @override
  String get rateYourTrip => 'Imala kee madaali';

  @override
  String get leaveComment => 'Yaada kenni (dirqama miti)';

  @override
  String get submitRating => 'Sadarkaa galchi';

  @override
  String get report => 'Rakkoo gabaasi';

  @override
  String get onboardingTitle1 => 'Imala Kee Qoodi';

  @override
  String get onboardingDesc1 =>
      'Konkolaachistoota gara kee deeman waliin wal qunnamii baasii imala guyyaa kee qoodi.';

  @override
  String get onboardingTitle2 => 'Nageenya & Amanamummaa';

  @override
  String get onboardingDesc2 =>
      'Konkolaachistoota mirkanaa\'an, hordoffii kallattii fi amaloota balaa yeroo muddamaa nageenya kee eegu.';

  @override
  String get onboardingTitle3 => 'Guyyuu Maallaqa Qusadhu';

  @override
  String get onboardingDesc3 =>
      'Gatii fageenyaan daangeffame. Torbaniin ykn ji\'aan galmaa\'uun caalaatti si fayyada.';

  @override
  String get getStarted => 'Jalqabi';

  @override
  String get skip => 'Irra darbi';

  @override
  String get etb => 'Br';

  @override
  String get perSeat => '/teessoo';

  @override
  String get km => 'km';

  @override
  String get verifyIdentity => 'Mallattoo mirkaneessi';

  @override
  String get mySubscriptions => 'Miseensota koo';

  @override
  String get pendingVerification =>
      'Herregni kee mirkanaa\'aa jira. Maaloo hayyama bulchiinsaa eegi.';

  @override
  String get editProfile => 'Seenaa gulaali';

  @override
  String get myTrips => 'Imala koo';

  @override
  String get earnings => 'Galii';

  @override
  String get totalTrips => 'Imala waliigalaa';

  @override
  String get activeTrip => 'Imala hojii irra jiru';

  @override
  String get scheduledTrips => 'Imala qophaa\'e';

  @override
  String get completedTrips => 'Imala xumurame';

  @override
  String get about => 'Waa\'ee';

  @override
  String get preferredRoutes => 'Daandii filatame';

  @override
  String get emergencyAlertTitle => 'Akeekkachiisa balaa';

  @override
  String get emergencyAlertSubtitle => 'Balaa maal?';

  @override
  String get emergencyTypeCarMalfunction => 'Konkolataa dogoggora';

  @override
  String get emergencyTypeMedical => 'Balaa fayyaa';

  @override
  String get emergencyTypeSuspicious => 'Sochii shakkii qabu';

  @override
  String get emergencyTypeAccident => 'Balaa konkolaachisummaa';

  @override
  String get emergencySendAlert => 'Akeekkachiisa balaa ergi';

  @override
  String get emergencySendFailed =>
      'Erguu hin dandeenye. Irra deebi\'ii yookiin tajaajila balaa bilbilaa.';

  @override
  String get profileNamePhoneRequired =>
      'Maqaa fi lakkoofsa bilbilaa guutuun dirqama';

  @override
  String get profileUpdatedSuccessfully =>
      'Seenaa fayyadamaa milkaa\'inaan haaromfameera';

  @override
  String get profileActivityAccountCreated => 'Herregni uumameera';

  @override
  String get profileActivityDriverConfigured =>
      'Seenaa konkolaachisaa qindaa\'eera';

  @override
  String get profileActivityPassengerActive => 'Seenaa imaltuu hojii irra jira';

  @override
  String get profileActivityVehicleDetails => 'Odeeffannoon konkolaataa jira';

  @override
  String get profileActivityReadyToBook => 'Imala qabachuuf qophaa\'eera';

  @override
  String get profileActivityIdentityVerification => 'Mirkaneessa eenyummaa';

  @override
  String get profileStatusGoodStanding => 'Haala gaarii keessa jira';

  @override
  String get profileStatusPendingVerificationDetails =>
      'Bal\'inaan mirkaneessaa eegaa jira';

  @override
  String get profileActivityManageAlerts =>
      'Akeekkachiisota keessaa menu herregaa keetiin bulchi';

  @override
  String get profilePersonalDetailsTitle => 'Bal\'ina dhuunfaa';

  @override
  String get profilePersonalDetailsSubtitle =>
      'Odeeffannoo herregaa kee kan qabuu, nageenyaa fi qabduu teessoo irratti fayyadamu.';

  @override
  String get profileDriverDetailsTitle => 'Bal\'ina konkolaachisaa';

  @override
  String get profileDriverDetailsSubtitle =>
      'Odeeffannoo konkolaataa yeroo imaltoonni qabatan mul\'atu.';

  @override
  String get profileQuickActionsTitle => 'Gocha ariifachiisaa';

  @override
  String get profileQuickActionsSubtitle =>
      'Gochoota fi filannoowwan herregaa yeroo baayyee itti fayyadamtan.';

  @override
  String get profileRecentActivityTitle => 'Sochii dhihoo';

  @override
  String get profileRecentActivitySubtitle =>
      'Mul\'ata gabaabaa sochii herregaa kee dhiyoo.';

  @override
  String get profileNoActivityTitle => 'Ammaaf sochiin hin jiru';

  @override
  String get profileNoActivityMessage =>
      'Yeroo imala qabattu ykn seenaa kee haaromsitu, haaromsi asitti mul\'ata.';

  @override
  String get profileCompletionLabel => 'Guutinsa seenaa';

  @override
  String get profileRoleLabel => 'Gahee';

  @override
  String get profileStatusLabel => 'Haala';

  @override
  String get profileStatusActive => 'Hojii irra';

  @override
  String get profileStatusPending => 'Eegaa jira';

  @override
  String get profileNotProvided => 'Hin kennamne';

  @override
  String get profileEditSubtitle =>
      'Bal\'ina dhuunfaa fi odeeffannoo eenyummaa imalaa kee haaromsi.';

  @override
  String get profilePhotoUploadPreview => 'Durargii olkaa\'uu suuraa';

  @override
  String get profilePhotoSyncingNote =>
      'Walqindaa\'inni suuraa haaromsa API itti aanu keessatti ni dabalama.';

  @override
  String get profileBasicInformationTitle => 'Odeeffannoo bu\'uuraa';

  @override
  String get profileBasicInformationSubtitle =>
      'Odeeffannoon kun imaltootaa fi bulchitootatti ni mul\'ata.';

  @override
  String get profileVehicleInformationTitle => 'Odeeffannoo konkolaataa';

  @override
  String get profileVehicleInformationSubtitle =>
      'Imaltoonni akka amananiif bal\'ina kana yeroo yeroon haaromsi.';

  @override
  String get profileSaving => 'Olkaa\'aa jira...';

  @override
  String get profileUserLabel => 'Fayyadamaa';
}
