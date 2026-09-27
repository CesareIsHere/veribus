// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get about => 'About';

  @override
  String get account => 'Account';

  @override
  String get appTitle => 'Template';

  @override
  String get appearance => 'Appearance';

  @override
  String get cancel => 'Cancel';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get createAccount => 'Create account';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirm =>
      'Your account and all its data will be permanently deleted. This cannot be undone.';

  @override
  String get deleteAccountDescription => 'Permanently delete your account and all its data.';

  @override
  String get email => 'Email';

  @override
  String get errorCancelled => 'Operation cancelled.';

  @override
  String get errorEmailNotConfirmed => 'Confirm your email with the link we sent you, then sign in.';

  @override
  String get errorEmailInUse => 'An account with this email already exists.';

  @override
  String get errorInvalidCredentials => 'Wrong email or password.';

  @override
  String get errorNetwork => 'No connection. Check your network and try again.';

  @override
  String get errorNotSupported => 'Not available on this device.';

  @override
  String get errorRequiresRecentLogin => 'For security, sign in again and retry.';

  @override
  String get errorServer => 'The server could not complete the request.';

  @override
  String get errorTooManyRequests => 'Too many attempts. Try again later.';

  @override
  String get errorUnauthorized => 'Your session has expired. Please sign in again.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get errorWeakPassword => 'The password is too weak.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordSubtitle => 'Enter your email and we\'ll send you a link to reset your password.';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get fullName => 'Full name';

  @override
  String get goHome => 'Go to home';

  @override
  String get language => 'Language';

  @override
  String get licenses => 'Open source licenses';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get logs => 'Logs';

  @override
  String get newPassword => 'New password';

  @override
  String get noAccountRegister => 'Don\'t have an account? Sign up';

  @override
  String get offline => 'You\'re offline';

  @override
  String get orContinueWith => 'or';

  @override
  String get pageNotFound => 'Page not found.';

  @override
  String get password => 'Password';

  @override
  String get passwordUpdated => 'Password updated. You can now sign in.';

  @override
  String get privacy => 'Privacy policy';

  @override
  String get profile => 'Profile';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get resetEmailSent => 'If the email exists, we sent you a reset link.';

  @override
  String get resetPasswordTitle => 'Choose a new password';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'Save';

  @override
  String get savePassword => 'Save password';

  @override
  String get saved => 'Saved';

  @override
  String get sendResetLink => 'Send link';

  @override
  String get settings => 'Settings';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Do you want to sign out?';

  @override
  String get support => 'Support';

  @override
  String get systemDefault => 'System';

  @override
  String get terms => 'Terms of service';

  @override
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get update => 'Update';

  @override
  String get updateRequired => 'A new version is required to continue.';

  @override
  String get validationEmail => 'Enter a valid email';

  @override
  String get validationPassword => 'At least 8 characters, with a letter and a number';

  @override
  String get validationPasswordsMatch => 'Passwords don\'t match';

  @override
  String get validationRequired => 'Required';

  @override
  String get version => 'Version';

  @override
  String get nearby => 'Nearby';

  @override
  String get search => 'Search';

  @override
  String get favorites => 'Favorites';

  @override
  String get alerts => 'Alerts';

  @override
  String get mapView => 'Map';

  @override
  String get listView => 'List';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get reportProblem => 'Report a problem';

  @override
  String get allLines => 'All';

  @override
  String get line => 'Line';

  @override
  String get lines => 'Lines';

  @override
  String get stops => 'Stops';

  @override
  String lineDetail(String name) {
    return 'Line $name';
  }

  @override
  String stopCode(String code) {
    return 'stop $code';
  }

  @override
  String get stopNotServed => 'This stop is no longer served.';

  @override
  String get lineNotServed => 'This line is not in service.';

  @override
  String get notServedAnymore => 'No longer served';

  @override
  String minutes(int n) {
    return '$n min';
  }

  @override
  String around(String time) {
    return 'around $time';
  }

  @override
  String get arriving => 'arriving';

  @override
  String stopsAway(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n stops away',
      one: '1 stop away',
      zero: 'at the stop',
    );
    return '$_temp0';
  }

  @override
  String approximateTime(int n) {
    return 'in about $n min, approximate time';
  }

  @override
  String vehicle(String label) {
    return 'vehicle $label';
  }

  @override
  String get noRealtimeData => 'no realtime data';

  @override
  String get lineWithoutRealtime => 'this line does not transmit its position';

  @override
  String get withoutRealtime => 'No realtime, scheduled times only';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusUncertain => 'To be checked';

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusCanceled => 'Canceled';

  @override
  String get statusSuppressed => 'Suppressed';

  @override
  String get signalCanceled => 'Trip canceled';

  @override
  String signalNotTransmitting(int n) {
    return 'The vehicle has not transmitted for $n min';
  }

  @override
  String get signalNoVehicle => 'No vehicle located';

  @override
  String signalStill(int n) {
    return 'Vehicle stopped for $n min';
  }

  @override
  String signalOldGps(int n) {
    return 'Last GPS signal $n min ago';
  }

  @override
  String signalAtTerminus(String time) {
    return 'Leaves the terminus at $time';
  }

  @override
  String get signalAtTerminusNoTime => 'Still at the terminus';

  @override
  String get signalLateData => 'Realtime data delayed';

  @override
  String get realtimeUnavailable => 'Realtime unavailable: showing scheduled times';

  @override
  String get noArrivals => 'No arrivals in the next 60 minutes';

  @override
  String updatedAgo(int s) {
    return 'updated $s s ago';
  }

  @override
  String get timetable => 'Today\'s timetable';

  @override
  String get previousDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get scheduledTimesNote => 'Scheduled times: they do not take traffic into account.';

  @override
  String get noServiceThisDay => 'No service on this day';

  @override
  String get firstTrip => 'first';

  @override
  String get lastTrip => 'last';

  @override
  String lastPositionAt(String time) {
    return 'last known position at $time';
  }

  @override
  String get terminus => 'terminus';

  @override
  String get noTripsInService => 'No trips in service';

  @override
  String nextDeparture(String time) {
    return 'Next departure at $time';
  }

  @override
  String vehiclesInService(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n vehicles in service',
      one: '1 vehicle in service',
      zero: 'No vehicles in service',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'Line or stop code';

  @override
  String get searchEmpty => 'Search runs on your phone: results show up as you type.';

  @override
  String get searchNoResults => 'No results. Check the code written on the stop pole.';

  @override
  String get locationDenied => 'Turn on location to see nearby stops';

  @override
  String get locationDeniedList => 'Without your position the list is empty: use Search to find a stop.';

  @override
  String get enableLocation => 'Turn on';

  @override
  String get you => 'You are here';

  @override
  String get backToMyPosition => 'Back to my position';

  @override
  String get zoomInForStops => 'Zoom in to see the stops';

  @override
  String get noStopsNearby => 'No stops within 1 km';

  @override
  String get nearbyNote => 'Stops within 500 m, sorted by distance. If there are none, the radius grows to 1 km.';

  @override
  String meters(int n) {
    return '$n m';
  }

  @override
  String get noFavorites => 'No favorites yet';

  @override
  String get noFavoritesHint => 'Tap the star on a stop or a line: the app will open here.';

  @override
  String get noAlerts => 'No active alerts';

  @override
  String get arrivalStates => 'Arrival states';

  @override
  String get stateConfirmedMeaning => 'A vehicle located a moment ago and moving is on this trip.';

  @override
  String get stateUncertainMeaning =>
      'There is a prediction, but something makes it doubtful: the reason is always written.';

  @override
  String get stateScheduledMeaning => 'No realtime data for this trip: only the scheduled time, never minutes.';

  @override
  String get stateSuppressedMeaning =>
      'The vehicle disappeared before completing the trip: it stays visible for 5 minutes.';

  @override
  String get stateCanceledMeaning => 'The operator canceled the trip.';

  @override
  String get dataSource => 'Data source';

  @override
  String get dataSourceBody =>
      'Open data by Roma Servizi per la Mobilità (GTFS and GTFS-Realtime). This app is not affiliated with Atac or RSM.';

  @override
  String get dataDisclaimer =>
      'Data come from automatic equipment and are not exhaustive: road conditions and malfunctions can make them inaccurate.';
}
