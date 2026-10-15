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
  String get appTitle => 'Veribus';

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
  String get appUpdates => 'App updates';

  @override
  String get appUpdatesBody => 'Download the latest version from the GitHub releases';

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
  String get stop => 'Stop';

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
  String alertsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n alerts', one: '1 alert');
    return '$_temp0';
  }

  @override
  String get arrivalStates => 'Arrival states';

  @override
  String get arrivalStatesHint => 'What Confirmed, To be checked, Scheduled… mean';

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

  @override
  String get variantStops => 'Served only by some trips';

  @override
  String get routeTravelled => 'Already travelled';

  @override
  String get routeAhead => 'Still to go';

  @override
  String nextStopName(String stop) {
    return 'Next stop: $stop';
  }

  @override
  String vehicleNumber(String label) {
    return 'Vehicle $label';
  }

  @override
  String get close => 'Close';

  @override
  String get followedTrips => 'Followed trips';

  @override
  String get followTrip => 'Follow this trip';

  @override
  String get followTripHint => 'Tap a time to be notified when that bus is about to pass.';

  @override
  String get followDays => 'Days';

  @override
  String get followLeads => 'Notify me before';

  @override
  String followLeadsHint(int n) {
    return 'Up to $n notices';
  }

  @override
  String followLeadsSummary(String minutes) {
    return '$minutes min before';
  }

  @override
  String get followEnabled => 'Notices on';

  @override
  String get followRemove => 'Stop following';

  @override
  String get followRemoveTitle => 'Stop following this trip?';

  @override
  String get followRemoveBody => 'You will no longer be notified about it.';

  @override
  String get followSaved => 'Trip followed';

  @override
  String get followedMarker => 'Followed trip';

  @override
  String get everyDay => 'Every day';

  @override
  String get weekdays => 'Mon–Fri';

  @override
  String get weekend => 'Sat, Sun';

  @override
  String get noFollows => 'No followed trips';

  @override
  String get noFollowsHint =>
      'Open the timetable of a stop and tap the time of the trip you want: you will be notified before it passes.';

  @override
  String get notificationsOff => 'Notifications are off';

  @override
  String get notificationsOffBody => 'Without notifications you cannot be warned when the bus is about to pass.';

  @override
  String get notificationsBlocked => 'Turn notifications on for this app in the phone settings.';

  @override
  String get notificationsUnavailable => 'This device cannot receive notifications.';

  @override
  String get enableNotifications => 'Turn on';

  @override
  String get noticeChannelName => 'Followed trips';

  @override
  String get noticeChannelDescription => 'Your bus is about to pass, or something happened to it';

  @override
  String get errorFollowLimit => 'You can follow at most 30 trips. Remove one first.';

  @override
  String pushLead(String route, int minutes) {
    return 'Line $route: in $minutes min';
  }

  @override
  String pushArriving(String route) {
    return 'Line $route: is arriving';
  }

  @override
  String get pushScheduled => 'scheduled time';

  @override
  String pushStopTo(String stop, String headsign) {
    return '$stop to $headsign';
  }

  @override
  String pushCanceledTitle(String route) {
    return 'Line $route: trip canceled';
  }

  @override
  String pushCanceledBody(String time, String place) {
    return 'The $time at $place was canceled';
  }

  @override
  String pushStillTitle(String route, int minutes) {
    return 'Line $route: bus standing still for $minutes min';
  }

  @override
  String pushStillBody(String time, String place) {
    return 'The $time at $place';
  }

  @override
  String pushLostTitle(String route) {
    return 'Line $route: signal lost';
  }

  @override
  String pushLostBody(String time, String place) {
    return 'The vehicle of the $time at $place stopped transmitting: it may not arrive';
  }

  @override
  String overdue(String time) {
    return 'Due at $time, it may still come';
  }

  @override
  String get showOnMap => 'Show on the map';

  @override
  String get editFollow => 'Edit';

  @override
  String tripAt(String time, String stop) {
    return '$time trip at $stop';
  }

  @override
  String get tripHistoryWeekdays => 'Recent weekdays';

  @override
  String get tripHistoryWeekend => 'Recent weekends';

  @override
  String get tripHistoryEmpty => 'No data yet: the history fills up day by day.';

  @override
  String get tripUsuallyOnTime => 'Usually on time';

  @override
  String tripUsuallyLate(int n) {
    return 'Usually about $n min late';
  }

  @override
  String tripUsuallyEarly(int n) {
    return 'Usually about $n min early';
  }

  @override
  String get tripRarelyTracked => 'Rarely tracked: it may pass all the same';

  @override
  String tripOnTimeCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n on time', one: '1 on time');
    return '$_temp0';
  }

  @override
  String tripLateCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n late', one: '1 late');
    return '$_temp0';
  }

  @override
  String tripEarlyCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n early', one: '1 early');
    return '$_temp0';
  }

  @override
  String tripNotTrackedCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n not tracked', one: '1 not tracked');
    return '$_temp0';
  }

  @override
  String tripCanceledCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n canceled', one: '1 canceled');
    return '$_temp0';
  }

  @override
  String get tripDayNotTracked => 'not tracked';

  @override
  String get tripDayCanceled => 'canceled';
}
